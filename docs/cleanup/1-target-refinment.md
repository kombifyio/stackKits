Feature Audit & Target State Refinement

This strategy ensures the TARGET_STATE.md is granular enough to drive a code cleanup. It introduces a categorization matrix to decide exactly what stays and what goes.

1. The Feature Audit Matrix

A structured list where every feature is assigned one of three statuses:

MANDATORY: Essential for the Target State. Keep and refactor.

OPTIONAL: Nice-to-have. Keep only if complexity is low.

REMOVE/DEPRECATED: Legacy or out-of-scope. Target for deletion.

2. The Feature Extraction & Audit Prompt

Use this prompt to generate the comprehensive feature list. Feed it with your STATUS_QUO.md, existing docs, and rough notes.

Role: Technical Product Manager & System Architect.

Task: Create a granular Feature Audit Matrix to refine the Target State and prepare for code cleanup.

Input Context:

Current Code/Status Quo: [Provide STATUS_QUO.md or code overview]

Initial Target Vision: [Provide preliminary TARGET_STATE.md]

Objective:
Generate a comprehensive table of all features and technical capabilities identified in the project.

Output Requirements:
Create a table with the following columns:

Feature/Component Name: Clear technical name.

Description: Brief explanation of its function.

Status: [MANDATORY | OPTIONAL | REMOVE] based on the Target Vision.

Cleanup Action: Specific instruction (e.g., "Refactor to standard", "Delete logic and tests", "Extract to shared lib").

Dependency Risk: High/Med/Low (How much will removing/changing this affect other repos?).

Categorization Logic:

MANDATORY: Features that directly support the core value proposition.

OPTIONAL: Legacy features that are still used but not strategic, or future features not yet core.

REMOVE: Redundant code, "dead wood," over-engineered patterns, or features that no longer fit the project goals.

Final Summary:
List the top 5 components that should be prioritized for total removal to reduce complexity immediately.

3. Integration into the Workflow

Generate Audit: Run the prompt above to get the full list.

Stakeholder Review: Manually verify the "Status" column. This is your final "Go/No-Go" list for the code.

Update Target State: Copy the Mandatory and Optional features into your final TARGET_STATE.md.

Execute Refactoring: Use the "Cleanup Action" column as specific input for the Master Refactoring Prompt (from the Refactoring Strategy doc).

4. Maintenance

As the code becomes cleaner, move features from the Feature Audit Matrix to the CHANGELOG.md (under the "Removed" or "Changed" sections) to keep the team informed of the architectural shift.