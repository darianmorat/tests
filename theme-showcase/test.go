package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
)

// Interfaces
type Storage interface {
	Store(key string, value interface{}) error
	Get(key string) (interface{}, bool)
	Delete(key string) bool
}

// Structs with embedded types
type User struct {
	ID       int       `json:"id"`
	Name     string    `json:"name"`
	Email    string    `json:"email"`
	Created  time.Time `json:"created"`
}

type MemoryStorage struct {
	mu   sync.RWMutex
	data map[string]interface{}
}

// Method with pointer receiver
func (ms *MemoryStorage) Store(key string, value interface{}) error {
	ms.mu.Lock()
	defer ms.mu.Unlock()
	ms.data[key] = value
	return nil
}

func (ms *MemoryStorage) Get(key string) (interface{}, bool) {
	ms.mu.RLock()
	defer ms.mu.RUnlock()
	val, exists := ms.data[key]
	return val, exists
}

func (ms *MemoryStorage) Delete(key string) bool {
	ms.mu.Lock()
	defer ms.mu.Unlock()
	if _, exists := ms.data[key]; exists {
		delete(ms.data, key)
		return true
	}
	return false
}

// Server struct with dependency injection
type Server struct {
	storage Storage
	port    string
}

func NewServer(storage Storage, port string) *Server {
	return &Server{storage: storage, port: port}
}

// HTTP handlers with error handling
func (s *Server) handleUsers(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodPost:
		s.createUser(w, r)
	case http.MethodGet:
		s.getUsers(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (s *Server) createUser(w http.ResponseWriter, r *http.Request) {
	var user User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}
	
	user.ID = int(time.Now().Unix())
	user.Created = time.Now()
	
	key := fmt.Sprintf("user:%d", user.ID)
	if err := s.storage.Store(key, user); err != nil {
		http.Error(w, "Storage error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func (s *Server) getUsers(w http.ResponseWriter, r *http.Request) {
	// This is a simplified version - in reality you'd iterate properly
	users := []User{
		{ID: 1, Name: "Alice", Email: "alice@example.com", Created: time.Now()},
		{ID: 2, Name: "Bob", Email: "bob@example.com", Created: time.Now()},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// Goroutine worker pattern
func worker(id int, jobs <-chan int, results chan<- string, wg *sync.WaitGroup) {
	defer wg.Done()
	for job := range jobs {
		// Simulate work
		time.Sleep(100 * time.Millisecond)
		result := fmt.Sprintf("Worker %d processed job %d", id, job)
		results <- result
	}
}

// Function with variadic parameters and channels
func processJobs(numWorkers int, jobData ...int) {
	jobs := make(chan int, len(jobData))
	results := make(chan string, len(jobData))
	
	var wg sync.WaitGroup

	// Start workers
	for i := 1; i <= numWorkers; i++ {
		wg.Add(1)
		go worker(i, jobs, results, &wg)
	}

	// Send jobs
	for _, job := range jobData {
		jobs <- job
	}
	close(jobs)

	// Wait for workers and close results
	go func() {
		wg.Wait()
		close(results)
	}()

	// Collect results
	for result := range results {
		fmt.Println(result)
	}
}

func main() {
	// Initialize storage
	storage := &MemoryStorage{
		data: make(map[string]interface{}),
	}

	// Create server
	server := NewServer(storage, ":8080")

	// Set up routes
	http.HandleFunc("/users", server.handleUsers)
	
	// Health check endpoint
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, `{"status": "healthy", "timestamp": "%s"}`, time.Now().Format(time.RFC3339))
	})

	// Demo concurrent processing
	fmt.Println("Processing jobs concurrently:")
	processJobs(3, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

	// Start server
	fmt.Printf("Server starting on port %s\n", server.port)
	log.Fatal(http.ListenAndServe(server.port, nil))
}
