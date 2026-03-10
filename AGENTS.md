# Multi-Layer Bounty Hunter Architecture

## ANTI-HALLUCINATION CONTROLS

### 1. STRUCTURED OUTPUT (Required)
All outputs MUST use XML structure:
```xml
<task_result>
    <action>search|analyze|code|verify</action>
    <source_url></source_url>
    <data></data>
    <confidence>0.0-1.0</confidence>
    <evidence></evidence>
</task_result>
```

### 2. EVIDENCE REQUIREMENT
Every claim MUST have source:
- NO source = REJECT output
- NO fabrication allowed
- If unknown → output "UNKNOWN"

### 3. HARD STOP RULES
- max_iterations: 5
- max_repos_per_session: 3
- max_files_changed: 3
- timeout: 600 seconds

### 4. CONFIDENCE SCORING
- < 0.6: DISCARD
- 0.6-0.8: MANUAL REVIEW
- > 0.8: ACCEPT

## AGENT LAYERS

### Layer 1: DISCOVERY AGENT
**Task:** Find high-score issues
**Tools:** GitHub API, web search
**Output:**
```xml
<discovery_result>
    <issue_url></issue_url>
    <score>0-50</score>
    <labels></labels>
    <confidence>0.0-1.0</confidence>
</discovery_result>
```
**Rules:**
- Only search GitHub API
- Score each issue (min 15)
- NO assumptions about repo
- Return UNKNOWN if data missing

### Layer 2: ANALYSIS AGENT
**Task:** Verify issue is solvable
**Tools:** git clone, read files, exec tests
**Output:**
```xml
<analysis_result>
    <repo_cloned>true|false</repo_cloned>
    <has_tests>true|false</has_tests>
    <test_framework>pytest|jest|cargo|NONE</test_framework>
    <files_to_change>1-3</files_to_change>
    <solvable>true|false</solvable>
    <confidence>0.0-1.0</confidence>
</analysis_result>
```
**Rules:**
- Clone repo first
- Run tests to verify
- Count files needed
- If > 3 files → REJECT

### Layer 3: CODING AGENT
**Task:** Generate minimal patch
**Tools:** read, write, edit
**Output:**
```xml
<coding_result>
    <files_changed></files_changed>
    <patch_type>typo|import|lint|logic</patch_type>
    <lines_changed>1-50</lines_changed>
    <confidence>0.0-1.0</confidence>
</coding_result>
```
**Rules:**
- MINIMAL changes only
- Max 50 lines changed
- NO refactoring
- NO architecture changes

### Layer 4: VERIFICATION AGENT
**Task:** Verify patch works
**Tools:** exec (run tests)
**Output:**
```xml
<verification_result>
    <tests_passed>true|false</tests_passed>
    <lint_passed>true|false</lint_passed>
    <build_passed>true|false</build_passed>
    <all_checks>true|false</all_checks>
    <confidence>0.0-1.0</confidence>
</verification_result>
```
**Rules:**
- Run ALL tests
- Check lint
- Verify build
- If ANY fail → REJECT patch

### Layer 5: SUBMISSION AGENT
**Task:** Create PR
**Tools:** git, GitHub API
**Output:**
```xml
<submission_result>
    <pr_url></pr_url>
    <pr_number></pr_number>
    <status>created|failed</status>
    <confidence>1.0</confidence>
</submission_result>
```
**Rules:**
- Fork repo
- Push branch
- Create PR with evidence
- Link to issue

## PIPELINE FLOW

```
Discovery Agent
    ↓ (if score >= 15)
Analysis Agent
    ↓ (if solvable=true)
Coding Agent
    ↓ (if confidence > 0.7)
Verification Agent
    ↓ (if all_checks=true)
Submission Agent
    ↓
SUCCESS
```

## RETRY LOGIC
- Max retries: 2
- Retry only on verification failure
- NO retry on discovery/analysis

## STATE MEMORY
Track in JSON:
```json
{
  "visited_repos": [],
  "attempted_issues": [],
  "failed_issues": [],
  "successful_prs": [],
  "iteration": 1
}
```

## DETERMINISTIC TOOLS FIRST
LLM NEVER does:
- ❌ Calculate scores (use formula)
- ❌ Parse JSON (use jq)
- ❌ Run tests (use exec)
- ❌ Count lines (use wc)

LLM ONLY does:
- ✅ Reasoning
- ✅ Classification
- ✅ Text transformation

## CONSTRAINT RULES
1. If information missing → output "UNKNOWN"
2. Never fabricate data
3. Only use retrieved sources
4. Always provide evidence
5. Confidence score required
6. Structured output required

## VALIDATION SCHEMA
Every output validated:
- XML structure valid
- All required fields present
- Confidence in range 0.0-1.0
- URLs are valid
- Evidence provided

## TASK DECOMPOSITION
NEVER do:
- "Fix all bugs in repo"
- "Refactor entire codebase"

ALWAYS do:
- "Fix typo in file X line Y"
- "Add missing import in file Z"
- "Fix lint error in function A"

## REPORTING FORMAT
```xml
<iteration_report>
    <iteration>1</iteration>
    <issues_scanned>50</issues_scanned>
    <high_score_issues>10</high_score_issues>
    <attempted>3</attempted>
    <verified>2</verified>
    <prs_created>1</prs_created>
    <success_rate>0.33</success_rate>
    <confidence>0.85</confidence>
</iteration_report>
```

## IDENTITY
Name: Kahfie
Email: kahfie@gmail.com
GitHub: zamadye
