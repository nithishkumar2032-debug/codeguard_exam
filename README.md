# CodeGuard Exam 🛡️

A secure, responsive online examination web portal built with **Flutter Web** and **Supabase**, featuring real-time proctoring, dual-tier lifecycle violation detection, server-authoritative countdown timers, and persistent question/draft synchronization.

---

## 🌐 Live Application & Links

- **Live Web Portal**: [https://nithishkumar2032-debug.github.io/codeguard_exam/](https://nithishkumar2032-debug.github.io/codeguard_exam/)
- **GitHub Repository**: [https://github.com/nithishkumar2032-debug/codeguard_exam](https://github.com/nithishkumar2032-debug/codeguard_exam)
- **Supabase Backend**: [https://lhhhyhwyqzdosoqktwjw.supabase.co](https://lhhhyhwyqzdosoqktwjw.supabase.co)

---

## ✨ Key Features

1. **Responsive Material 3 Assessment Interface**
   - Clean, accessible candidate onboarding with name, register number, and exam selection.
   - Comprehensive exam instructions screen with security rules and question breakdown.
   - Question navigation palette with status chips (Answered, Flagged for Review, Unanswered).

2. **Dual-Tier Browser Integrity & Proctoring System**
   - Real-time detection of browser tab switching (`visibilitychange`) and window unfocusing (`blur`).
   - Debounced coalescing of overlapping events to prevent duplicate penalty counts.
   - **First Violation**: Displays a non-dismissible warning dialog alerting the candidate upon return.
   - **Second Violation**: Instantly locks and auto-submits the exam with reason `Terminated due to multiple tab-switching violations`.

3. **Hybrid Examination Engine**
   - **Multiple Choice Questions (MCQs)**: Single-choice selection with immediate draft persistence.
   - **Live Coding Challenges**: In-browser code editing with test cases, starter code reset, and custom test runner simulation.

4. **Server-Authoritative Timing & Supabase Persistence**
   - 30-minute exam countdown bound to server timestamp (`expires_at`).
   - Automatic background draft saving to Supabase (`candidate_question_responses` and `candidate_coding_drafts`).
   - Resilient offline fallback using browser local storage when disconnected.
   - Row-Level Security (RLS) policies guaranteeing candidates can only read their own exam records.

---

## 🏗️ Architecture & Technology Stack

- **Frontend**: Flutter Web (Dart 3.12, Material 3)
- **Backend & Database**: Supabase (PostgreSQL 15, Anonymous Auth, Row-Level Security)
- **Hosting**: GitHub Pages via automated GitHub Actions CI/CD
- **Testing**: Comprehensive unit, widget, lifecycle, and security schema tests

---

## 🚀 Running Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.12 or newer)
- Google Chrome

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/nithishkumar2032-debug/codeguard_exam.git
   cd codeguard_exam
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run in Chrome:
   ```bash
   flutter run -d chrome
   ```

4. Run all automated tests:
   ```bash
   flutter test
   ```

---

## 📦 Building for Production

To produce the static web bundle for deployment:
```bash
flutter build web --release --base-href "/codeguard_exam/"
```
The output will be generated in `build/web/`.
