# Module spec — {{p{N}-module-slug}}

_Phase: {{N}} · Owner: {{@handle}} · Estimate: {{3}} d · Status: Not started_

## Purpose

{{One paragraph: what this module does, why it exists, where it sits in the
architecture (which container/component from SYSTEM_DESIGN).}}

## Responsibilities

- {{owns the question + answer lifecycle}}
- {{enforces group-membership rules for posting}}

## Not responsible for

- {{authentication (auth module)}}
- {{vote tallying (voting module)}}
- {{sending notifications (notifications module) — only emits a domain event}}

## Public contract

The stable promise other modules depend on. Changing this is a breaking change.

```ts
// services/qa/index.ts
export function createQuestion(
  groupId: string,
  authorId: string,
  input: { title: string; body: string },
): Promise<Question>;            // throws NotMemberError, ValidationError

export function listQuestions(
  groupId: string,
  page: { cursor?: string; limit?: number },
): Promise<{ items: Question[]; nextCursor: string | null }>;
```

HTTP surface (if any):

| Method / path | Auth | Request | Response | Errors |
|---|---|---|---|---|
| POST /api/v1/groups/:id/questions | member | `{title, body}` | 201 `Question` | 403, 422 |
| GET  /api/v1/groups/:id/questions | member | `?cursor&limit` | 200 `{items,nextCursor}` | 403 |

Events emitted: {{`question.created`, `answer.created` — payload `{id, groupId, authorId}`}}

## Internal design

- **Files:** {{`services/qa/`, `repos/questionRepo.ts`, `routes/questions.ts`}}
- **Key functions / classes:** {{...}}
- **State / data owned:** tables `question`, `answer` (source of truth).
  Denormalised: `question.answer_count`.
- **Algorithms / rules:** {{title 3–200 chars; body ≤ 10k; soft-delete keeps
  thread integrity; list ordered by created_at desc, cursor = base64(created_at,id)}}

## Dependencies

| Depends on | Via | For |
|---|---|---|
| `auth` | `getSession()` | current user |
| `groups` | `isMember(groupId, userId)` | authz |
| lib `zod` | — | input validation |
| DB | repo layer | persistence |

## Build steps

1. [ ] Migration: create `question`, `answer` tables + indexes (SYSTEM_DESIGN §7).
2. [ ] `questionRepo` / `answerRepo`: insert, getById, listByGroup(cursor), softDelete. Unit-test the cursor logic.
3. [ ] `qa` service: `createQuestion`, `listQuestions`, `addAnswer` — validation, membership check, transaction, emit event.
4. [ ] HTTP routes: parse, auth guard, map errors to problem+json.
5. [ ] Wire event emission to the in-process bus (consumed later by notifications).
6. [ ] Seed script entries for local dev.
7. [ ] Update `MODULES.md` row + `ARCHITECTURE.md` if flow changed.

## Test plan

**Unit**
- [ ] title too short / too long → `ValidationError`
- [ ] non-member → `NotMemberError`, nothing written
- [ ] `listQuestions` returns stable pages when rows are inserted between calls
- [ ] `nextCursor` is null on the last page
- [ ] soft-deleted question hidden from list but answers preserved

**Integration**
- [ ] POST then GET round-trips through the real DB
- [ ] event `question.created` observed on the bus

**Manual verification**
- [ ] create a question in the UI as a member; see it in the list
- [ ] attempt as a non-member → 403 shown gracefully

## Acceptance criteria (all must be true = done)

- [ ] Public contract implemented exactly as written above, with types.
- [ ] All unit + integration tests pass; coverage of this module ≥ {{85}}%.
- [ ] p95 of `listQuestions` < {{150}} ms with 10k questions in the group (local bench).
- [ ] Errors surface as problem+json with correct status codes.
- [ ] `MODULES.md` and (if changed) `ARCHITECTURE.md` updated.
- [ ] No secrets, no debug logging, no TODOs without a linked issue.

## Biggest unknown

{{Whether the in-process event bus is enough or a durable queue is needed for
notifications — revisit in Phase 4.}}
