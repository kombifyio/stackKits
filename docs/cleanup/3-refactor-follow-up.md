Code Refactoring & Complexity Reduction Strategy

This strategy follows the documentation cleanup. Its goal is to align the codebase with the TARGET_STATE.md while stripping away unnecessary complexity, duplication, and legacy logic.

1. Core Principles

Functionality Preservation: No behavioral changes unless explicitly required by the Target State.

Idempotency: The prompt can be applied repeatedly to the same or updated code to achieve incremental improvements.

DRY & YAGNI: Remove "Dead Wood" (unused code) and "Gold Plating" (over-engineered solutions).

Standardization: Aligning naming conventions and patterns across the multi-repo project.

2. The Master Refactoring Prompt

Use this prompt for each file or module. Provide the TARGET_STATE.md and STATUS_QUO.md as context alongside the source code.

Role: Expert Software Engineer & Refactoring Specialist.

Context: > 1. Target State: [Reference/Link to TARGET_STATE.md]
2. Current Status: [Reference/Link to STATUS_QUO.md]

Task: Perform an idempotent, complexity-reducing refactor of the provided code.

Objectives:

Dead Code Removal: Delete any functions, variables, or imports that are not utilized or do not support the Target State.

Complexity Reduction: Simplify nested logic, replace over-engineered patterns with standard solutions, and improve readability.

Eliminate Redundancy: Identify and merge duplicated logic (DRY).

Standardization: Ensure naming and structure follow the project's core architecture.

Constraints:

Maintain existing public API signatures unless a change is explicitly documented in the Target State.

Do not add new features.

Ensure the code remains functionally identical for all required features.

Output Format:

Refactored Code: The complete, cleaned-up file content.

Refactoring Log:

Removed: List of deleted components/logic.

Simplified: Description of logic that was made more concise.

Reasoning: Why these changes align with the Target State and reduce complexity.

3. Iterative Workflow (The "Loop")

Selection: Choose a module or file identified in the "Cleanup List" of your Documentation Phase.

Execution: Run the Master Refactoring Prompt.

Validation: Verify the refactored code against existing tests.

Re-Iteration: If the code still feels complex, feed the refactored result back into the prompt for a second pass.

Integration: Merge the cleaned code and update the STATUS_QUO.md to reflect the improvements.