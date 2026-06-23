DELETE ONE OF THE NEXT TWO LINES:
Use the CURRENT git worktree for this work.
Create a NEW git worktree for this work.

DELETE THE NEXT LINE IF YOU DO NOT WANT TO BE ASKED QUESTIONS:
Before doing anything, ask me lots of clarifying questions using the multi-select question tool (AskUserQuestion), and wait for my answers before proceeding.

# Feature request

**Goal:** {{what you want to build, in one sentence}}

**Details / requirements:**
- {{requirement 1}}
- {{requirement 2}}

**Constraints:** {{anything to avoid, patterns to follow, perf/security notes}}

## Workflow

1. Branch from the latest `main` pulled fresh from the remote (`git fetch origin` then branch off `origin/main`). All work goes into a new PR off this branch.
2. Follow strict TDD:
   - Write one failing test at a time.
   - Commit that test on its own ("test: ...") BEFORE writing any implementation.
   - Then implement the minimum needed to make it pass and commit the fix separately.
   - Repeat for each behaviour.
   - For each step ensure that you update a todo markdown so progress can be tracked.
3. **Done when all tests are passing.**
4. Open the PR.

## After implementation, dispatch sub-agents (each as a separate sub-agent task)

- Sub-agent 1: Check that every test follows the AAA (Arrange, Act, Assert) structure. Fix any that do not.
- Sub-agent 2: Check that every test name uses the "when" naming convention. Fix any that do not.
- Sub-agent 3: Check for over-mocked tests and simplify/fix them.
- Sub-agent 4: Verify the PR description correctly reflects the actual changes made to the code; update it if not.
- Sub-agent 5: Review the code the same way the `/code-reviewer` command does, posting findings as markdown via the GitHub Actions review flow. If this project does not support that flow, run the `/code-review` command instead.

Follow the conventions already in the codebase throughout.
