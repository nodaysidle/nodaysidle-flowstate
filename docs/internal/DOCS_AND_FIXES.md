# FlowState Docs Audit + Next Fixes

## What I cleaned up

### Updated
- `README.md`
  - Removed the misleading "ML-Powered Break Predictions" claim.
  - Reworded the product flow so it matches the current heuristic/adaptive behavior.

### Deleted
- `Sources/codemap.md`
- `Sources/FlowState/codemap.md`
- `Sources/FlowState/Views/codemap.md`
- `Sources/FlowState/Services/codemap.md`
- `Sources/FlowState/Models/codemap.md`

These files were empty architectural templates with no real value.

## What I think should be fixed next

- Nothing urgent in docs right now.
- If we keep going, the next useful step is code-level cleanup, testing, or tightening the heuristics.

## Already fixed in this pass

- README architecture section now matches the current source layout.
- README settings language now matches the actual tabs and defaults more closely.
- README no longer implies the break logic is trained ML.
- Root `codemap.md` now reflects the actual project structure and current architecture.

## My suggested first code fix

Pick one code-level improvement next:
- test coverage for `FocusScoreEngine` / `BreakPredictor`
- trim any stale code comments
- verify the accessibility flow still behaves cleanly on launch
