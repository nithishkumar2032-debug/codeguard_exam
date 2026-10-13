-- ============================================================================
-- Migration: 20261014000004_seed_assessment_data.sql
-- Description: Seed initial exam definition, 10 MCQs, protected answer keys,
--              and 2 coding challenges with public and hidden test cases.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Seed: Exam
-- ----------------------------------------------------------------------------
INSERT INTO public.exams (id, title, description, duration_seconds, is_active)
VALUES (
    'cs301_dsa_final',
    'CS301 - Data Structures & Algorithms Final',
    'Official proctored examination covering core data structures, algorithms, and web execution concepts.',
    1800,
    TRUE
)
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    duration_seconds = EXCLUDED.duration_seconds,
    is_active = EXCLUDED.is_active;

-- ----------------------------------------------------------------------------
-- 2. Seed: 10 MCQ Questions (Candidate-Visible)
-- ----------------------------------------------------------------------------
INSERT INTO public.mcq_questions (id, exam_id, question_number, question_text, options)
VALUES
(
    'mcq_1',
    'cs301_dsa_final',
    1,
    'What is the time complexity of searching for an element in a balanced Binary Search Tree (AVL/Red-Black)?',
    '["O(1)", "O(log n)", "O(n)", "O(n log n)"]'::jsonb
),
(
    'mcq_2',
    'cs301_dsa_final',
    2,
    'In JavaScript, which operator performs strict equality comparison without type coercion?',
    '["==", "===", "=", "!=="]'::jsonb
),
(
    'mcq_3',
    'cs301_dsa_final',
    3,
    'Which data structure operates on a Last-In, First-Out (LIFO) order?',
    '["Queue", "Priority Queue", "Stack", "Circular Buffer"]'::jsonb
),
(
    'mcq_4',
    'cs301_dsa_final',
    4,
    'In relational databases, which ACID property ensures that transactions are either fully committed or completely rolled back?',
    '["Atomicity", "Consistency", "Isolation", "Durability"]'::jsonb
),
(
    'mcq_5',
    'cs301_dsa_final',
    5,
    'What is the primary role of the JavaScript Event Loop in a browser runtime?',
    '["Compiling JavaScript source to native machine code", "Managing concurrent CPU threads directly in the OS", "Orchestrating asynchronous callbacks, Promises, and the Call Stack", "Allocating memory heap chunks for garbage collection"]'::jsonb
),
(
    'mcq_6',
    'cs301_dsa_final',
    6,
    'Which HTTP response status code signifies that a resource was successfully created on the server?',
    '["200 OK", "201 Created", "204 No Content", "304 Not Modified"]'::jsonb
),
(
    'mcq_7',
    'cs301_dsa_final',
    7,
    'In symmetric cryptography, what key is used for both encrypting and decrypting data?',
    '["The same shared secret key", "A public key for encryption and private key for decryption", "A digital certificate signed by a root CA", "A cryptographic one-way hash digest"]'::jsonb
),
(
    'mcq_8',
    'cs301_dsa_final',
    8,
    'What is the average time complexity of the QuickSort algorithm?',
    '["O(n)", "O(n log n)", "O(n^2)", "O(log n)"]'::jsonb
),
(
    'mcq_9',
    'cs301_dsa_final',
    9,
    'Which CSS layout model provides one-dimensional layout control along a primary and cross axis?',
    '["CSS Grid", "Flexbox", "Float layout", "Table layout"]'::jsonb
),
(
    'mcq_10',
    'cs301_dsa_final',
    10,
    'In software architecture, what does the "S" stand for in the SOLID design principles?',
    '["State Pattern Principle", "Single Responsibility Principle", "Security-by-Design Principle", "Singleton Principle"]'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
    exam_id = EXCLUDED.exam_id,
    question_number = EXCLUDED.question_number,
    question_text = EXCLUDED.question_text,
    options = EXCLUDED.options;

-- ----------------------------------------------------------------------------
-- 3. Seed: MCQ Answer Keys (PROTECTED - Zero Client Access)
-- ----------------------------------------------------------------------------
INSERT INTO public.mcq_answer_keys (question_id, correct_option_index, explanation)
VALUES
('mcq_1', 1, 'In a balanced BST with height h = log2(n), search operations halve the search space at each node.'),
('mcq_2', 1, 'The strict equality operator (===) checks both value and type without performing implicit coercion.'),
('mcq_3', 2, 'A Stack follows the Last-In, First-Out (LIFO) discipline where push and pop operate at the top.'),
('mcq_4', 0, 'Atomicity ensures that all statements within a transaction succeed or all are rolled back as an indivisible unit.'),
('mcq_5', 2, 'The Event Loop checks whether the call stack is empty and coordinates pushing tasks from microtask and macrotask queues.'),
('mcq_6', 1, 'HTTP 201 Created indicates the request succeeded and resulted in creation of a new resource.'),
('mcq_7', 0, 'Symmetric encryption schemes (e.g. AES, ChaCha20) share an identical secret key between communicating parties.'),
('mcq_8', 1, 'QuickSort partitions around a pivot in O(n) across O(log n) balanced recursion depth on average.'),
('mcq_9', 1, 'Flexbox arranges elements along a single dimensional flow (row or column). CSS Grid handles 2D layouts.'),
('mcq_10', 1, 'In SOLID, S denotes Single Responsibility: a class or module should have one, and only one, reason to change.')
ON CONFLICT (question_id) DO UPDATE SET
    correct_option_index = EXCLUDED.correct_option_index,
    explanation = EXCLUDED.explanation;

-- ----------------------------------------------------------------------------
-- 4. Seed: 2 Coding Challenges (Candidate-Visible)
-- ----------------------------------------------------------------------------
INSERT INTO public.coding_challenges (id, exam_id, challenge_number, title, description, language, starter_code, sample_input, sample_output)
VALUES
(
    'code_1',
    'cs301_dsa_final',
    1,
    'Valid Palindrome Checker',
    'Write a JavaScript function `isPalindrome(str)` that determines if a given string is a palindrome, reading the same forwards and backwards. The function should be case-insensitive and ignore non-alphanumeric characters.',
    'JavaScript',
    E'/**\n * Checks whether a given string is a palindrome.\n * @param {string} str\n * @returns {boolean}\n */\nfunction isPalindrome(str) {\n  // Your implementation here\n  \n}\n',
    'isPalindrome("A man, a plan, a canal: Panama")',
    'true'
),
(
    'code_2',
    'cs301_dsa_final',
    2,
    'Two Sum Target Indices',
    'Write a JavaScript function `twoSum(nums, target)` that returns the zero-based indices of the two numbers in `nums` that add up to `target`. Assume each input has exactly one valid solution and the same element may not be used twice. Return an array of two indices `[i, j]`.',
    'JavaScript',
    E'/**\n * Finds two indices in nums that sum to target.\n * @param {number[]} nums\n * @param {number} target\n * @returns {number[]}\n */\nfunction twoSum(nums, target) {\n  // Your implementation here\n  \n}\n',
    'twoSum([2, 7, 11, 15], 9)',
    '[0, 1]'
)
ON CONFLICT (id) DO UPDATE SET
    exam_id = EXCLUDED.exam_id,
    challenge_number = EXCLUDED.challenge_number,
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    language = EXCLUDED.language,
    starter_code = EXCLUDED.starter_code,
    sample_input = EXCLUDED.sample_input,
    sample_output = EXCLUDED.sample_output;

-- ----------------------------------------------------------------------------
-- 5. Seed: Public Sample Test Cases
-- ----------------------------------------------------------------------------
DELETE FROM public.coding_test_cases WHERE challenge_id IN ('code_1', 'code_2');

INSERT INTO public.coding_test_cases (challenge_id, input, expected_output, test_order)
VALUES
-- Palindrome sample test cases
('code_1', '"A man, a plan, a canal: Panama"', 'true', 1),
('code_1', '"race a car"', 'false', 2),
('code_1', '"Madam"', 'true', 3),

-- Two sum sample test cases
('code_2', '[2, 7, 11, 15], 9', '[0, 1]', 1),
('code_2', '[3, 2, 4], 6', '[1, 2]', 2),
('code_2', '[3, 3], 6', '[0, 1]', 3);

-- ----------------------------------------------------------------------------
-- 6. Seed: Hidden Test Cases (PROTECTED - Zero Client Access)
-- ----------------------------------------------------------------------------
DELETE FROM public.coding_hidden_test_cases WHERE challenge_id IN ('code_1', 'code_2');

INSERT INTO public.coding_hidden_test_cases (challenge_id, input, expected_output, test_order)
VALUES
-- Palindrome hidden test cases
('code_1', '"No ''x'' in Nixon"', 'true', 1),
('code_1', '"12321"', 'true', 2),
('code_1', '"12345"', 'false', 3),
('code_1', '"Was it a car or a cat I saw?"', 'true', 4),

-- Two sum hidden test cases
('code_2', '[1, 5, 8, 12, 19], 20', '[0, 4]', 1),
('code_2', '[10, -2, 5, 3], 8', '[0, 1]', 2),
('code_2', '[0, 4, 3, 0], 0', '[0, 3]', 3);
