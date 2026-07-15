class Solution {
   // #1
   hasDuplicate(nums) {
      const noDuplicate = [...new Set(nums)] // is a collection of unique values
      return noDuplicate
   }

   // #2
   isAnagram(s, t) {
      return s.split("").sort().join() === t.split("").sort().join()
   }

   // #3
   twoSum(nums, target) {
      const prevMap = new Map()

      for (let i = 0; i < nums.length; i++) {
         const diff = target - nums[i]
         if (prevMap.has(diff)) {
            return [prevMap.get(diff), i]
         }
         prevMap.set(nums[i], i)
      }
   }

   // #4
   groupAnagrams(strs) {
      let sorting = strs.map((item) => item.split("").sort().join(""))
      let group = sorting.filter((item) => item === item)
      return group
   }

   // #5
   isPalindrome(s) {
      const letters = s
         .split("")
         .filter((ch) => /[a-z0-9]/i.test(ch))
         .join("")
         .toLowerCase()

      return letters === letters.split("").reverse().join("")
   }

   // #6
   binarySearch(arr, target) {
      let left = 0
      let right = arr.length - 1

      while (left <= right) {
         let mid = Math.floor((left + right) / 2)

         if (target === arr[mid]) {
            return mid
         }

         if (target < arr[mid]) {
            right = mid - 1
         } else {
            left = mid + 1
         }
      }

      return -1
   }

   // #7
   camelCasingSplit(str) {
      const result = str
         .split("")
         .map((l, i) => (l.toUpperCase() === l && i !== 0 ? " " + l : l))
         .join("")

      return result
   }

   // #8
}

const solution = new Solution()

// #1
console.log(solution.hasDuplicate([1, 2, 3, 3]))

// #2
// console.log(solution.isAnagram('racecar', 'carrace'));

// #3
// console.log(solution.twoSum([2, 2, 2, 2], 4));

// #4
// console.log(solution.groupAnagrams(['act', 'pots', 'tops', 'cat', 'stop', 'hat']));

// #5
// console.log(solution.isPalindrome("Was it a car or a cat I saw?"));

// #6
// console.log(solution.binarySearch([-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12], 8));

// #7
// console.log(solution.camelCasingSplit("DarianToledoMora"));

// #8
