# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-slug]`
**Created**: [DATE]
**Status**: Draft
**Input**: User description: "$ARGUMENTS"

## Execution Flow (spec authoring)
```
1. Parse the user description. If empty → ERROR "No feature description provided".
2. Extract key concepts: actors, actions, data, constraints.
3. For any unclear aspect, add a [NEEDS CLARIFICATION: specific question] marker.
4. Fill User Scenarios & Testing. If no clear user flow → ERROR "Cannot determine user journey".
5. Generate Functional Requirements — each MUST be testable.
6. Identify Key Entities (if the feature involves data).
7. Run the Review & Acceptance Checklist.
8. Return: SUCCESS (spec ready for planning) or WARN (has [NEEDS CLARIFICATION]).
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY.
- ❌ No HOW to build it (no tech stack, APIs, code structure). That belongs in the plan.
- 👥 Written for product stakeholders, not implementers.
- 🔒 Honor the constitution: on-device privacy, no network, accessible & consistent UI.

*Mark every assumption with `[NEEDS CLARIFICATION: ...]` rather than guessing.*

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
[Describe the main journey in plain language.]

### Acceptance Scenarios
1. **Given** [initial state], **When** [action], **Then** [expected outcome].
2. **Given** [initial state], **When** [action], **Then** [expected outcome].

### Edge Cases
- What happens when [boundary condition]?
- How does the system handle [error / denied permission / malformed input]?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: The app MUST [specific, testable capability].
- **FR-002**: The app MUST [specific, testable capability].
- **FR-003**: Users MUST be able to [key interaction].

*Example of an under-specified requirement to flag:*
- **FR-00X**: The app MUST notify the user [NEEDS CLARIFICATION: how far before expiry, and via what channel?].

### Non-Functional Requirements *(include when relevant)*
- **Privacy**: [data handled entirely on-device? file protection? no network?]
- **Accessibility**: [identifiers, Dynamic Type, VoiceOver expectations]
- **Performance**: [e.g. no main-thread blocking on launch]

### Key Entities *(include if the feature involves data)*
- **[Entity]**: [what it represents, key attributes, relationships — no schema/storage detail].

## Review & Acceptance Checklist
*GATE: automated checks during spec authoring.*

### Content Quality
- [ ] No implementation details (languages, frameworks, APIs)
- [ ] Focused on user value and business needs
- [ ] Written for non-technical stakeholders
- [ ] All mandatory sections completed

### Requirement Completeness
- [ ] No `[NEEDS CLARIFICATION]` markers remain
- [ ] Requirements are testable and unambiguous
- [ ] Success criteria are measurable
- [ ] Scope is clearly bounded
- [ ] Assumptions are stated

## Execution Status
- [ ] User description parsed
- [ ] Key concepts extracted
- [ ] Ambiguities marked
- [ ] User scenarios defined
- [ ] Requirements generated
- [ ] Entities identified
- [ ] Review checklist passed
