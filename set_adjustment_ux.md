# Set adjustment UX — editing weight/reps across all sets

Deep dive on a real friction point: a coach bumps the weight, and adjusting a 4-set
exercise means editing the same number in four places.

## Where this actually lives

The screen in question is the **Exercise editor**
([exercise_editor_screen.dart](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart)),
reached from the workout-day editor — not the day editor itself. Sets are rendered by
[planned_set_row.dart](mobile/lib/modules/program_management/widgets/planned_set_row.dart),
one row per set:

```
[≡]  [ Weight (kg) ]  [ Reps (or range) ]  [🗑]
[≡]  [ Weight (kg) ]  [ Reps (or range) ]  [🗑]
[≡]  [ Weight (kg) ]  [ Reps (or range) ]  [🗑]
[≡]  [ Weight (kg) ]  [ Reps (or range) ]  [🗑]
                [ + Add set ]
```

Every field is fully independent. There is no notion of "the exercise's weight" — only
four sets that each happen to hold the same number.

## What actually happened (the reported workaround)

> deleted 3 sets, increased weight on the remaining one, then duplicated it 3 times

This is revealing: the user reverse-engineered a "duplicate" path that the UI never
advertised. It works because **Add set copies the last set's values** —
[`_onPlannedSetAdded`](mobile/lib/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart#L180)
reuses `current.draft.sets.last.values`. So the latent mental model "set the canonical
set once, then fan it out" already exists in the code; it's just not exposed as an action.

## Root cause

The editor optimizes for the **rare** case (pyramids, ramping, drop sets — every set
different) and pays for it in the **common** case (straight sets — `4×5 @ 100 kg`, all
identical). Most structured strength work is straight sets, and a coach's "add 2.5 kg"
applies to *all* working sets at once. The UI has no concept of "these sets move
together," so a single intent ("heavier") becomes N identical manual edits.

Two facts make this cheap to fix well:

1. **No data-model change is needed.** Each `WorkoutSet` stores its own `plannedValues`
   ([program_editor_draft.dart](mobile/lib/modules/program_management/models/program_editor_draft.dart));
   "uniform across sets" is purely a *presentation/affordance* concern that fans out to
   per-set values on edit. The bloc already maps over every set on each change.
2. **This is not a sweaty-hands surface.** Program editing lives outside the gym, so the
   normal 48 dp (`AppSpacing.touchMin`) floor applies — we have room for extra controls
   without violating the in-session ergonomics rules.

## On the proposed solution (multi-cursor: one tap edits all, double-tap isolates)

The instinct is correct — **the common case deserves a single edit point** — but the
specific mechanism has problems on mobile:

- **It's an invisible mode.** Nothing on screen says "editing this field changes all
  four." A user returning weeks later has no way to know, and can't tell *which* scope
  they're in. Mode errors (edit one when you meant all, or vice versa) are silent and
  costly.
- **Single-tap vs. double-tap to switch scope fights the platform.** On a `TextField`,
  double-tap already means "select word," and a tap places the caret. Overloading those
  gestures to mean "scope = all / scope = one" is fragile and collides with native text
  selection. There's no hover or right-click on a phone to lean on.
- **Mixed values are ambiguous.** If the sets already differ (a pyramid), what does the
  shared field display and what does typing into it do? Blank it all? Overwrite with one
  value? No good answer.

The fixable kernel: keep "one place to edit weight for the whole exercise," but make the
**scope visible and explicit** rather than hidden behind a tap-count gesture. Every option
below does that.

---

## Solution A — Uniform-first, expand to vary *(recommended)*

Treat the exercise's sets as **uniform by default**, and only drop to per-row editing when
they actually differ. This is the model Strong, Hevy, and most lifting trackers use,
because it matches how programs are written.

```
Planned sets

   ┌───────────────┐   Sets
   │   −    4    + │       (count stepper)
   └───────────────┘
   ┌───────────────┐   ┌───────────────┐
   │  −  100  +   │   │  −   5   +   │     Weight (kg)   Reps
   └───────────────┘   └───────────────┘
        4 × 5 @ 100 kg                       ← live summary

   ⌄ Vary by set
```

- One weight control and one reps control drive **all** sets. The coach bump is now a
  single `+2.5`.
- A **sets count** stepper replaces delete-row / add-row churn for the common case
  (this alone kills the delete-3-and-duplicate workaround).
- **"Vary by set"** expands into today's per-row list for pyramids, drop sets, ramps. If
  the loaded exercise already has non-uniform sets, open expanded with a quiet "sets vary"
  note so nothing is hidden.
- Collapsing back to uniform when rows differ should prompt ("This will set every set to
  100 × 5 — continue?") rather than silently flatten.

**Mobile-friendly:** yes — explicit, labeled controls; no hidden gestures; ± steppers are
thumb-friendly and let weight move in plate increments (2.5 kg) without the keyboard.
**Discoverability:** high — the uniform editor *is* the default view.
**Cost:** medium — new "uniform vs. varied" presentation state + detection of whether
current sets are uniform; the broadcast edit itself is a one-line `map` over all sets.

## Solution B — Bulk-adjust bar *(strong complement, or lighter standalone)*

Keep the per-row list, add a small toolbar above it that acts on **every** set at once:

```
Adjust all:  [ −2.5 ] [ +2.5 kg ]   [ Set all to… ]   [ −1 ] [ +1 rep ]
─────────────────────────────────────────────────────────
[≡]  [ 100 ]  [ 5 ]  [🗑]
[≡]  [ 100 ]  [ 5 ]  [🗑]
 …
```

- **Relative** bumps (`+2.5 kg`, `+1 rep`) map directly onto the actual trigger:
  progressive overload is almost always "add a bit to what's there," and it works even
  when sets differ (a ramped 80/90/100 stays ramped, just shifted up).
- **"Set all to…"** covers the absolute case (flatten everything to one value).
- Visible, labeled, no mode to get lost in.

**Mobile-friendly:** yes. **Discoverability:** high (persistent labeled bar).
**Cost:** low — add `AllSetsWeightAdjusted(delta)` / `AllSetsRepsAdjusted` /
`AllSetsWeightSet(value)` events; each is a `map` over `draft.sets`. Controllers already
re-sync from `weightInput` via `didUpdateWidget`, so the rows update live.

> A + B together is the sweet spot: A makes the *common* state cheap to express; B makes
> *adjusting* an existing state (uniform or varied) a single tap. B is also the smallest
> shippable win on its own.

## Solution C — Fill-down (spreadsheet pattern)

Per-field affordance: edit the first set's weight, then "apply to all" — via a small
fill-down icon next to the field, or a long-press context action ("Apply **100** to all
sets").

```
[≡]  [ 100 ⤓ ]  [ 5 ⤓ ]  [🗑]      ⤓ = fill this value down to all sets
```

**Mobile-friendly:** moderate — long-press is a real mobile idiom but semi-hidden; an
inline icon is more discoverable but adds visual noise to every row.
**Discoverability:** low–medium. **Cost:** low. Smallest change to today's layout, but it
keeps the per-set list as the primary frame, so it improves the workaround without fixing
the underlying "rare case is the default" mismatch.

## Solution D — Explicit "link sets" toggle (the proposal, de-risked)

Rescue the multi-cursor idea by replacing the hidden tap-count with a **visible switch**:

```
[ 🔗 Sets move together ]  ← toggle, ON by default for uniform sets

(ON)   one linked Weight/Reps editor drives all sets
(OFF)  the current independent per-row list
```

This is essentially Solution A reframed as a toggle instead of an expander. The toggle
makes scope explicit (solving the proposal's core flaw), but a binary "linked/unlinked"
is a blunter model than A's "uniform value + optional per-set override," and the meaning
of toggling **off** (do per-row values inherit the linked value? reset?) needs defining.
Listed mainly to show the path from the original idea to A.

---

## Recommendation

Ship **A + B**:

- **A (uniform-first with "vary by set")** removes the structural mismatch — straight
  sets, the overwhelmingly common case, become a single weight + single reps + a count.
  The delete-3-then-duplicate dance disappears.
- **B (relative ± "adjust all" bar)** makes the actual trigger — *"coach added 2.5 kg"* —
  one tap, and it behaves correctly even for intentionally varied sets.

Both keep full per-set control for pyramids/drop sets, need **no schema or domain change**
(pure presentation + a couple of fan-out bloc events over the existing `sets` list), and
respect the editor's 48 dp (non-sweaty-hands) target budget. Avoid the original
single-/double-tap mechanism: the goal it's reaching for is right, but the scope must be
**shown**, not inferred from how many times you tapped a text field.

### Implementation footnotes

- Fan-out edit is trivial: the weight/reps handlers in
  [exercise_editor_bloc.dart](mobile/lib/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart)
  already `map` over `draft.sets`; an "all" variant just drops the `if (s.draftId != …)`
  guard.
- Detecting "is uniform" = compare `values` across `draft.sets` (respecting rep *ranges*,
  e.g. `6-8`, and time-based duration + optional weight).
- "Add set copies last set" is already the behavior — keep it; under A it becomes
  "increment count, inherit the uniform value."
- Per-exercise `measurementType` means all sets share a shape (rep / time / bodyweight),
  so a single linked editor never has to reconcile mixed types.
- Validation (`ExerciseDraftValidation.compute`) is already per-set and is unaffected by
  how the values were entered.

### Adjacent idea (out of scope here, worth a note)

The deepest fix to the coach scenario is to never open the exercise editor at all: a
**"progress this exercise" inline action** on the workout-day editor (`+2.5 kg to all
sets`) would turn a multi-screen edit into one tap from the day view. Bigger change;
flagged for later, not part of this proposal.
