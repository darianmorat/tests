#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

// Preprocessor definitions and macros
#define HASH_TABLE_INITIAL_SIZE 16
#define LOAD_FACTOR_THRESHOLD 0.75
#define MAX_KEY_LENGTH 256
#define MAX_VALUE_LENGTH 512

// Forward declarations
typedef struct hash_node hash_node_t;
typedef struct hash_table hash_table_t;

// Enumerations for status codes
typedef enum {
    HASH_OK,
    HASH_ERROR,
    HASH_KEY_NOT_FOUND,
    HASH_MEMORY_ERROR,
    HASH_KEY_TOO_LONG
} hash_status_t;

// Structure definitions
struct hash_node {
    char *key;
    char *value;
    uint32_t hash;
    hash_node_t *next;  // For collision handling via chaining
};

struct hash_table {
    hash_node_t **buckets;
    size_t size;        // Number of buckets
    size_t count;       // Number of stored items
    double load_factor;
};

// Function prototypes
static uint32_t hash_function(const char *key);
static hash_node_t *create_node(const char *key, const char *value, uint32_t hash);
static void free_node(hash_node_t *node);
static hash_status_t resize_table(hash_table_t *table);
static hash_node_t *find_node(hash_table_t *table, const char *key, uint32_t hash);

/**
 * FNV-1a hash function implementation
 * Provides good distribution for string keys
 */
static uint32_t hash_function(const char *key) {
    uint32_t hash = 2166136261u;  // FNV offset basis
    const uint32_t prime = 16777619u;  // FNV prime
    
    while (*key) {
        hash ^= (uint8_t)(*key++);
        hash *= prime;
    }
    
    return hash;
}

/**
 * Create a new hash node with allocated memory
 */
static hash_node_t *create_node(const char *key, const char *value, uint32_t hash) {
    if (!key || !value) return NULL;
    
    // Check key length
    if (strlen(key) >= MAX_KEY_LENGTH || strlen(value) >= MAX_VALUE_LENGTH) {
        return NULL;
    }
    
    hash_node_t *node = malloc(sizeof(hash_node_t));
    if (!node) return NULL;
    
    // Allocate and copy key
    node->key = malloc(strlen(key) + 1);
    if (!node->key) {
        free(node);
        return NULL;
    }
    strcpy(node->key, key);
    
    // Allocate and copy value
    node->value = malloc(strlen(value) + 1);
    if (!node->value) {
        free(node->key);
        free(node);
        return NULL;
    }
    strcpy(node->value, value);
    
    node->hash = hash;
    node->next = NULL;
    
    return node;
}

/**
 * Free a node and all its allocated memory
 */
static void free_node(hash_node_t *node) {
    if (node) {
        free(node->key);
        free(node->value);
        free(node);
    }
}

/**
 * Find a node in the hash table
 */
static hash_node_t *find_node(hash_table_t *table, const char *key, uint32_t hash) {
    size_t index = hash % table->size;
    hash_node_t *current = table->buckets[index];
    
    while (current) {
        if (current->hash == hash && strcmp(current->key, key) == 0) {
            return current;
        }
        current = current->next;
    }
    
    return NULL;
}

/**
 * Initialize a new hash table
 */
hash_table_t *hash_table_create(void) {
    hash_table_t *table = malloc(sizeof(hash_table_t));
    if (!table) return NULL;
    
    table->buckets = calloc(HASH_TABLE_INITIAL_SIZE, sizeof(hash_node_t*));
    if (!table->buckets) {
        free(table);
        return NULL;
    }
    
    table->size = HASH_TABLE_INITIAL_SIZE;
    table->count = 0;
    table->load_factor = 0.0;
    
    return table;
}

/**
 * Resize the hash table when load factor exceeds threshold
 */
static hash_status_t resize_table(hash_table_t *table) {
    size_t old_size = table->size;
    hash_node_t **old_buckets = table->buckets;
    
    // Double the size
    table->size = old_size * 2;
    table->buckets = calloc(table->size, sizeof(hash_node_t*));
    
    if (!table->buckets) {
        table->size = old_size;
        table->buckets = old_buckets;
        return HASH_MEMORY_ERROR;
    }
    
    // Rehash all existing nodes
    for (size_t i = 0; i < old_size; i++) {
        hash_node_t *current = old_buckets[i];
        
        while (current) {
            hash_node_t *next = current->next;
            size_t new_index = current->hash % table->size;
            
            current->next = table->buckets[new_index];
            table->buckets[new_index] = current;
            
            current = next;
        }
    }
    
    free(old_buckets);
    table->load_factor = (double)table->count / table->size;
    
    printf("Hash table resized to %zu buckets\n", table->size);
    return HASH_OK;
}

/**
 * Insert or update a key-value pair
 */
hash_status_t hash_table_put(hash_table_t *table, const char *key, const char *value) {
    if (!table || !key || !value) return HASH_ERROR;
    
    uint32_t hash = hash_function(key);
    hash_node_t *existing = find_node(table, key, hash);
    
    // Update existing key
    if (existing) {
        char *new_value = malloc(strlen(value) + 1);
        if (!new_value) return HASH_MEMORY_ERROR;
        
        strcpy(new_value, value);
        free(existing->value);
        existing->value = new_value;
        return HASH_OK;
    }
    
    // Check if we need to resize
    table->load_factor = (double)(table->count + 1) / table->size;
    if (table->load_factor > LOAD_FACTOR_THRESHOLD) {
        hash_status_t status = resize_table(table);
        if (status != HASH_OK) return status;
    }
    
    // Create new node
    hash_node_t *node = create_node(key, value, hash);
    if (!node) return HASH_MEMORY_ERROR;
    
    // Insert at beginning of chain
    size_t index = hash % table->size;
    node->next = table->buckets[index];
    table->buckets[index] = node;
    
    table->count++;
    table->load_factor = (double)table->count / table->size;
    
    return HASH_OK;
}

/**
 * Get a value by key
 */
hash_status_t hash_table_get(hash_table_t *table, const char *key, char **value) {
    if (!table || !key || !value) return HASH_ERROR;
    
    uint32_t hash = hash_function(key);
    hash_node_t *node = find_node(table, key, hash);
    
    if (!node) return HASH_KEY_NOT_FOUND;
    
    *value = node->value;
    return HASH_OK;
}

/**
 * Remove a key-value pair
 */
hash_status_t hash_table_remove(hash_table_t *table, const char *key) {
    if (!table || !key) return HASH_ERROR;
    
    uint32_t hash = hash_function(key);
    size_t index = hash % table->size;
    hash_node_t *current = table->buckets[index];
    hash_node_t *prev = NULL;
    
    while (current) {
        if (current->hash == hash && strcmp(current->key, key) == 0) {
            if (prev) {
                prev->next = current->next;
            } else {
                table->buckets[index] = current->next;
            }
            
            free_node(current);
            table->count--;
            table->load_factor = (double)table->count / table->size;
            return HASH_OK;
        }
        prev = current;
        current = current->next;
    }
    
    return HASH_KEY_NOT_FOUND;
}

/**
 * Print hash table statistics and contents
 */
void hash_table_print(hash_table_t *table) {
    if (!table) return;
    
    printf("\n=== Hash Table Statistics ===\n");
    printf("Size: %zu buckets\n", table->size);
    printf("Count: %zu items\n", table->count);
    printf("Load Factor: %.3f\n", table->load_factor);
    
    size_t collisions = 0;
    size_t max_chain = 0;
    
    printf("\n=== Contents ===\n");
    for (size_t i = 0; i < table->size; i++) {
        hash_node_t *current = table->buckets[i];
        size_t chain_length = 0;
        
        if (current) {
            printf("Bucket %zu: ", i);
            
            while (current) {
                printf("'%s' -> '%s'", current->key, current->value);
                chain_length++;
                current = current->next;
                
                if (current) {
                    printf(" -> ");
                    collisions++;
                }
            }
            printf("\n");
            
            if (chain_length > max_chain) {
                max_chain = chain_length;
            }
        }
    }
    
    printf("\nCollisions: %zu\n", collisions);
    printf("Max chain length: %zu\n", max_chain);
}

/**
 * Free the entire hash table
 */
void hash_table_destroy(hash_table_t *table) {
    if (!table) return;
    
    for (size_t i = 0; i < table->size; i++) {
        hash_node_t *current = table->buckets[i];
        
        while (current) {
            hash_node_t *next = current->next;
            free_node(current);
            current = next;
        }
    }
    
    free(table->buckets);
    free(table);
}

/**
 * Demo function showing hash table usage
 */
int main(void) {
    printf("Hash Table Implementation Demo\n");
    printf("=============================\n");
    
    hash_table_t *table = hash_table_create();
    if (!table) {
        fprintf(stderr, "Failed to create hash table\n");
        return EXIT_FAILURE;
    }
    
    // Test data
    const char *test_keys[] = {
        "name", "age", "city", "country", "email",
        "phone", "address", "zip", "state", "language"
    };
    
    const char *test_values[] = {
        "John Doe", "30", "New York", "USA", "john@example.com",
        "555-1234", "123 Main St", "10001", "NY", "English"
    };
    
    const size_t num_tests = sizeof(test_keys) / sizeof(test_keys[0]);
    
    // Insert test data
    printf("Inserting test data...\n");
    for (size_t i = 0; i < num_tests; i++) {
        hash_status_t status = hash_table_put(table, test_keys[i], test_values[i]);
        if (status == HASH_OK) {
            printf("✓ Inserted: '%s' -> '%s'\n", test_keys[i], test_values[i]);
        } else {
            printf("✗ Failed to insert: '%s'\n", test_keys[i]);
        }
    }
    
    // Test retrieval
    printf("\nTesting retrieval...\n");
    char *value;
    for (size_t i = 0; i < num_tests; i++) {
        hash_status_t status = hash_table_get(table, test_keys[i], &value);
        if (status == HASH_OK) {
            printf("✓ Found: '%s' -> '%s'\n", test_keys[i], value);
        } else {
            printf("✗ Not found: '%s'\n", test_keys[i]);
        }
    }
    
    // Update a value
    printf("\nUpdating 'age' to '31'...\n");
    hash_table_put(table, "age", "31");
    hash_table_get(table, "age", &value);
    printf("New age value: %s\n", value);
    
    // Print table statistics
    hash_table_print(table);
    
    // Test removal
    printf("\nRemoving 'phone'...\n");
    hash_status_t status = hash_table_remove(table, "phone");
    if (status == HASH_OK) {
        printf("✓ Successfully removed 'phone'\n");
    } else {
        printf("✗ Failed to remove 'phone'\n");
    }
    
    // Verify removal
    status = hash_table_get(table, "phone", &value);
    if (status == HASH_KEY_NOT_FOUND) {
        printf("✓ Confirmed: 'phone' no longer exists\n");
    }
    
    hash_table_destroy(table);
    printf("\nHash table destroyed. Demo complete.\n");
    
    return EXIT_SUCCESS;
}
