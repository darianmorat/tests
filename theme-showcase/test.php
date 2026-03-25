<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use App\Models\Product;
use App\Http\Requests\UserRequest;
use App\Http\Resources\UserResource;
use App\Services\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\{DB, Cache, Log, Hash};
use Illuminate\Support\Collection;
use Carbon\Carbon;

/**
 * Class UserController
 * Handles user management with modern PHP features
 * 
 * @package App\Http\Controllers\Api
 */
class UserController extends Controller
{
    private PaymentService $paymentService;
    private const CACHE_TTL = 3600;
    
    public function __construct(PaymentService $paymentService)
    {
        $this->paymentService = $paymentService;
        $this->middleware('auth:sanctum')->except(['index', 'show']);
    }
    
    /**
     * Display paginated users with filtering
     */
    public function index(Request $request): JsonResponse
    {
        $query = User::with(['orders', 'profile'])
            ->when($request->filled('status'), function ($q) use ($request) {
                return $q->where('status', $request->status);
            })
            ->when($request->filled('search'), function ($q) use ($request) {
                return $q->where('name', 'like', "%{$request->search}%")
                        ->orWhere('email', 'like', "%{$request->search}%");
            });
        
        $users = $query->paginate($request->get('per_page', 15));
        
        return response()->json([
            'success' => true,
            'data' => UserResource::collection($users),
            'meta' => [
                'total' => $users->total(),
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
            ]
        ]);
    }
    
    /**
     * Store a new user with validation and events
     */
    public function store(UserRequest $request): JsonResponse
    {
        try {
            DB::beginTransaction();
            
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'email_verified_at' => null,
                'status' => UserStatus::PENDING->value,
            ]);
            
            // Create user profile
            $user->profile()->create([
                'phone' => $request->phone,
                'address' => $request->address,
                'preferences' => $request->preferences ?? [],
            ]);
            
            // Send welcome email
            $user->notify(new WelcomeNotification());
            
            DB::commit();
            
            // Clear cache
            Cache::tags(['users'])->flush();
            
            return response()->json([
                'success' => true,
                'message' => 'User created successfully',
                'data' => new UserResource($user->load('profile')),
            ], 201);
            
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('User creation failed', [
                'error' => $e->getMessage(),
                'request_data' => $request->all()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to create user',
            ], 500);
        }
    }
    
    /**
     * Display user with caching
     */
    public function show(int $id): JsonResponse
    {
        $user = Cache::remember(
            "user.{$id}",
            self::CACHE_TTL,
            fn() => User::with(['orders.products', 'profile'])
                       ->findOrFail($id)
        );
        
        return response()->json([
            'success' => true,
            'data' => new UserResource($user),
        ]);
    }
    
    /**
     * Update user with optimistic locking
     */
    public function update(UserRequest $request, User $user): JsonResponse
    {
        $this->authorize('update', $user);
        
        $user->update($request->validated());
        
        // Update profile if provided
        if ($request->has('profile')) {
            $user->profile->update($request->profile);
        }
        
        Cache::forget("user.{$user->id}");
        Cache::tags(['users'])->flush();
        
        return response()->json([
            'success' => true,
            'message' => 'User updated successfully',
            'data' => new UserResource($user->fresh()),
        ]);
    }
    
    /**
     * Process payment using dependency injection
     */
    public function processPayment(Request $request, User $user): JsonResponse
    {
        $request->validate([
            'amount' => 'required|numeric|min:0.01',
            'payment_method' => 'required|string|in:card,paypal,crypto',
        ]);
        
        try {
            $result = $this->paymentService->processPayment(
                user: $user,
                amount: $request->amount,
                method: $request->payment_method,
                metadata: $request->metadata ?? []
            );
            
            return match ($result->status) {
                'success' => response()->json([
                    'success' => true,
                    'transaction_id' => $result->transactionId,
                    'message' => 'Payment processed successfully'
                ]),
                'pending' => response()->json([
                    'success' => true,
                    'status' => 'pending',
                    'message' => 'Payment is being processed'
                ], 202),
                'failed' => response()->json([
                    'success' => false,
                    'message' => $result->error ?? 'Payment failed'
                ], 400),
            };
            
        } catch (PaymentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'code' => $e->getCode()
            ], 422);
        }
    }
}

/**
 * Enum for user status with backed values
 */
enum UserStatus: string
{
    case ACTIVE = 'active';
    case PENDING = 'pending';
    case SUSPENDED = 'suspended';
    case DELETED = 'deleted';
    
    public function label(): string
    {
        return match($this) {
            self::ACTIVE => 'Active User',
            self::PENDING => 'Pending Verification',
            self::SUSPENDED => 'Account Suspended',
            self::DELETED => 'Account Deleted',
        };
    }
    
    public function canLogin(): bool
    {
        return $this === self::ACTIVE;
    }
}

/**
 * Modern User model with attributes and relationships
 */
class User extends Model
{
    use HasFactory, Notifiable, SoftDeletes;
    
    protected $fillable = [
        'name', 'email', 'password', 'status', 'email_verified_at'
    ];
    
    protected $hidden = ['password', 'remember_token'];
    
    protected $casts = [
        'email_verified_at' => 'datetime',
        'status' => UserStatus::class,
        'preferences' => 'array',
        'last_login_at' => 'datetime',
    ];
    
    // Accessors using new attribute syntax
    protected function fullName(): Attribute
    {
        return Attribute::make(
            get: fn ($value, $attributes) => 
                $attributes['first_name'] . ' ' . $attributes['last_name']
        );
    }
    
    protected function email(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => strtolower($value),
            set: fn ($value) => strtolower($value),
        );
    }
    
    // Relationships
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
    
    public function profile(): HasOne
    {
        return $this->hasOne(UserProfile::class);
    }
    
    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class)
                   ->withTimestamps()
                   ->withPivot(['granted_at', 'granted_by']);
    }
    
    // Scopes for query building
    public function scopeActive(Builder $query): void
    {
        $query->where('status', UserStatus::ACTIVE);
    }
    
    public function scopeRecentlyActive(Builder $query, int $days = 30): void
    {
        $query->where('last_login_at', '>=', Carbon::now()->subDays($days));
    }
    
    // Custom methods
    public function hasRole(string $role): bool
    {
        return $this->roles()->where('name', $role)->exists();
    }
    
    public function getTotalOrderValue(): float
    {
        return $this->orders()
                   ->where('status', 'completed')
                   ->sum('total_amount');
    }
}

/**
 * Service class demonstrating dependency injection and modern PHP
 */
class PaymentService
{
    public function __construct(
        private readonly PaymentGateway $gateway,
        private readonly Logger $logger,
        private readonly EventDispatcher $events
    ) {}
    
    public function processPayment(
        User $user,
        float $amount,
        string $method,
        array $metadata = []
    ): PaymentResult {
        $this->logger->info('Processing payment', [
            'user_id' => $user->id,
            'amount' => $amount,
            'method' => $method
        ]);
        
        try {
            // Validate payment method
            $this->validatePaymentMethod($method, $amount);
            
            // Process with gateway
            $result = $this->gateway->charge([
                'amount' => $amount * 100, // Convert to cents
                'currency' => 'USD',
                'customer_id' => $user->payment_customer_id,
                'payment_method' => $method,
                'metadata' => array_merge($metadata, [
                    'user_id' => $user->id,
                    'timestamp' => Carbon::now()->toISOString()
                ])
            ]);
            
            // Create transaction record
            $transaction = Transaction::create([
                'user_id' => $user->id,
                'amount' => $amount,
                'currency' => 'USD',
                'status' => $result->status,
                'gateway_transaction_id' => $result->id,
                'payment_method' => $method,
                'processed_at' => Carbon::now(),
            ]);
            
            // Fire event
            $this->events->dispatch(new PaymentProcessed($transaction));
            
            return new PaymentResult(
                status: $result->status,
                transactionId: $transaction->id,
                gatewayId: $result->id
            );
            
        } catch (\Throwable $e) {
            $this->logger->error('Payment processing failed', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            throw new PaymentException(
                "Payment processing failed: {$e->getMessage()}",
                previous: $e
            );
        }
    }
    
    private function validatePaymentMethod(string $method, float $amount): void
    {
        $validMethods = ['card', 'paypal', 'crypto'];
        
        if (!in_array($method, $validMethods)) {
            throw new InvalidArgumentException("Invalid payment method: {$method}");
        }
        
        if ($method === 'crypto' && $amount < 10) {
            throw new PaymentException('Minimum crypto payment is $10');
        }
    }
}

/**
 * Data Transfer Object using readonly properties
 */
readonly class PaymentResult
{
    public function __construct(
        public string $status,
        public int $transactionId,
        public string $gatewayId,
        public ?string $error = null
    ) {}
    
    public function isSuccessful(): bool
    {
        return $this->status === 'success';
    }
}

/**
 * Custom exception with context
 */
class PaymentException extends Exception
{
    public function __construct(
        string $message,
        public readonly array $context = [],
        int $code = 0,
        ?\Throwable $previous = null
    ) {
        parent::__construct($message, $code, $previous);
    }
    
    public function getContext(): array
    {
        return $this->context;
    }
}

/**
 * Utility trait for common functionality
 */
trait HasTimestamps
{
    protected static function bootHasTimestamps(): void
    {
        static::creating(function ($model) {
            $now = Carbon::now();
            $model->created_at = $now;
            $model->updated_at = $now;
        });
        
        static::updating(function ($model) {
            $model->updated_at = Carbon::now();
        });
    }
    
    public function touch(): bool
    {
        $this->updated_at = Carbon::now();
        return $this->save();
    }
}

/**
 * Helper functions with type declarations
 */
function formatCurrency(float $amount, string $currency = 'USD'): string
{
    return match ($currency) {
        'USD' => '$' . number_format($amount, 2),
        'EUR' => '€' . number_format($amount, 2),
        'GBP' => '£' . number_format($amount, 2),
        default => $currency . ' ' . number_format($amount, 2),
    };
}

function validateEmail(string $email): bool
{
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Array operations with modern syntax
 */
$users = User::all();
$activeUsers = $users->filter(fn($user) => $user->status === UserStatus::ACTIVE);
$usersByStatus = $users->groupBy('status');
$totalRevenue = $users->sum(fn($user) => $user->getTotalOrderValue());

// Null coalescing and null coalescing assignment
$config['timeout'] ??= 30;
$user->preferences['theme'] = $request->theme ?? $user->preferences['theme'] ?? 'dark';

// Match expressions for complex logic
$discount = match ($user->membership_level) {
    'bronze' => 0.05,
    'silver' => 0.10,
    'gold' => 0.15,
    'platinum' => 0.20,
    default => 0.0,
};

// Named arguments in function calls
$payment = processPayment(
    user: $user,
    amount: 99.99,
    method: 'card',
    metadata: ['source' => 'web']
);

/**
 * Modern PHP 8+ features demonstration
 */
#[Route('/api/users/{id}', methods: ['GET'])]
#[Middleware('auth')]
class UserApiController
{
    public function show(
        #[PathParameter] int $id,
        #[Inject] UserRepository $repository
    ): JsonResponse {
        $user = $repository->findOrFail($id);
        
        return response()->json($user);
    }
}

?>
