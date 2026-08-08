# SysAdmin LearnApp - Claude Code Guideline

## Build & Run Commands
- Build project: `swift build`
- Run application: `swift run`
- Run tests: `swift test`

## Code Style & Architecture
- **Language:** Swift 6.x (Strict Concurrency checking).
- **Structure:** Modular design with a clear separation between Lesson data and the interactive CLI Shell.
- **Error Handling:** Use Swift's `Result` type or `throws` for system command executions. Do not use force-unwraps (`!`).
- **Dependencies:** Keep external Swift Package Manager (SPM) dependencies to a minimum. Prefer native `Foundation` APIs.
