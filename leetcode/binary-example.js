function binarySearch(array, target, start = 0, end = array.length - 1) {
   // BASE CASE: Not found
   if (start > end) {
      return -1; // or "not found"
   }

   // Find the middle
   let middle = Math.floor((start + end) / 2);
   console.log(middle); // splits made

   // Found it!
   if (array[middle] === target) {
      return middle;
   }

   // Search left half
   if (target < array[middle]) {
      return binarySearch(array, target, start, middle - 1); // end becomes 6 index
   }

   // Search right half
   return binarySearch(array, target, middle + 1, end); // start becomes 4 index
}
