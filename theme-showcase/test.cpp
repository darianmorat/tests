#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <stdexcept>
#include <iomanip>

class HashTable {
private:
   // Node structure for chaining
   struct Node {
      std::string key;
      std::unique_ptr<Node> next;

      Node(const std::string& k, const std::string& v, std::size_t h)
      : key(k), value(v), hash(h), next(nullptr) {}
   };

   // Assignment operator
      HashTable& operator=(const HashTable& other) {
      if (this != &other) {
         HashTable temp(other);
         std::swap(buckets, temp.buckets);
         std::swap(table_size, temp.table_size);
         std::swap(count, temp.count);
         std::swap(load_factor, temp.load_factor);
      }
      return *this;
   }

   // Move assignment operator
   HashTable& operator=(HashTable&& other) noexcept {
      if (this != &other) {
         buckets = std::move(other.buckets);
         table_size = other.table_size;
         count = other.count;
         load_factor = other.load_factor;
      }
      return *this;
   }

   // Constants
   static constexpr std::size_t INITIAL_SIZE = 16;
   static constexpr double LOAD_FACTOR_THRESHOLD = 0.75;
   static constexpr std::size_t MAX_KEY_LENGTH = 256;
   static constexpr std::size_t MAX_VALUE_LENGTH = 512;

   std::vector<std::unique_ptr<Node>> buckets;
   std::size_t table_size;
   std::size_t count;
   double load_factor;

   // FNV-1a hash function
   std::size_t hashFunction(const std::string& key) const {
      std::size_t hash = 2166136261u; // FNV offset basis
      const std::size_t prime = 16777619u; // FNV prime

      for (char c : key) {
         hash ^= static_cast<std::uint8_t>(c);
         hash *= prime;
      }

      return hash;
   }

   // Find a node in the table
   Node* findNode(const std::string& key, std::size_t hash) const {
      std::size_t index = hash % table_size;
      Node* current = buckets[index].get();

      while (current) {
         if (current->hash == hash && current->key == key) {
            return current;
         }
         current = current->next.get();
      }

      return nullptr;
   }

   // Resize the table when load factor exceeds threshold
   void resizeTable() {
      std::size_t old_size = table_size;
      auto old_buckets = std::move(buckets);

      // Double the size
      table_size = old_size * 2;
      buckets.resize(table_size);

      // Initialize new buckets
      for (auto& bucket : buckets) {
         bucket = nullptr;
      }

      // Rehash all existing nodes
      for (auto& bucket : old_buckets) {
         Node* current = bucket.release();

         while (current) {
            std::unique_ptr<Node> node(current);
            current = node->next.release();

            std::size_t new_index = node->hash % table_size;
            node->next = std::move(buckets[new_index]);
            buckets[new_index] = std::move(node);
         }
      }

      load_factor = static_cast<double>(count) / table_size;
      std::cout << "Hash table resized to " << table_size << " buckets\n";
   }

public:
   // Exception classes
   class HashTableException : public std::runtime_error {
   public:
      HashTableException(const std::string& msg) : std::runtime_error(msg) {}
   };

   class KeyNotFoundException : public HashTableException {
   public:
      KeyNotFoundException(const std::string& key) 
      : HashTableException("Key not found: " + key) {}
   };

   class KeyTooLongException : public HashTableException {
   public:
      KeyTooLongException() : HashTableException("Key or value too long") {}
   };

   // Constructor
   HashTable() : table_size(INITIAL_SIZE), count(0), load_factor(0.0) {
      buckets.resize(table_size);
      for (auto& bucket : buckets) {
         bucket = nullptr;
      }
   }

   // Destructor (automatic cleanup with smart pointers)
   ~HashTable() = default;

   // Copy constructor
   HashTable(const HashTable& other) 
   : table_size(other.table_size), count(other.count), load_factor(other.load_factor) {
      buckets.resize(table_size);

      for (std::size_t i = 0; i < table_size; ++i) {
         buckets[i] = nullptr;
         Node* current = other.buckets[i].get();
         Node** dest = reinterpret_cast<Node**>(&buckets[i]);

         while (current) {
            *dest = new Node(current->key, current->value, current->hash);
            dest = reinterpret_cast<Node**>(&(*dest)->next);
            current = current->next.get();
         }
      }
   }

   // Insert or update a key-value pair
   void put(const std::string& key, const std::string& value) {
      if (key.length() >= MAX_KEY_LENGTH || value.length() >= MAX_VALUE_LENGTH) {
         throw KeyTooLongException();
      }

      std::size_t hash = hashFunction(key);
      Node* existing = findNode(key, hash);

      // Update existing key
      if (existing) {
         existing->value = value;
         return;
      }

      // Check if we need to resize
      load_factor = static_cast<double>(count + 1) / table_size;
      if (load_factor > LOAD_FACTOR_THRESHOLD) {
         resizeTable();
      }

      // Create new node
      auto node = std::make_unique<Node>(key, value, hash);
      std::size_t index = hash % table_size;

      // Insert at beginning of chain
      node->next = std::move(buckets[index]);
      buckets[index] = std::move(node);

      count++;
      load_factor = static_cast<double>(count) / table_size;
   }

   // Get a value by key
   std::string get(const std::string& key) const {
      std::size_t hash = hashFunction(key);
      Node* node = findNode(key, hash);

      if (!node) {
         throw KeyNotFoundException(key);
      }

      return node->value;
   }

   // Check if key exists
   bool contains(const std::string& key) const {
      std::size_t hash = hashFunction(key);
      return findNode(key, hash) != nullptr;
   }

   // Remove a key-value pair
   bool remove(const std::string& key) {
      std::size_t hash = hashFunction(key);
      std::size_t index = hash % table_size;

      if (!buckets[index]) {
         return false;
      }

      // Check if first node is the target
      if (buckets[index]->hash == hash && buckets[index]->key == key) {
         buckets[index] = std::move(buckets[index]->next);
         count--;
         load_factor = static_cast<double>(count) / table_size;
         return true;
      }

      // Search in the chain
      Node* current = buckets[index].get();
      while (current->next) {
         if (current->next->hash == hash && current->next->key == key) {
            current->next = std::move(current->next->next);
            count--;
            load_factor = static_cast<double>(count) / table_size;
            return true;
         }
         current = current->next.get();
      }

      return false;
   }

   // Get table statistics
   std::size_t size() const { return count; }
   std::size_t bucketCount() const { return table_size; }
   double getLoadFactor() const { return load_factor; }
   bool empty() const { return count == 0; }

   // Clear all elements
   void clear() {
      for (auto& bucket : buckets) {
         bucket.reset();
      }
      count = 0;
      load_factor = 0.0;
   }

   // Print hash table statistics and contents
   void print() const {
      std::cout << "\n=== Hash Table Statistics ===\n";
      std::cout << "Size: " << table_size << " buckets\n";
      std::cout << "Count: " << count << " items\n";
      std::cout << "Load Factor: " << std::fixed << std::setprecision(3) << load_factor << "\n";

      std::size_t collisions = 0;
      std::size_t max_chain = 0;

      std::cout << "\n=== Contents ===\n";
      for (std::size_t i = 0; i < table_size; ++i) {
         Node* current = buckets[i].get();
         std::size_t chain_length = 0;

         if (current) {
            std::cout << "Bucket " << i << ": ";

            while (current) {
               std::cout << "'" << current->key << "' -> '" << current->value << "'";
               chain_length++;
               current = current->next.get();

               if (current) {
                  std::cout << " -> ";
                  collisions++;
               }
            }
            std::cout << "\n";

            if (chain_length > max_chain) {
               max_chain = chain_length;
            }
         }
      }

      std::cout << "\nCollisions: " << collisions << "\n";
      std::cout << "Max chain length: " << max_chain << "\n";
   }

   // Operator[] for convenient access
   std::string& operator[](const std::string& key) {
      std::size_t hash = hashFunction(key);
      Node* existing = findNode(key, hash);

      if (existing) {
         return existing->value;
      }

      // Create new entry with empty value
      put(key, "");
      return findNode(key, hash)->value;
   }
};

class HashTable {
private:
   // Node structure for chaining
   struct Node {
      std::string key;
      std::unique_ptr<Node> next;

      Node(const std::string& k, const std::string& v, std::size_t h)
      : key(k), value(v), hash(h), next(nullptr) {}
   };

   // Assignment operator
      HashTable& operator=(const HashTable& other) {
      if (this != &other) {
         HashTable temp(other);
         std::swap(buckets, temp.buckets);
         std::swap(table_size, temp.table_size);
         std::swap(count, temp.count);
         std::swap(load_factor, temp.load_factor);
      }
      return *this;
   }

   // Move assignment operator
   HashTable& operator=(HashTable&& other) noexcept {
      if (this != &other) {
         buckets = std::move(other.buckets);
         table_size = other.table_size;
         count = other.count;
         load_factor = other.load_factor;
      }
      return *this;
   }

   // Constants
   static constexpr std::size_t INITIAL_SIZE = 16;
   static constexpr double LOAD_FACTOR_THRESHOLD = 0.75;
   static constexpr std::size_t MAX_KEY_LENGTH = 256;
   static constexpr std::size_t MAX_VALUE_LENGTH = 512;

   std::vector<std::unique_ptr<Node>> buckets;
   std::size_t table_size;
   std::size_t count;
   double load_factor;

   // FNV-1a hash function
   std::size_t hashFunction(const std::string& key) const {
      std::size_t hash = 2166136261u; // FNV offset basis
      const std::size_t prime = 16777619u; // FNV prime

      for (char c : key) {
         hash ^= static_cast<std::uint8_t>(c);
         hash *= prime;
      }

      return hash;
   }

   // Find a node in the table
   Node* findNode(const std::string& key, std::size_t hash) const {
      std::size_t index = hash % table_size;
      Node* current = buckets[index].get();

      while (current) {
         if (current->hash == hash && current->key == key) {
            return current;
         }
         current = current->next.get();
      }

      return nullptr;
   }

   // Resize the table when load factor exceeds threshold
   void resizeTable() {
      std::size_t old_size = table_size;
      auto old_buckets = std::move(buckets);

      // Double the size
      table_size = old_size * 2;
      buckets.resize(table_size);

      // Initialize new buckets
      for (auto& bucket : buckets) {
         bucket = nullptr;
      }

      // Rehash all existing nodes
      for (auto& bucket : old_buckets) {
         Node* current = bucket.release();

         while (current) {
            std::unique_ptr<Node> node(current);
            current = node->next.release();

            std::size_t new_index = node->hash % table_size;
            node->next = std::move(buckets[new_index]);
            buckets[new_index] = std::move(node);
         }
      }

      load_factor = static_cast<double>(count) / table_size;
      std::cout << "Hash table resized to " << table_size << " buckets\n";
   }

public:
   // Exception classes
   class HashTableException : public std::runtime_error {
   public:
      HashTableException(const std::string& msg) : std::runtime_error(msg) {}
   };

   class KeyNotFoundException : public HashTableException {
   public:
      KeyNotFoundException(const std::string& key) 
      : HashTableException("Key not found: " + key) {}
   };

   class KeyTooLongException : public HashTableException {
   public:
      KeyTooLongException() : HashTableException("Key or value too long") {}
   };

   // Constructor
   HashTable() : table_size(INITIAL_SIZE), count(0), load_factor(0.0) {
      buckets.resize(table_size);
      for (auto& bucket : buckets) {
         bucket = nullptr;
      }
   }

   // Destructor (automatic cleanup with smart pointers)
   ~HashTable() = default;

   // Copy constructor
   HashTable(const HashTable& other) 
   : table_size(other.table_size), count(other.count), load_factor(other.load_factor) {
      buckets.resize(table_size);

      for (std::size_t i = 0; i < table_size; ++i) {
         buckets[i] = nullptr;
         Node* current = other.buckets[i].get();
         Node** dest = reinterpret_cast<Node**>(&buckets[i]);

         while (current) {
            *dest = new Node(current->key, current->value, current->hash);
            dest = reinterpret_cast<Node**>(&(*dest)->next);
            current = current->next.get();
         }
      }
   }

   // Insert or update a key-value pair
   void put(const std::string& key, const std::string& value) {
      if (key.length() >= MAX_KEY_LENGTH || value.length() >= MAX_VALUE_LENGTH) {
         throw KeyTooLongException();
      }

      std::size_t hash = hashFunction(key);
      Node* existing = findNode(key, hash);

      // Update existing key
      if (existing) {
         existing->value = value;
         return;
      }

      // Check if we need to resize
      load_factor = static_cast<double>(count + 1) / table_size;
      if (load_factor > LOAD_FACTOR_THRESHOLD) {
         resizeTable();
      }

      // Create new node
      auto node = std::make_unique<Node>(key, value, hash);
      std::size_t index = hash % table_size;

      // Insert at beginning of chain
      node->next = std::move(buckets[index]);
      buckets[index] = std::move(node);

      count++;
      load_factor = static_cast<double>(count) / table_size;
   }

   // Get a value by key
   std::string get(const std::string& key) const {
      std::size_t hash = hashFunction(key);
      Node* node = findNode(key, hash);

      if (!node) {
         throw KeyNotFoundException(key);
      }

      return node->value;
   }

   // Check if key exists
   bool contains(const std::string& key) const {
      std::size_t hash = hashFunction(key);
      return findNode(key, hash) != nullptr;
   }

   // Remove a key-value pair
   bool remove(const std::string& key) {
      std::size_t hash = hashFunction(key);
      std::size_t index = hash % table_size;

      if (!buckets[index]) {
         return false;
      }

      // Check if first node is the target
      if (buckets[index]->hash == hash && buckets[index]->key == key) {
         buckets[index] = std::move(buckets[index]->next);
         count--;
         load_factor = static_cast<double>(count) / table_size;
         return true;
      }

      // Search in the chain
      Node* current = buckets[index].get();
      while (current->next) {
         if (current->next->hash == hash && current->next->key == key) {
            current->next = std::move(current->next->next);
            count--;
            load_factor = static_cast<double>(count) / table_size;
            return true;
         }
         current = current->next.get();
      }

      return false;
   }

   // Get table statistics
   std::size_t size() const { return count; }
   std::size_t bucketCount() const { return table_size; }
   double getLoadFactor() const { return load_factor; }
   bool empty() const { return count == 0; }

   // Clear all elements
   void clear() {
      for (auto& bucket : buckets) {
         bucket.reset();
      }
      count = 0;
      load_factor = 0.0;
   }

   // Print hash table statistics and contents
   void print() const {
      std::cout << "\n=== Hash Table Statistics ===\n";
      std::cout << "Size: " << table_size << " buckets\n";
      std::cout << "Count: " << count << " items\n";
      std::cout << "Load Factor: " << std::fixed << std::setprecision(3) << load_factor << "\n";

      std::size_t collisions = 0;
      std::size_t max_chain = 0;

      std::cout << "\n=== Contents ===\n";
      for (std::size_t i = 0; i < table_size; ++i) {
         Node* current = buckets[i].get();
         std::size_t chain_length = 0;

         if (current) {
            std::cout << "Bucket " << i << ": ";

            while (current) {
               std::cout << "'" << current->key << "' -> '" << current->value << "'";
               chain_length++;
               current = current->next.get();

               if (current) {
                  std::cout << " -> ";
                  collisions++;
               }
            }
            std::cout << "\n";

            if (chain_length > max_chain) {
               max_chain = chain_length;
            }
         }
      }

      std::cout << "\nCollisions: " << collisions << "\n";
      std::cout << "Max chain length: " << max_chain << "\n";
   }

   // Operator[] for convenient access
   std::string& operator[](const std::string& key) {
      std::size_t hash = hashFunction(key);
      Node* existing = findNode(key, hash);

      if (existing) {
         return existing->value;
      }

      // Create new entry with empty value
      put(key, "");
      return findNode(key, hash)->value;
   }
};

// Demo function
int main() {
   std::cout << "C++ Hash Table Implementation Demo\n";
   std::cout << "==================================\n";

   try {
      HashTable table;

      // Test data
      std::vector<std::pair<std::string, std::string>> test_data = {
         {"name", "John Doe"},
         {"age", "30"},
         {"city", "New York"},
         {"country", "USA"},
         {"email", "john@example.com"},
         {"phone", "555-1234"},
         {"address", "123 Main St"},
         {"zip", "10001"},
         {"state", "NY"},
         {"language", "English"}
      };

      // Insert test data
      std::cout << "Inserting test data...\n";
      for (const auto& [key, value] : test_data) {
         table.put(key, value);
         std::cout << "✓ Inserted: '" << key << "' -> '" << value << "'\n";
      }

      // Test retrieval
      std::cout << "\nTesting retrieval...\n";
      for (const auto& [key, expected_value] : test_data) {
         try {
            std::string value = table.get(key);
            std::cout << "✓ Found: '" << key << "' -> '" << value << "'\n";
         } catch (const HashTable::KeyNotFoundException& e) {
            std::cout << "✗ " << e.what() << "\n";
         }
      }

      // Test operator[]
      std::cout << "\nTesting operator[]...\n";
      std::cout << "Name via operator[]: " << table["name"] << "\n";
      table["nickname"] = "Johnny";
      std::cout << "Added nickname: " << table["nickname"] << "\n";

      // Update a value
      std::cout << "\nUpdating 'age' to '31'...\n";
      table.put("age", "31");
      std::cout << "New age value: " << table.get("age") << "\n";

      // Print table statistics
      table.print();

      // Test removal
      std::cout << "\nRemoving 'phone'...\n";
      if (table.remove("phone")) {
         std::cout << "✓ Successfully removed 'phone'\n";
      } else {
         std::cout << "✗ Failed to remove 'phone'\n";
      }

      // Verify removal
      if (!table.contains("phone")) {
         std::cout << "✓ Confirmed: 'phone' no longer exists\n";
      }

      // Test copy constructor
      std::cout << "\nTesting copy constructor...\n";
      HashTable table_copy(table);
      std::cout << "Original table size: " << table.size() << "\n";
      std::cout << "Copied table size: " << table_copy.size() << "\n";

      std::cout << "\nDemo complete!\n";

   } catch (const std::exception& e) {
      std::cerr << "Error: " << e.what() << "\n";
      return EXIT_FAILURE;
   }

   return EXIT_SUCCESS;
}
