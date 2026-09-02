# Reusable prompt blocks for each phase

These are conversation prompts, not skills. Paste/adapt as needed.

## Clarify (act as PM)

> Before writing code, act as a senior product manager. Restate my goal, list
> observable acceptance criteria, list what's explicitly out of scope, and ask
> only the questions whose answers would change the design. Wait for my answers.

## Design (act as architect)

> Act as a senior architect. Propose an approach: data model changes, new
> interfaces, control flow, affected modules. Give one or two alternatives you
> considered and why you rejected them. Call out risks and the rollback story.
> Don't write implementation code yet.

## Break down

> Break this into slices that are each independently mergeable and leave the
> tree green (build + lint + tests). Order riskiest/most foundational first.
> For each slice name the test that proves it.

## Self-review (act as reviewer)

> Review this diff as if I were a stranger submitting it. Check it does exactly
> what the requirements said, hunt edge cases (empty/null/huge/concurrent/
> unauthorized/network failure), verify errors are surfaced not swallowed, and
> confirm the tests fail when the code is broken. Report findings ranked by
> severity.

## Debug (act as debugger)

> Form 2–3 hypotheses for this failure, ranked by likelihood. For the top one,
> state the smallest experiment that would confirm or kill it. Run it. Don't
> change code until a hypothesis is confirmed.
