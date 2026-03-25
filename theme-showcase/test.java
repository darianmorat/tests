package com.example.userservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

import javax.persistence.*;
import javax.validation.constraints.*;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
import java.util.concurrent.CompletableFuture;
import java.util.function.Predicate;

// Main Application Class
@SpringBootApplication
public class UserServiceApplication {
   public static void main(String[] args) {
      SpringApplication.run(UserServiceApplication.class, args);
   }
}

// Entity Classes with JPA Annotations
@Entity
@Table(name = "users")
public class User {
   @Id
   @GeneratedValue(strategy = GenerationType.IDENTITY)
   private Long id;

   @NotBlank(message = "Name cannot be blank")
   @Size(min = 2, max = 100, message = "Name must be between 2 and 100 characters")
   private String name;

   @Email(message = "Invalid email format")
   @Column(unique = true)
   private String email;

   @Enumerated(EnumType.STRING)
   private UserStatus status = UserStatus.ACTIVE;

   @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
   private List<Order> orders = new ArrayList<>();

   @CreationTimestamp
   private LocalDateTime createdAt;

   @UpdateTimestamp
   private LocalDateTime updatedAt;

   // Constructors
   public User() {}

   public User(String name, String email) {
      this.name = name;
      this.email = email;
   }

   // Getters and Setters with Method Chaining
   public Long getId() { return id; }
   public User setId(Long id) { this.id = id; return this; }

   public String getName() { return name; }
   public User setName(String name) { this.name = name; return this; }

   public String getEmail() { return email; }
   public User setEmail(String email) { this.email = email; return this; }

   public UserStatus getStatus() { return status; }
   public User setStatus(UserStatus status) { this.status = status; return this; }

   public List<Order> getOrders() { return orders; }
   public User setOrders(List<Order> orders) { this.orders = orders; return this; }

   // Business Logic Methods
   public boolean isActive() {
      return status == UserStatus.ACTIVE;
   }

   public OptionalDouble getAverageOrderValue() {
      return orders.stream()
      .mapToDouble(Order::getAmount)
      .average();
   }

   @Override
   public boolean equals(Object o) {
      if (this == o) return true;
      if (!(o instanceof User)) return false;
      User user = (User) o;
      return Objects.equals(id, user.id) && Objects.equals(email, user.email);
   }

   @Override
   public int hashCode() {
      return Objects.hash(id, email);
   }

   @Override
   public String toString() {
      return String.format("User{id=%d, name='%s', email='%s', status=%s}", 
         id, name, email, status);
   }
}

// Enum for User Status
public enum UserStatus {
   ACTIVE("Active"),
   INACTIVE("Inactive"),
   SUSPENDED("Suspended"),
   DELETED("Deleted");

   private final String displayName;

   UserStatus(String displayName) {
      this.displayName = displayName;
   }

   public String getDisplayName() {
      return displayName;
   }

   public static UserStatus fromString(String status) {
      return Arrays.stream(values())
      .filter(s -> s.name().equalsIgnoreCase(status))
      .findFirst()
      .orElseThrow(() -> new IllegalArgumentException("Invalid status: " + status));
   }
}

// Related Entity
@Entity
@Table(name = "orders")
public class Order {
   @Id
   @GeneratedValue(strategy = GenerationType.IDENTITY)
   private Long id;

   @ManyToOne(fetch = FetchType.LAZY)
   @JoinColumn(name = "user_id", nullable = false)
   private User user;

   // Constructors and methods
   public Order() {}
   public Order(User user, Double amount) {
      this.user = user;
      this.amount = amount;
   }

   // Getters and setters...
   public Long getId() { return id; }
   public User getUser() { return user; }
   public Double getAmount() { return amount; }
   public LocalDateTime getOrderDate() { return orderDate; }
}

// Repository Interface with Custom Queries
public interface UserRepository extends JpaRepository<User, Long> {
   Optional<User> findByEmail(String email);

   List<User> findByStatus(UserStatus status);

   @Query("SELECT u FROM User u WHERE u.status = :status")
   List<User> findNameContainingStatus(@Param("name") String name
}

// DTO Classes for API Responses
public class UserDTO {
   private Long id;
   private String name;
   private String email;
   private String status;
   private int orderCount;
   private Double totalOrderValue;

   // Constructor using Builder Pattern
   private UserDTO(Builder builder) {
   this.id = builder.id;
   this.name = builder.name;
   this.email = builder.email;
   this.status = builder.status;
   this.orderCount = builder.orderCount;
   this.totalOrderValue = builder.totalOrderValue;
}

      // Static factory method
      public static UserDTO fromEntity(User user) {
         return new Builder()
         .id(user.getId())
         .name(user.getName())
         .email(user.getEmail())
         .status(user.getStatus().getDisplayName())
         .orderCount(user.getOrders().size())
         .totalOrderValue(user.getOrders().stream()
            .mapToDouble(Order::getAmount)
            .sum())
         .build();
      }

      // Builder Pattern Implementation
      public static class Builder {
         private Long id;
         private String name;
         private String email;
         private String status;
         private int orderCount;
         private Double totalOrderValue;

         public Builder id(Long id) { this.id = id; return this; }
         public Builder name(String name) { this.name = name; return this; }
         public Builder email(String email) { this.email = email; return this; }
         public Builder status(String status) { this.status = status; return this; }
         public Builder orderCount(int count) { this.orderCount = count; return this; }
         public Builder totalOrderValue(Double value) { this.totalOrderValue = value; return this; }

         public UserDTO build() {
            return new UserDTO(this);
         }
      }

      // Getters
      public Long getId() { return id; }
   public String getName() { return name; }
   public String getEmail() { return email; }
   public String getStatus() { return status; }
   public int getOrderCount() { return orderCount; }
   public Double getTotalOrderValue() { return totalOrderValue; }
}

// Service Layer with Business Logic
@Service
@Transactional
public class UserService {
   private final UserRepository userRepository;
   private final OrderRepository orderRepository;

   public UserService(UserRepository userRepository, OrderRepository orderRepository) {
      this.userRepository = userRepository;
      this.orderRepository = orderRepository;
   }

   // CRUD Operations with Functional Programming
   public List<UserDTO> getAllUsers(Optional<UserStatus> status) {
      List<User> users = status.map(userRepository::findByStatus)
      .orElseGet(userRepository::findAll);

      return users.stream()
      .map(UserDTO::fromEntity)
      .collect(Collectors.toList());
   }

   public Optional<UserDTO> getUserById(Long id) {
      return userRepository.findById(id)
      .map(UserDTO::fromEntity);
   }

   public UserDTO createUser(User user) throws UserServiceException {
      // Check if email already exists
      if (userRepository.findByEmail(user.getEmail()).isPresent()) {
         throw new UserServiceException("Email already exists: " + user.getEmail());
      }

      User savedUser = userRepository.save(user);
      return UserDTO.fromEntity(savedUser);
   }

   public Optional<UserDTO> updateUser(Long id, User updatedUser) {
      return userRepository.findById(id)
      .map(existingUser -> {
         existingUser.setName(updatedUser.getName())
            .setEmail(updatedUser.getEmail())
            .setStatus(updatedUser.getStatus());
         return UserDTO.fromEntity(userRepository.save(existingUser));
      });
   }

   public boolean deleteUser(Long id) {
      return userRepository.findById(id)
      .map(user -> {
         user.setStatus(UserStatus.DELETED);
         userRepository.save(user);
         return true;
      })
      .orElse(false);
   }

   // Complex Business Logic with Streams
   public Map<UserStatus, Long> getUserCountByStatus() {
      return userRepository.findAll().stream()
      .collect(Collectors.groupingBy(
         User::getStatus,
         Collectors.counting()));
   }

   public List<UserDTO> getTopUsersByOrderValue(int limit) {
      return userRepository.findAll().stream()
      .filter(user -> !user.getOrders().isEmpty())
      .sorted((u1, u2) -> Double.compare(
         u2.getOrders().stream().mapToDouble(Order::getAmount).sum(),
         u1.getOrders().stream().mapToDouble(Order::getAmount).sum()))
      .limit(limit)
      .map(UserDTO::fromEntity)
      .collect(Collectors.toList());
   }

   // Async Processing
   @Async
   public CompletableFuture<List<User>> findUsersAsync(Predicate<User> criteria) {
      List<User> filteredUsers = userRepository.findAll().stream()
      .filter(criteria)
      .collect(Collectors.toList());
      return CompletableFuture.completedFuture(filteredUsers);
   }
}

// Custom Exception
public class UserServiceException extends Exception {
   public UserServiceException(String message) {
      super(message);
   }

   public UserServiceException(String message, Throwable cause) {
      super(message, cause);
   }
}

// REST Controller with Advanced Features
@RestController
@RequestMapping("/api/v1/users")
@CrossOrigin(origins = "*")
public class UserController {
   private final UserService userService;

   public UserController(UserService userService) {
      this.userService = userService;
   }

   @GetMapping
   public ResponseEntity<List<UserDTO>> getAllUsers(
      @RequestParam(required = false) String status,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "10") int size) {

      Optional<UserStatus> userStatus = Optional.ofNullable(status)
      .map(UserStatus::fromString);

      List<UserDTO> users = userService.getAllUsers(userStatus);
      return ResponseEntity.ok(users);
   }

   @GetMapping("/{id}")
   public ResponseEntity<UserDTO> getUserById(@PathVariable Long id) {
      return userService.getUserById(id)
      .map(user -> ResponseEntity.ok(user))
      .orElse(ResponseEntity.notFound().build());
   }

   @PostMapping
   public ResponseEntity<?> createUser(@Valid @RequestBody User user) {
      try {
         UserDTO createdUser = userService.createUser(user);
         return ResponseEntity.status(HttpStatus.CREATED).body(createdUser);
      } catch (UserServiceException e) {
         return ResponseEntity.badRequest()
         .body(Map.of("error", e.getMessage()));
      }
   }

   @PutMapping("/{id}")
   public ResponseEntity<UserDTO> updateUser(@PathVariable Long id, 
      @Valid @RequestBody User user) {
      return userService.updateUser(id, user)
      .map(updatedUser -> ResponseEntity.ok(updatedUser))
      .orElse(ResponseEntity.notFound().build());
   }

   @DeleteMapping("/{id}")
   public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
      return userService.deleteUser(id) 
      ? ResponseEntity.noContent().build()
      : ResponseEntity.notFound().build();
   }

   @GetMapping("/stats")
   public ResponseEntity<Map<String, Object>> getUserStats() {
      Map<String, Object> stats = new HashMap<>();
      stats.put("countByStatus", userService.getUserCountByStatus());
      stats.put("topUsers", userService.getTopUsersByOrderValue(5));

      return ResponseEntity.ok(stats);
   }
}
