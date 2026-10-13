import '../domain/models/mcq_question.dart';

/// Exactly 10 Multiple Choice Questions for the examination session.
/// Note: The correct answer indices are NOT present here.
abstract class SampleMcqs {
  static const List<McqQuestion> questions = [
    McqQuestion(
      id: 'mcq_1',
      number: 1,
      text: 'What is the time complexity of searching for an element in a balanced Binary Search Tree (AVL/Red-Black)?',
      options: [
        'O(1)',
        'O(log n)',
        'O(n)',
        'O(n log n)',
      ],
    ),
    McqQuestion(
      id: 'mcq_2',
      number: 2,
      text: 'In JavaScript, which operator performs strict equality comparison without type coercion?',
      options: [
        '==',
        '===',
        '=',
        '!==',
      ],
    ),
    McqQuestion(
      id: 'mcq_3',
      number: 3,
      text: 'Which data structure operates on a Last-In, First-Out (LIFO) order?',
      options: [
        'Queue',
        'Priority Queue',
        'Stack',
        'Circular Buffer',
      ],
    ),
    McqQuestion(
      id: 'mcq_4',
      number: 4,
      text: 'In relational databases, which ACID property ensures that transactions are either fully committed or completely rolled back?',
      options: [
        'Atomicity',
        'Consistency',
        'Isolation',
        'Durability',
      ],
    ),
    McqQuestion(
      id: 'mcq_5',
      number: 5,
      text: 'What is the primary role of the JavaScript Event Loop in a browser runtime?',
      options: [
        'Compiling JavaScript source to native machine code',
        'Managing concurrent CPU threads directly in the OS',
        'Orchestrating asynchronous callbacks, Promises, and the Call Stack',
        'Allocating memory heap chunks for garbage collection',
      ],
    ),
    McqQuestion(
      id: 'mcq_6',
      number: 6,
      text: 'Which HTTP response status code signifies that a resource was successfully created on the server?',
      options: [
        '200 OK',
        '201 Created',
        '204 No Content',
        '304 Not Modified',
      ],
    ),
    McqQuestion(
      id: 'mcq_7',
      number: 7,
      text: 'In symmetric cryptography, what key is used for both encrypting and decrypting data?',
      options: [
        'The same shared secret key',
        'A public key for encryption and private key for decryption',
        'A digital certificate signed by a root CA',
        'A cryptographic one-way hash digest',
      ],
    ),
    McqQuestion(
      id: 'mcq_8',
      number: 8,
      text: 'What is the average time complexity of the QuickSort algorithm?',
      options: [
        'O(n)',
        'O(n log n)',
        'O(n^2)',
        'O(log n)',
      ],
    ),
    McqQuestion(
      id: 'mcq_9',
      number: 9,
      text: 'Which CSS layout model provides one-dimensional layout control along a primary and cross axis?',
      options: [
        'CSS Grid',
        'Flexbox',
        'Float layout',
        'Table layout',
      ],
    ),
    McqQuestion(
      id: 'mcq_10',
      number: 10,
      text: 'In software architecture, what does the "S" stand for in the SOLID design principles?',
      options: [
        'State Pattern Principle',
        'Single Responsibility Principle',
        'Security-by-Design Principle',
        'Singleton Principle',
      ],
    ),
  ];
}
