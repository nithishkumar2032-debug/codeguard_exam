import '../domain/models/coding_challenge.dart';

/// Exactly 2 JavaScript coding challenges for the exam session.
abstract class SampleCodingChallenges {
  static const List<CodingChallenge> challenges = [
    CodingChallenge(
      id: 'code_1',
      number: 1,
      title: 'Valid Palindrome Checker',
      description:
          'Write a JavaScript function `isPalindrome(str)` that determines if a given string '
          'is a palindrome, reading the same forwards and backwards. The function should be '
          'case-insensitive and ignore non-alphanumeric characters.',
      language: 'JavaScript',
      starterCode: '''/**
 * Checks whether a given string is a palindrome.
 * @param {string} str
 * @returns {boolean}
 */
function isPalindrome(str) {
  // Your implementation here
  
}
''',
      sampleInput: 'isPalindrome("A man, a plan, a canal: Panama")',
      sampleOutput: 'true',
      testCases: [
        CodingTestCase(
          input: '"A man, a plan, a canal: Panama"',
          expectedOutput: 'true',
        ),
        CodingTestCase(
          input: '"race a car"',
          expectedOutput: 'false',
        ),
        CodingTestCase(
          input: '"Madam"',
          expectedOutput: 'true',
        ),
      ],
    ),
    CodingChallenge(
      id: 'code_2',
      number: 2,
      title: 'Two Sum Target Indices',
      description:
          'Write a JavaScript function `twoSum(nums, target)` that returns the zero-based indices '
          'of the two numbers in `nums` that add up to `target`. Assume each input has exactly one '
          'valid solution and the same element may not be used twice. Return an array of two indices `[i, j]`.',
      language: 'JavaScript',
      starterCode: '''/**
 * Finds two indices in nums that sum to target.
 * @param {number[]} nums
 * @param {number} target
 * @returns {number[]}
 */
function twoSum(nums, target) {
  // Your implementation here
  
}
''',
      sampleInput: 'twoSum([2, 7, 11, 15], 9)',
      sampleOutput: '[0, 1]',
      testCases: [
        CodingTestCase(
          input: '[2, 7, 11, 15], 9',
          expectedOutput: '[0, 1]',
        ),
        CodingTestCase(
          input: '[3, 2, 4], 6',
          expectedOutput: '[1, 2]',
        ),
        CodingTestCase(
          input: '[3, 3], 6',
          expectedOutput: '[0, 1]',
        ),
      ],
    ),
  ];
}
