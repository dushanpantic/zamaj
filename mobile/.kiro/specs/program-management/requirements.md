# Requirements Document

## Introduction

The **program-management** feature is the first UI layer built on top of the
already-completed `core-domain-and-persistence` foundation. It lets a user
author, view, edit, and delete **programs** (training blocks composed of
reusable workout-day templates) on an offline-first Flutter device.

The feature covers:

- A program list screen that shows every locally-stored program.
- A program-editor flow for creating and editing a program, its workout days,
  its exercise groups, its exercises, its planned sets, and its per-exercise
  planned rest.
- A **text-plan paste-and-parse** flow as the optimized primary authoring
  path: the user pastes a coach-provided plan text, the app parses it into
  an editable structured preview, the user touches it up, and the app saves
  it as a complete program aggregate in a single transaction.
- Exercise authoring with **extensible** measurement-type selection
  (rep-based and time-based for MVP; architecture must accommodate future
  types).
- Optional exercise metadata (free-form notes and an external video URL that
  opens in the device's default browser or YouTube app and is never embedded
  inline).
- **Extensible** exercise group authoring (single-exercise and superset for
  MVP; architecture must accommodate future kinds such as dropset, pyramid,
  reverse pyramid, circuit, and timed-work without rewriting persisted data).
- Program CRUD that respects **historical immutability**: editing a program
  must never retroactively alter the snapshotted planned values stored inside
  previously-started sessions.

The feature explicitly does NOT deliver:

- Workout-day picker, session execution, focus mode, rest timer, or export
  (those are separate specs).
- Import sources other than pasted text (no spreadsheet import, no document
  import, no photo-to-text).
- Cloud sync, accounts, or sharing.
- Session-side editing of programs; this spec is exclusively about the
  **planned / template** side.

## Glossary

- **Program_Management_Module**: The Flutter feature module that owns every
  screen, BLoC, widget, and service described by this spec. Lives under
  `lib/modules/program_management/` following the conventions in `init.md`.
- **Program_List_Screen**: The top-level screen listing every locally-stored
  Program in reverse-chronological order of last update.
- **Program_Editor_Screen**: The screen for creating a new Program or editing
  an existing one, including editing its name, its ordered list of workout
  days, and navigating into individual workout-day edit flows.
- **Workout_Day_Editor_Screen**: The screen for editing a single workout day's
  name, its ordered list of exercise groups, and navigating into individual
  exercise edit flows.
- **Exercise_Editor_Screen**: The screen (or inline section) for authoring a
  single Exercise's name, its `Measurement_Type`, its `Exercise_Metadata`, its
  planned sets, and its `Planned_Rest_Seconds`.
- **Plan_Text**: A `String` that the user pastes from an external source
  (typically a coach's message), intended to be parsed into a structured
  plan.
- **Text_Plan_Parser**: The pure Dart component that transforms a `Plan_Text`
  into a structured `Plan_Draft` or a typed `Plan_Parse_Error`.
- **Plan_Pretty_Printer**: The pure Dart component that transforms a
  `Plan_Draft` into its canonical textual form.
- **Plan_Draft**: An in-memory intermediate representation produced by the
  `Text_Plan_Parser`. Consists of one program name, an ordered list of
  draft workout days, draft exercise groups, draft exercises, and draft sets.
  Drafts carry no persisted ids; ids are assigned on save.
- **Plan_Preview_Screen**: The screen that displays a `Plan_Draft` in an
  editable, structured form before the user commits to saving it as a
  persisted Program.
- **Plan_Parse_Error**: A typed error returned by the `Text_Plan_Parser` when
  the input cannot be interpreted as a plan. Carries a one-based line number,
  a one-based column number, a machine-readable error code, and a
  human-readable message.
- **Plan_Parse_Warning**: A typed non-fatal diagnostic surfaced by the
  `Text_Plan_Parser` when a line is interpreted through a recovery path
  (for example, an unrecognized trailing token on an otherwise-valid set
  line). Carries the same line/column/code/message shape as
  `Plan_Parse_Error` but does not prevent producing a `Plan_Draft`.
- **Planned_Rest_Seconds**: A non-negative integer number of seconds of
  planned rest authored per Exercise. Absent (null) when the user did not
  specify a rest. Out of scope: per-set rest overrides.
- **Program_Repository**: The abstract contract exposed by the
  `core-domain-and-persistence` spec at
  `lib/modules/domain/repositories/program_repository.dart`. This spec's
  persistence goes exclusively through this contract.
- **Session_Repository**: The abstract contract exposed by the
  `core-domain-and-persistence` spec at
  `lib/modules/domain/repositories/session_repository.dart`. This spec only
  reads from it (to know whether a program has dependent sessions) and never
  writes to it.
- **Template_Tables**: The persisted rows that back `Program`, `WorkoutDay`,
  `ExerciseGroup`, `Exercise`, and `WorkoutSet` aggregates in the database
  (as defined by the `core-domain-and-persistence` spec).
- **Session_Snapshot**: The immutable canonical-JSON copy of a `WorkoutDay`
  tree captured on the `Session` row at session-start time, as defined by the
  `core-domain-and-persistence` spec.
- **Measurement_Type**: The sealed extensible domain type from the
  `core-domain-and-persistence` spec whose MVP variants are `RepBased` and
  `TimeBased`.
- **Exercise_Group_Kind**: The sealed extensible domain type from the
  `core-domain-and-persistence` spec whose MVP variants are `Single` and
  `Superset`.
- **Video_URL**: A nullable string field on `Exercise_Metadata` that holds an
  external link to a video demonstration.
- **External_Link_Launcher**: The platform component used to open a
  `Video_URL` in the device's default browser or video app. Responsible for
  leaving the Zamaj app but never embedding a player inline.
- **Offline_Device**: A device with no network connectivity at the moment of
  operation.

## Requirements

### Requirement 1: Program List Screen

**User Story:** As an athlete with several training blocks saved on my
device, I want a single home screen that lists every program, so that I can
pick one to edit, delete, or use later.

#### Acceptance Criteria

1. WHEN the Program_List_Screen is opened, THE Program_Management_Module SHALL load every Program persisted on the device through the Program_Repository and display each Program's name, created_at date, and updated_at date.
2. THE Program_List_Screen SHALL order the displayed Programs primarily by their persisted `updated_at` timestamp in descending order, and SHALL break ties between Programs with identical `updated_at` timestamps by ordering their names in ascending case-insensitive order.
3. WHILE no Programs exist on the device, THE Program_List_Screen SHALL display a zero-state placeholder that offers two entry points: create a new Program from an empty form, and create a new Program by pasting a Plan_Text.
4. WHEN the user taps a listed Program, THE Program_Management_Module SHALL navigate to the Program_Editor_Screen for that Program.
5. WHEN the user invokes the "delete" action on a listed Program, THE Program_List_Screen SHALL display a confirmation prompt with explicit confirm and cancel controls and SHALL retain the Program in the displayed list until the user selects one of those controls.
6. WHEN the user selects the confirm control on the delete confirmation prompt, THE Program_Management_Module SHALL delete the Program through the Program_Repository.
7. WHEN a Program is successfully deleted through the Program_List_Screen, THE Program_Management_Module SHALL remove the Program from the displayed list without requiring a manual refresh.
8. THE Program_List_Screen SHALL display an "Import from text" affordance that navigates to a Plan_Text paste surface.
9. IF the Program_Repository fails to return the list of Programs when the Program_List_Screen is opened, THEN THE Program_List_Screen SHALL display an error indicator and a retry affordance that re-invokes the load when activated.
10. IF the Program_Repository returns an error while deleting a Program, THEN THE Program_Management_Module SHALL retain that Program in the displayed list and display an error indicator that names the failed action.

### Requirement 2: Create Program From Empty Form

**User Story:** As a user without a pre-formatted plan, I want to build a
program from scratch by typing its name and adding workout days manually,
so that I can author simple plans without needing a coach's text message.

#### Acceptance Criteria

1. WHEN the user invokes "create Program from empty form", THE Program_Management_Module SHALL open the Program_Editor_Screen in create mode with an empty Program draft whose name is an empty string and whose workout-day list is empty.
2. WHILE the Program draft name, after trimming leading and trailing whitespace, has a length less than 1 character or greater than 120 characters, THE Program_Editor_Screen SHALL disable the "save" action.
3. WHEN the user taps "save" while the Program draft name, after trimming leading and trailing whitespace, has a length between 1 and 120 characters inclusive, THE Program_Management_Module SHALL invoke `ProgramRepository.createProgram(name: ...)` exactly once with the trimmed name.
4. WHEN `ProgramRepository.createProgram` returns successfully and all workout-day writes for the draft have been persisted, THE Program_Management_Module SHALL navigate to the persisted Program's Program_Editor_Screen.
5. IF the repository returns a typed DomainError during Program creation, THEN THE Program_Management_Module SHALL display an error message that identifies the offending field by its user-visible label, SHALL leave the Program draft on screen with all user-entered values preserved, and SHALL re-enable the "save" action so the user can retry.
6. WHILE the Program_Editor_Screen is in create mode, THE Program_Editor_Screen SHALL allow the user to add, rename, reorder, and delete workout days on the in-memory draft without invoking the Program_Repository, and SHALL persist all workout days as part of a single save operation initiated by one "save" gesture by the user.

### Requirement 3: Edit Existing Program

**User Story:** As a coach-athlete user whose block is mid-cycle, I want to
adjust an existing program — rename it, add a workout day, reorder its
exercises — so that I can keep the template accurate as the block evolves,
without touching sessions I have already completed.

#### Acceptance Criteria

1. WHEN the Program_Editor_Screen is opened in edit mode for a given Program id that resolves to an existing Program through the Program_Repository, THE Program_Management_Module SHALL load the Program and its workout-day aggregates through the Program_Repository and display the Program's name together with the ordered list of its workout days, each showing the workout day name and its ordered list of exercises.
2. IF the Program id passed to the Program_Editor_Screen does not resolve to an existing Program through the Program_Repository, THEN THE Program_Management_Module SHALL display an error indicating that the Program was not found and SHALL NOT enter edit mode.
3. THE Program_Editor_Screen SHALL allow the user to rename the Program, add a workout day, delete a workout day, rename a workout day, and reorder workout days.
4. WHEN the user submits a new Program name whose trimmed length is between 1 and 100 characters inclusive, THE Program_Management_Module SHALL persist the trimmed name through `ProgramRepository.updateProgram(program)`.
5. IF the user submits a new Program name whose trimmed length is 0 or greater than 100 characters, THEN THE Program_Management_Module SHALL reject the rename, display a validation error indicating the allowed length range, and preserve the Program's previous name.
6. WHEN the user reorders workout days, THE Program_Management_Module SHALL persist the new order through `ProgramRepository.reorderWorkoutDays(programId, orderedWorkoutDayIds)` such that the position index of each workout day in the persisted list equals its position in the user-arranged list.
7. WHEN the user requests deletion of a workout day, THE Program_Management_Module SHALL display a confirmation prompt identifying the workout day and SHALL NOT delete it until the user explicitly confirms.
8. WHEN the user confirms deletion of a workout day, THE Program_Management_Module SHALL delete that workout day through `ProgramRepository.deleteWorkoutDay` and remove it from the displayed list.
9. IF the user cancels or dismisses the deletion confirmation prompt, THEN THE Program_Management_Module SHALL close the prompt and preserve the workout day and the Program's current state unchanged.
10. WHEN the user taps a listed workout day, THE Program_Management_Module SHALL navigate to the Workout_Day_Editor_Screen for that workout day.

### Requirement 4: Workout Day Editor

**User Story:** As a user editing a Program, I want to manage each workout
day — its exercises, its supersets, and the order of exercises — so that the
template matches my coach's intended session structure.

#### Acceptance Criteria

1. WHEN the Workout_Day_Editor_Screen is opened for a given workout-day id that exists in the Program_Repository, THE Program_Management_Module SHALL display the workout day's name, its ordered exercise groups, and each exercise within each group in the ordered position persisted by the Program_Repository.
2. THE Workout_Day_Editor_Screen SHALL allow the user to rename the workout day to any name whose trimmed length is between 1 and 100 characters inclusive, add an exercise group, delete an exercise group, reorder exercise groups, add an exercise within a group, delete an exercise within a group, reorder exercises within a group, convert a Single group to a Superset group by adding an exercise to it, and convert a Superset group back to a Single group by removing all but one of its exercises; newly added exercise groups SHALL be appended at the end of the workout day's group list and newly added exercises SHALL be appended at the end of their containing group's exercise list.
3. WHEN the user changes the Exercise_Group_Kind of a group through the actions in Acceptance Criterion 2, THE Program_Management_Module SHALL persist the resulting group through `ProgramRepository.updateExerciseGroup(group)` only when the group contains exactly one exercise for the `Single` kind or two or more exercises for the `Superset` kind, as required by Requirement 3 of `core-domain-and-persistence`.
4. IF the user attempts to save an exercise group that would violate the cardinality invariant defined by Requirement 3 of `core-domain-and-persistence`, THEN THE Program_Management_Module SHALL NOT invoke the `ProgramRepository.updateExerciseGroup` call, SHALL retain the user's unsaved edits, and SHALL display an inline error message naming the violated invariant.
5. WHERE the Program_Management_Module architecture represents `Exercise_Group_Kind`, the architecture SHALL route every group-kind decision through the sealed `ExerciseGroupKind` type defined by the `core-domain-and-persistence` spec so that adding a future kind (for example dropset, pyramid, circuit, timed-work) requires only adding UI surfaces for the new variant, not rewriting persisted data or existing variant handling.
6. WHEN the user taps an exercise inside a workout day, THE Program_Management_Module SHALL navigate to the Exercise_Editor_Screen keyed by the tapped exercise's id.
7. IF the Workout_Day_Editor_Screen is opened with a workout-day id that does not resolve to an existing workout day through the Program_Repository, THEN THE Program_Management_Module SHALL display an error indicating the workout day was not found, SHALL NOT render the editor form, and SHALL provide a back control that returns to the previous screen.
8. IF a `ProgramRepository` save call invoked from the Workout_Day_Editor_Screen returns any error other than a cardinality-invariant `ValidationError`, THEN THE Program_Management_Module SHALL retain the user's unsaved edits on screen, display an error indicator that names the failed action, and re-enable the "save" action so the user can retry.

### Requirement 5: Exercise Authoring and Measurement Type

**User Story:** As a user authoring an exercise, I want to pick how it's
measured — rep-based for lifts, time-based for holds — and enter the right
fields for that choice, so that planned values always match how the movement
will actually be measured.

#### Acceptance Criteria

1. WHEN the Exercise_Editor_Screen is opened for an Exercise, THE Program_Management_Module SHALL display input fields for the Exercise's name, its Measurement_Type, its Exercise_Metadata, its planned Planned_Rest_Seconds, and its ordered planned sets.
2. THE Exercise_Editor_Screen SHALL expose a Measurement_Type selector whose options correspond exactly to the current set of `MeasurementType` variants declared by the `core-domain-and-persistence` spec (initially `RepBased` and `TimeBased`).
3. WHEN the user selects the `RepBased` Measurement_Type, THE Program_Management_Module SHALL display per-set inputs for a planned weight in kilograms between 0 and 1000 inclusive at a resolution of 0.5 kilograms, and for a planned repetition count that is a whole number between 0 and 999 inclusive.
4. WHEN the user selects the `TimeBased` Measurement_Type, THE Program_Management_Module SHALL display a per-set input for a planned duration that is a whole number of seconds between 0 and 3600 inclusive.
5. WHEN the user selects a new Measurement_Type for an Exercise that differs from its current Measurement_Type, THE Program_Management_Module SHALL display a confirmation prompt that names the effect on the Exercise's planned sets and SHALL NOT apply the change until the user explicitly confirms.
6. WHEN the user confirms a Measurement_Type change, THE Program_Management_Module SHALL reinitialize every planned set on the Exercise to a zero-valued variant that matches the new Measurement_Type so that the consistency invariant defined by Requirement 13.3 of `core-domain-and-persistence` holds on save.
7. IF the user cancels or dismisses the Measurement_Type change confirmation prompt, THEN THE Program_Management_Module SHALL retain the Exercise's previous Measurement_Type and its planned sets unchanged.
8. THE Exercise_Editor_Screen SHALL allow the user to add a planned set up to a total of 20 planned sets per Exercise, delete a planned set down to a minimum of 1 planned set per Exercise, reorder planned sets, and edit every field of every planned set.
9. WHERE the Program_Management_Module architecture represents `Measurement_Type`, the architecture SHALL route every measurement-type decision through the sealed `MeasurementType` type defined by the `core-domain-and-persistence` spec so that adding a future variant (for example distance-based, RPE-anchored) requires only adding UI surfaces for the new variant, not rewriting persisted data or existing variant handling.
10. IF the user attempts to save an Exercise whose name has a trimmed length of 0 or greater than 80 characters or whose Planned_Rest_Seconds is outside the range 0 to 3600 inclusive, THEN THE Program_Management_Module SHALL block the save by not invoking the Program_Repository, retain all user-entered values on screen, and display a message naming the offending field and its allowed range.
11. IF the user attempts to save an Exercise whose planned-set values do not match the Exercise's Measurement_Type, THEN THE Program_Management_Module SHALL block the save by not invoking the Program_Repository, retain all user-entered values on screen, and display a message naming the offending set's position and the required variant.

### Requirement 6: Planned Rest Per Exercise

**User Story:** As a user authoring an Exercise, I want to record the
planned rest between sets, so that the focus-mode rest timer can use it
later and so that my coach's intent (for example "2m rest") survives into
the session snapshot.

#### Acceptance Criteria

1. THE Exercise_Editor_Screen SHALL expose a single optional Planned_Rest_Seconds input that applies to every planned set of the Exercise.
2. WHEN the user enters a Planned_Rest_Seconds value that is a whole number between 0 and 3600 inclusive, THE Program_Management_Module SHALL accept that value as the Exercise's Planned_Rest_Seconds.
3. IF the user enters a Planned_Rest_Seconds value that is not a whole number between 0 and 3600 inclusive, THEN THE Program_Management_Module SHALL reject the value, display a message stating the allowed range, and preserve the Exercise's previously persisted Planned_Rest_Seconds value.
4. IF the user leaves the Planned_Rest_Seconds input empty or whitespace-only, THEN THE Program_Management_Module SHALL persist the Exercise's Planned_Rest_Seconds as absent (null) rather than as zero.
5. THE Program_Management_Module SHALL persist Planned_Rest_Seconds in a nullable field that is serialized as part of the Exercise aggregate so that the value is captured inside every Session_Snapshot taken from a WorkoutDay containing that Exercise.
6. IF the domain layer exposed by `core-domain-and-persistence` does not yet carry a Planned_Rest_Seconds field on `Exercise`, THEN the design phase of this spec SHALL extend the Exercise domain model, its Drift mapping, and its canonical-JSON serialization to add this field with a schema migration from the current schema version, such that every pre-existing Exercise row has Planned_Rest_Seconds set to absent (null) after migration and every other field on pre-existing Exercise rows is preserved unchanged.

### Requirement 7: Exercise Metadata — Notes and External Video Links

**User Story:** As a user, I want to attach a free-form note and a video
link to an exercise, so that I can remember technique cues and so that I
can open a demo video without cluttering the in-session UI.

#### Acceptance Criteria

1. THE Exercise_Editor_Screen SHALL expose an optional free-form notes input accepting 0 to 2000 characters and an optional Video_URL input accepting 0 to 2048 characters, both mapping directly to the `ExerciseMetadata.notes` and `ExerciseMetadata.videoUrl` fields defined by the `core-domain-and-persistence` spec.
2. WHEN the user saves an Exercise whose Video_URL input parses as an absolute URL with an http or https scheme, THE Program_Management_Module SHALL persist the value as authored in `ExerciseMetadata.videoUrl`.
3. WHEN the user saves an Exercise whose Video_URL or notes input is empty or contains only whitespace, THE Program_Management_Module SHALL persist the corresponding `ExerciseMetadata` field as null.
4. IF the user attempts to save an Exercise whose Video_URL input is non-empty and does not parse as an absolute URL with an http or https scheme, THEN THE Program_Management_Module SHALL reject the save, preserve any previously persisted `ExerciseMetadata` values, and display a validation message identifying the Video_URL field as invalid.
5. WHEN the user activates the Video_URL control on an Exercise whose `ExerciseMetadata.videoUrl` is non-null, THE Program_Management_Module SHALL open the stored URL through the External_Link_Launcher.
6. IF the External_Link_Launcher reports a failure to open a Video_URL, THEN THE Program_Management_Module SHALL display a message indicating the link could not be opened and SHALL leave `ExerciseMetadata.videoUrl` unchanged.
7. THE Program_Management_Module SHALL NOT embed video content inline inside any screen.
8. WHERE a Video_URL's host is one of youtube.com, youtu.be, or m.youtube.com, THE External_Link_Launcher SHALL prefer the YouTube app when it is installed on the device and SHALL fall back to the default browser when it is not installed.

### Requirement 8: Text-Plan Parser — Optimized Primary Workflow

**User Story:** As a user receiving a plan from my coach, I want to paste
that text into Zamaj and have the app infer the program structure for me,
so that I can start lifting today without re-typing every set.

#### Acceptance Criteria

1. WHEN the user activates the "Import from text" affordance, THE Program_Management_Module SHALL display a Plan_Text paste surface with a multi-line text input that accepts between 0 and 100,000 UTF-16 code units and a "parse" action that is enabled only WHILE the current Plan_Text length is between 1 and 100,000 UTF-16 code units inclusive.
2. WHEN the user submits a Plan_Text whose length is between 1 and 100,000 UTF-16 code units inclusive, THE Text_Plan_Parser SHALL complete within 500 milliseconds of wall-clock time and SHALL return either a Plan_Draft or a typed Plan_Parse_Error.
3. IF the submitted Plan_Text contains zero UTF-16 code units or contains only horizontal-whitespace and line-ending characters, THEN THE Text_Plan_Parser SHALL return a Plan_Parse_Error with error code `empty_input`, one-based line number 1 and one-based column number 1, and SHALL NOT produce a Plan_Draft.
4. THE Text_Plan_Parser SHALL classify each non-blank line by inspecting its first non-whitespace token using the following ordered rules, where the first matching rule wins:
   - a workout-day header line, WHERE the first non-whitespace token matches the case-folded keyword "day" optionally followed by an identifier or ordinal;
   - a superset marker line, WHERE the first non-whitespace token matches any of the case-folded keywords "superset", "super-set", or "ss" (for example "Superset", "SUPERSET", "super-set", and "ss" SHALL all be recognized);
   - a planned-set line, WHERE the first non-whitespace token matches the sets-by-reps pattern `<positive-integer><multiplication-sign><positive-integer>` and the multiplication sign is one of the ASCII letters `x` or `X` or the Unicode character `×` (U+00D7);
   - an exercise name line, WHERE none of the preceding rules match and the line appears after a workout-day header or a superset marker in the current document scope;
   - an allowed blank separator line, WHERE the line contains only horizontal-whitespace characters between its start and its line terminator.
5. THE Text_Plan_Parser SHALL treat the following surface variations as equivalent and SHALL NOT change classification based on them:
   - any run of one or more horizontal-whitespace characters (ASCII space U+0020 or ASCII horizontal tab U+0009) appearing between tokens on the same line;
   - any run of zero or more horizontal-whitespace characters appearing as leading or trailing whitespace on a line, including a bare trailing line that contains only horizontal-whitespace before its terminator;
   - letter case in keywords, unit suffixes, and multiplication signs (for example "4x8", "4X8", and "4×8" SHALL be equivalent; "KG", "kg", and "Kg" SHALL be equivalent; "Superset", "SUPERSET", and "super-set" SHALL be equivalent);
   - line-ending style, where any of `\n`, `\r\n`, or a bare trailing line without a terminator SHALL be accepted.
6. WHEN the Text_Plan_Parser identifies a planned-set line with an explicit trailing rest token of the form `<integer><unit-suffix>` where the integer is between 1 and 3600 inclusive and the unit-suffix is one of the case-folded single characters `s` or `m`, THE Text_Plan_Parser SHALL attach the parsed rest to the owning Exercise's Planned_Rest_Seconds, converting a value with unit-suffix `m` to seconds by multiplying the integer by 60.
7. IF a trailing rest token uses an integer outside the range 1 to 3600 inclusive, or uses a unit-suffix other than the case-folded `s` or `m`, THEN THE Text_Plan_Parser SHALL treat the token as an unrecognized trailing token on an otherwise-valid set line per criterion 9.
8. IF the Text_Plan_Parser encounters a line that matches none of the classification rules in criterion 4, THEN THE Text_Plan_Parser SHALL return a Plan_Parse_Error whose one-based line number and one-based column number point at the first offending character, whose error code identifies the failed production, and SHALL NOT produce a Plan_Draft for this invocation.
9. IF the Text_Plan_Parser encounters an unrecognized trailing token on an otherwise-valid planned-set line, THEN THE Text_Plan_Parser SHALL attach a Plan_Parse_Warning to the owning Exercise within the Plan_Draft, where the warning contains the offending token's text, its one-based line number, its one-based column number pointing at the first character of the offending token, and an error code identifying the failed production, and SHALL still produce a Plan_Draft.
10. THE Text_Plan_Parser SHALL NOT perform any network I/O and SHALL complete every invocation using only local resources, so that it works on an Offline_Device.
11. THE Text_Plan_Parser SHALL expose a pure Dart API that accepts a `String` and returns a `Plan_Draft` or a `Plan_Parse_Error` without touching the database, without touching the filesystem, and without requiring a Flutter widget context.

### Requirement 9: Plan Preview and Save

**User Story:** As a user who just parsed a coach's text, I want to review
and touch up what the parser produced before committing, so that small
parse mistakes or missing details don't get locked into my program.

#### Acceptance Criteria

1. WHEN the Text_Plan_Parser produces a Plan_Draft, THE Program_Management_Module SHALL navigate to the Plan_Preview_Screen and render every field of the Plan_Draft in the same structured form as the Program_Editor_Screen (program name, workout days, exercise groups with kind, exercises with Measurement_Type, every planned set, Planned_Rest_Seconds per exercise, and Exercise_Metadata per exercise).
2. WHILE the Plan_Preview_Screen is displayed, THE Program_Management_Module SHALL allow the user to rename the program, rename any workout day, add/delete/reorder workout days, add/delete/reorder exercise groups, change an exercise group's kind subject to Requirement 4 Acceptance Criterion 4, add/delete/reorder exercises, change an exercise's Measurement_Type subject to Requirement 5 Acceptance Criterion 6, edit every field of every planned set, edit Planned_Rest_Seconds per exercise, and edit Exercise_Metadata per exercise.
3. WHEN the user taps save on the Plan_Preview_Screen and every Plan_Draft value passes domain validation, THE Program_Management_Module SHALL persist the Plan_Draft as a new Program aggregate through the Program_Repository as a single atomic operation and THEN navigate to the Program_List_Screen with the newly saved Program visible.
4. WHEN the user taps discard on the Plan_Preview_Screen, THE Program_Management_Module SHALL return to the Program_List_Screen without persisting any part of the Plan_Draft.
5. IF any Plan_Draft value fails domain validation at save time (for example a zero-exercise superset after edits, or a rep-based set on a time-based exercise), THEN THE Program_Management_Module SHALL block the save, display a message naming the offending element and the violated invariant, and leave the Plan_Preview_Screen on screen with the user's edits preserved for correction.
6. WHILE the Plan_Preview_Screen is displayed, THE Program_Management_Module SHALL render every Plan_Parse_Warning emitted by the Text_Plan_Parser inline next to the affected element so that the user can see what the parser was uncertain about.
7. IF persistence of the Plan_Draft through the Program_Repository fails for any reason, THEN THE Program_Management_Module SHALL roll back any partial writes so that no Program aggregate fragment remains on the device, display a message indicating that the save failed, and leave the Plan_Preview_Screen on screen with the user's edits preserved.

### Requirement 10: Text-Plan Parser Correctness Properties

**User Story:** As a developer relying on the parser for the primary import
path, I want the parser's behavior pinned down by explicit, testable
correctness properties, so that future edits to the grammar cannot
silently break existing coach-paste text.

#### Acceptance Criteria

1. FOR ALL Plan_Text inputs P for which the Text_Plan_Parser returns a Plan_Draft D (with or without warnings), THE Plan_Pretty_Printer SHALL format D into a Plan_Text P', and re-invoking the Text_Plan_Parser on P' SHALL return a Plan_Draft D' for which D and D' compare equal under the freezed-generated `operator ==` on Plan_Draft, where the comparison excludes any attached Plan_Parse_Warning list.
2. FOR ALL Plan_Text inputs P, any two invocations of the Text_Plan_Parser on P within the same process SHALL return results that compare equal under the freezed-generated `operator ==` on their return type, including element-wise and order-preserving equality of the attached Plan_Parse_Warning list in the accepted case and including equality of the Plan_Parse_Error in the rejected case.
3. FOR ALL Plan_Text inputs P for which the Text_Plan_Parser returns a Plan_Draft D, and for any Plan_Text P' obtained from P by applying zero or more of the following transformations (individually or in combination), re-invoking the Text_Plan_Parser on P' SHALL return a Plan_Draft D' for which D and D' compare equal under the freezed-generated `operator ==` on Plan_Draft: (a) collapsing, expanding, or rearranging any run of horizontal-whitespace characters (ASCII space U+0020 or ASCII tab U+0009) between tokens on the same line; (b) adding or removing any leading or trailing horizontal-whitespace characters on any line; (c) replacing any line-ending among `\n`, `\r\n`, or `\r`, including mixed line-endings; (d) changing the case of any token covered by Requirement 8 Acceptance Criterion 5 (keywords, unit suffixes, multiplication signs, and superset markers).
4. FOR ALL Plan_Draft values D that the Text_Plan_Parser produced and the Program_Management_Module successfully persisted as a Program aggregate PG through the Program_Repository, loading PG back through the Program_Repository and converting it to a Plan_Draft D_loaded by discarding every persistence-assigned identifier, feeding D_loaded through the Plan_Pretty_Printer to obtain a Plan_Text P'', and re-invoking the Text_Plan_Parser on P'' SHALL return a Plan_Draft D' for which D and D' compare equal under the freezed-generated `operator ==` on Plan_Draft.
5. IF a Plan_Text is unparseable, THEN THE Text_Plan_Parser SHALL return exactly one Plan_Parse_Error and no Plan_Draft, and for subsequent invocations on the same Plan_Text within the same process, the returned Plan_Parse_Error SHALL have the same one-based line number, the same one-based column number, and the same error code as the first returned Plan_Parse_Error.

### Requirement 11: Template Integrity Against Active Sessions

**User Story:** As an athlete who already logged sessions against version
N of a Program, I want my coach-initiated edits to the Program to never
change what my historical sessions show, so that my training record stays
honest.

#### Acceptance Criteria

1. WHEN the user creates, updates, or deletes any Program, WorkoutDay, ExerciseGroup, Exercise, or WorkoutSet through the Program_Management_Module, THE Program_Management_Module SHALL perform every create, update, and delete write exclusively through the Program_Repository.
2. THE Program_Management_Module SHALL NOT invoke any Session_Repository create, update, or delete method as part of any program, workout-day, exercise-group, exercise, or set edit action.
3. WHEN an edit E applied through the Program_Management_Module completes successfully against the Program_Repository for any Session S that was persisted before E, reading S through the Session_Repository after E SHALL return a Session whose `snapshot.canonicalJson` bytes are byte-for-byte identical to what the same read returned immediately after S was persisted.
4. WHEN an edit E applied through the Program_Management_Module completes successfully against the Program_Repository for any Session S that was persisted before E, reading S through the Session_Repository after E SHALL return a Session whose `snapshot.sha256Hash` is identical to what the same read returned immediately after S was persisted.
5. IF the user attempts to delete a Program that has one or more dependent persisted Sessions, THEN THE Program_Management_Module SHALL display a confirmation prompt that states the target Program's name and the exact integer count of dependent Sessions.
6. THE Program_Management_Module SHALL NOT invoke `ProgramRepository.deleteProgram` for a Program with dependent persisted Sessions until the user explicitly confirms the prompt described in Acceptance Criterion 5.
7. WHEN the Program_Management_Module deletes a workout day that has one or more dependent persisted Sessions, THE Program_Management_Module SHALL invoke only the soft-reference deletion path defined by Requirement 6 of `core-domain-and-persistence` and SHALL NOT invoke any hard-delete or cascade-delete call that removes session-referenced rows.
8. WHEN the Program_Management_Module deletes a workout day that has one or more dependent persisted Sessions, reading every dependent Session through the Session_Repository after the delete SHALL return a Session whose `snapshot.canonicalJson` bytes and `snapshot.sha256Hash` are byte-for-byte identical to what the same read returned immediately after the Session was persisted.

### Requirement 12: CRUD via Repository Contracts Only

**User Story:** As a developer, I want the program-management UI to depend
only on domain-typed repository contracts, so that the UI layer stays
swappable and Drift leakage never reaches BLoCs or widgets.

#### Acceptance Criteria

1. THE Program_Management_Module, defined as all non-generated Dart source files under `lib/modules/program_management/` (excluding `*.freezed.dart` and `*.g.dart` siblings), SHALL depend only on `lib/core/` and on the `lib/modules/domain/` barrel export `package:zamaj/modules/domain/domain.dart` for its data-access needs, and SHALL NOT import any file under `lib/modules/persistence/`.
2. THE Program_Management_Module SHALL NOT import `package:drift/drift.dart`, `package:drift/native.dart`, `package:drift_flutter/drift_flutter.dart`, `package:sqlite3/sqlite3.dart`, `package:sqlite3/common.dart`, any Drift-generated type, or any `*.g.dart` file located under `lib/modules/persistence/`, from any BLoC, screen, widget, or service.
3. THE Program_Management_Module SHALL receive `ProgramRepository` and `SessionRepository` instances through constructor parameters whose declared types resolve to the abstract contracts defined under `lib/modules/domain/repositories/`, and SHALL NOT resolve these dependencies via service locators, global singletons, or setter injection.
4. THE Program_Management_Module SHALL NOT reference, construct, or open any of the symbols `AppDatabase`, `NativeDatabase`, `driftDatabase`, or `GeneratedDatabase`, and SHALL NOT invoke any constructor or factory that returns a subtype of `GeneratedDatabase`.
5. IF the module import check (`tool/check_offline_imports.sh` extended to cover `lib/modules/program_management/`) detects any import or symbol reference forbidden by criteria 1, 2, or 4, THEN THE check SHALL exit with a non-zero status code and SHALL emit, for each violation, a message identifying the offending file path, the line number, and the forbidden import or symbol.

### Requirement 13: Offline-First Isolation

**User Story:** As a user in a basement gym, I want the whole program-
management flow — list, create, edit, paste-parse, preview, save, delete —
to work with no network connectivity, so that I can author and adjust plans
regardless of signal.

#### Acceptance Criteria

1. THE Program_Management_Module SHALL NOT import any package that performs network I/O, including `package:http`, `package:dio`, `package:web_socket_channel`, `package:grpc`, and `package:socket_io_client`, and SHALL NOT reference any of the `dart:io` classes `HttpClient`, `HttpServer`, `Socket`, `ServerSocket`, `RawSocket`, `SecureSocket`, or `SecureServerSocket`.
2. THE Text_Plan_Parser SHALL NOT import any package that performs network I/O and SHALL NOT reference any of the `dart:io` classes `HttpClient`, `HttpServer`, `Socket`, `ServerSocket`, `RawSocket`, `SecureSocket`, or `SecureServerSocket`.
3. THE Plan_Pretty_Printer SHALL NOT import any package that performs network I/O and SHALL NOT reference any of the `dart:io` classes `HttpClient`, `HttpServer`, `Socket`, `ServerSocket`, `RawSocket`, `SecureSocket`, or `SecureServerSocket`.
4. WHEN any Program_Management_Module screen is opened on an Offline_Device, every in-screen action defined by Requirements 1 through 11 SHALL complete without issuing any outbound network request from the Program_Management_Module itself; the Program_Management_Module's offline obligation SHALL terminate at the External_Link_Launcher hand-off call described in Requirement 7 Acceptance Criterion 5, independent of whether the launcher subsequently requires network connectivity to render the opened URL.

### Requirement 14: Module Structure and Conventions

**User Story:** As a developer, I want the program-management module to
follow the project's existing conventions, so that later feature modules
can be built the same way and the codebase stays consistent.

#### Acceptance Criteria

1. THE Program_Management_Module SHALL live under `lib/modules/program_management/` and SHALL expose a single barrel file `lib/modules/program_management/program_management.dart` that re-exports every type intended for consumption outside the module.
2. THE Program_Management_Module SHALL organize its source under `bloc/`, `screens/`, `widgets/`, `services/`, and `models/` subdirectories per the conventions in `init.md`.
3. THE Program_Management_Module SHALL use the `flutter_bloc` pattern with sealed `Event` and `State` class families whose concrete subclasses extend `Equatable`, per the conventions in `init.md`.
4. THE Program_Management_Module SHALL use single quotes for Dart string literals, SHALL apply the `const` keyword to every constructor invocation flagged by the `prefer_const_constructors` lint in the project's `analysis_options.yaml`, SHALL use `package:zamaj/...` imports for every cross-directory import within `lib/`, and SHALL NOT use relative `lib/` imports.
5. THE Program_Management_Module SHALL NOT contain any `print` call in its source files; any diagnostic output SHALL go through `log` from `dart:developer` or through a BLoC observer consistent with `init.md`.
6. WHEN `flutter analyze` is run against the project with the existing `analysis_options.yaml`, the Program_Management_Module source files SHALL produce zero errors, zero warnings, and zero lint violations.

### Requirement 15: Error Surfaces and Validation

**User Story:** As a user, when I enter something the app can't accept, I
want a clear message that tells me where the problem is and what the rule
is, so that I can fix it without trial and error.

#### Acceptance Criteria

1. WHEN any Program_Repository call returns a typed `DomainError` (`ValidationError`, `OrderingError`, `NotFoundError`, `VersionMismatchError`, `DeserializationError`), THE Program_Management_Module SHALL surface a non-empty message that contains the error's `invariant` or `field` descriptor verbatim and, WHERE the error carries an `entityId`, contains that `entityId` verbatim.
2. IF the Text_Plan_Parser returns a Plan_Parse_Error, THEN the Plan_Text paste surface SHALL display the error's line and column as 1-based integers, highlight the offending line, and retain the user's Plan_Text in the editor without truncation or modification so that the user can correct it and retry.
3. IF the user edits a planned-set weight field on a `RepBased` exercise and the entered value is negative or is not a multiple of 0.5 kilograms, THEN the Program_Management_Module SHALL reject the value before calling the Program_Repository, retain the user's entered text in the field without modification, and display a message that identifies the weight field and states the constraint "weight must be zero or positive and a multiple of 0.5 kilograms".
4. IF the user edits a planned-set duration field on a `TimeBased` exercise and the entered value is negative or is not a whole number of seconds, THEN the Program_Management_Module SHALL reject the value before calling the Program_Repository, retain the user's entered text in the field without modification, and display a message that identifies the duration field and states the constraint "duration must be a non-negative whole number of seconds".
5. IF the user edits a planned-set repetition field on a `RepBased` exercise and the entered value is negative or is not a whole number, THEN the Program_Management_Module SHALL reject the value before calling the Program_Repository, retain the user's entered text in the field without modification, and display a message that identifies the repetitions field and states the constraint "repetitions must be a non-negative whole number".
6. IF the user edits the Planned_Rest_Seconds field on an Exercise and the entered value is negative or is not a whole number, THEN the Program_Management_Module SHALL reject the value before calling the Program_Repository, retain the user's entered text in the field without modification, and display a message that identifies the Planned_Rest_Seconds field and states the constraint "rest seconds must be a non-negative whole number".
