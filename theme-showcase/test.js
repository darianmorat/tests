// ES6+ modules and imports
import { EventEmitter } from "events";

// Classes with private fields and methods
class DataProcessor extends EventEmitter {
   #cache = new Map();
   #isProcessing = false;

   constructor(options = {}) {
      super();
      this.timeout = options.timeout ?? 5000;
      this.maxRetries = options.maxRetries ?? 3;
   }

   // Async/await with error handling
   async processData(data, transform = (x) => x) {
      if (this.#isProcessing) {
         throw new Error("Already processing");
      }

      this.#isProcessing = true;
      this.emit("start", { timestamp: Date.now() });

      try {
         const result = await this.#performProcessing(data, transform);
         this.emit("success", result);
         return result;
      } catch (error) {
         this.emit("error", error);
         throw error;
      } finally {
         this.#isProcessing = false;
      }
   }

   // Private method with timeout and retries
   async #performProcessing(data, transform, attempt = 1) {
      const cacheKey = JSON.stringify(data);

      if (this.#cache.has(cacheKey)) {
         return this.#cache.get(cacheKey);
      }

      try {
         const processed = await Promise.race([
            this.#processWithDelay(data, transform),
            this.#createTimeout(),
         ]);

         this.#cache.set(cacheKey, processed);
         return processed;
      } catch (error) {
         if (attempt < this.maxRetries) {
            console.warn(`Attempt ${attempt} failed, retrying...`);
            return this.#performProcessing(data, transform, attempt + 1);
         }
         throw error;
      }
   }

   #createTimeout() {
      return new Promise((_, reject) => {
         setTimeout(() => reject(new Error("Timeout")), this.timeout);
      });
   }

   async #processWithDelay(data, transform) {
      // Simulate async processing
      await new Promise((resolve) => setTimeout(resolve, Math.random() * 1000));
      return data.map(transform).filter(Boolean);
   }

   // Generator function
   *getCachedEntries() {
      for (const [key, value] of this.#cache.entries()) {
         yield { key: JSON.parse(key), value, cached: true };
      }
   }

   // Static method with object destructuring
   static validateConfig({ timeout, maxRetries, ...rest }) {
      const errors = [];

      if (timeout !== undefined && typeof timeout !== "number") {
         errors.push("timeout must be a number");
      }

      if (maxRetries !== undefined && !Number.isInteger(maxRetries)) {
         errors.push("maxRetries must be an integer");
      }

      if (Object.keys(rest).length > 0) {
         errors.push(`Unknown options: ${Object.keys(rest).join(", ")}`);
      }

      return errors;
   }
}

// Functional programming with higher-order functions
const createPipeline =
   (...fns) =>
   (value) =>
      fns.reduce((acc, fn) => fn(acc), value);

const asyncPipe =
   (...fns) =>
   async (value) => {
      let result = value;
      for (const fn of fns) {
         result = await fn(result);
      }
      return result;
   };

// Arrow functions and array methods
const utils = {
   debounce: (fn, delay) => {
      let timeoutId;
      return (...args) => {
         clearTimeout(timeoutId);
         timeoutId = setTimeout(() => fn.apply(this, args), delay);
      };
   },

   groupBy: (array, keyFn) =>
      array.reduce((groups, item) => {
         const key = keyFn(item);
         groups[key] = groups[key] ?? [];
         groups[key].push(item);
         return groups;
      }, {}),

   partition: (array, predicate) => [
      array.filter(predicate),
      array.filter((item) => !predicate(item)),
   ],
};

// Async IIFE with top-level await simulation
(async () => {
   const processor = new DataProcessor({ timeout: 2000, maxRetries: 2 });

   // Event listeners with arrow functions
   processor.on("start", ({ timestamp }) =>
      console.log(`Processing started at ${new Date(timestamp).toISOString()}`),
   );

   processor.on("error", (error) => console.error("Processing failed:", error.message));

   // Sample data with various transformations
   const sampleData = [
      { id: 1, value: 10 },
      { id: 2, value: 20 },
      { id: 3, value: null },
   ];

   try {
      // Promise.all with array of async operations
      const results = await Promise.all([
         processor.processData(sampleData, (item) => ({
            ...item,
            doubled: item.value * 2,
         })),
         processor.processData([1, 2, 3, 4, 5], (x) => x ** 2),
         processor.processData(["hello", "world"], (s) => s.toUpperCase()),
      ]);

      console.log("All results:", results);

      // Spread operator and rest parameters
      const [first, ...remaining] = results;
      console.log("First result:", first);
      console.log("Remaining:", remaining.length);

      // Object.fromEntries and Map usage
      const summary = Object.fromEntries(
         results.map((result, index) => [`result_${index}`, result.length]),
      );
      console.log("Summary:", summary);
   } catch (error) {
      c;
   }

   // Demonstrate generator usage
   console.log("\nCached entries:");
   for (const entry of processor.getCachedEntries()) {
      console.log(`Key: ${JSON.stringify(entry.key)}, Items: ${entry.value.length}`);
   }
})();

// Export for module usage
export { DataProcessor, utils, createPipeline, asyncPipe };
onsole.error("Batch processing failed:", error);
