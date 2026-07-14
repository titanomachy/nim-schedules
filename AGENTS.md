# Agent Instructions

Scope: this file applies to the whole repository.

## Project Overview

Metronome is a small, dependency-light Nim scheduler library for interval,
cron, systemd-style calendar timer, and one-shot jobs. It supports async jobs
on the event loop and thread-backed jobs, plus throttling, lifecycle controls,
error reporting, and next-run inspection.

The package is configured by `metronome.nimble` and requires Nim `>= 2.2.10`.
Nim and Nimble are installed in the standard `~/.nimble/bin` location. Use the
normal `nim` and `nimble` commands; if a minimal non-interactive shell does not
include that directory in `PATH`, add it instead of installing another
toolchain. Keep the library dependency-free unless a change clearly justifies
a new dependency.

## Public Modules And Architecture

- `src/metronome.nim` is the default public import and generated top-level
  documentation. It exports the scheduler and cron APIs.
- `src/metronome/scheduler.nim` contains beaters, throttling, scheduler state,
  lifecycle and introspection APIs, wait/dispatch behavior, and the
  `scheduler`/`metronome` macros.
- `src/metronome/cron/` contains cron fields, parsing, and next-run evaluation.
- `src/metronome/timezones.nim` is an optional public module for exact named
  IANA timezones. Importing only `metronome` must not embed its catalog.
- `src/metronome/timezones/` contains the pinned catalog, TZif reader, and
  recurring POSIX timezone-rule implementation. The embedded database is
  currently IANA release `2026c`.
- `src/metronome/timers.nim` is an optional public module for systemd-style
  `OnCalendar` schedules and timer beaters. It imports the timezone feature;
  importing only `metronome` must not include timer parsing or IANA data.
- `src/metronome/timers/` separates calendar data types, parsing, and
  hierarchical next-run evaluation. Keep these responsibilities separated
  rather than growing one all-purpose calendar module.

The scheduler core supports custom schedules through `NextRunProc`. The timer
DSL hook lives in the core macro, but resolves the optional timer API from the
caller; do not make the core import `metronome/timers`.

## Development Commands

- Run the complete test suite with `nimble test`.
- Run coverage instrumentation with `nimble coverage`. This requires `lcov`,
  `genhtml`, and a coverage-capable C compiler toolchain.
- Generate local API documentation with `nimble docs`.
- Compile examples with threads enabled, for example
  `nim c --threads:on -r examples/example_basic_intervals.nim`.
- Exercise the timer example with
  `nim c --threads:on -r examples/example_timer_scheduler.nim`.

`tests/config.nims` already adds `../src` to the module path and enables
threads. Do not duplicate those flags in individual test commands without a
specific reason.

## Repository Layout

- `tests/test_beater.nim`: beater timing, custom schedules, throttling,
  lifecycle, failures, and dispatch regression tests.
- `tests/test_scheduler.nim`: scheduler APIs and sync/async macro expansion.
- `tests/test_cron.nim`: cron parsing and next-run behavior.
- `tests/test_timezones.nim`: catalog, TZif/POSIX rules, DST behavior, and
  timezone-aware cron tests.
- `tests/test_timers.nim`: calendar parsing/evaluation, timezone behavior,
  precision, and timer DSL/direct API tests.
- `tests/fixtures/systemd_calendar.txt`: captured reference results from
  `systemd-analyze calendar`; tests and CI must not require systemd itself.
- `examples/`: runnable examples aligned with the README, including named
  timezone cron and systemd-style timer examples.
- `tools/update_timezones.nim`: maintainer-only deterministic updater for the
  embedded IANA catalog.
- `code_coverage.sh` and `scripts/coverage_badge.sh`: canonical local/CI
  coverage report and badge generation.
- `CHANGELOG.md`: release notes; add user-visible behavior under `Unreleased`.
- `PLANS/`: ignored local planning material. Do not add plan files to the
  repository unless explicitly requested to change that policy.

## Coding And API Guidelines

- Follow the existing Nim style: two-space indentation, exported symbols
  marked with `*`, and `##` documentation comments for public APIs.
- Preserve the public API unless the task explicitly calls for a breaking
  change. Update README examples, NimDoc, tests, and `CHANGELOG.md` when public
  behavior changes.
- Keep sync and async scheduler paths in parity. Jobs without `async=true` run
  in worker threads and must continue to obey Nim thread/GC-safety rules.
- Keep scheduler-owned timing state inside the scheduler lifecycle. Avoid new
  global state, detached background threads, or runtime downloads.
- Keep the optional-module boundary intact: core and cron use only the standard
  library; named timezone data appears only through `metronome/timezones` or
  `metronome/timers`.
- Do not change cron evaluation as a side effect of timer work. Cron uses OR
  semantics when both day-of-month and day-of-week are restricted; calendar
  timers use systemd-compatible AND semantics.
- Timer calendar targets retain microseconds, but dispatch is best-effort and
  normally millisecond-scale. Positive sub-millisecond deadlines must never be
  intentionally launched early.
- Preserve the documented DST rules: timer occurrences in spring-forward gaps
  are skipped; ambiguous timer occurrences use the earlier instant. Direct
  timezone conversion has its separately documented normalization behavior.

## Testing Guidelines

- Prefer deterministic `DateTime` and next-run tests over wall-clock sleeps.
  Keep unavoidable sleep-based lifecycle tests short and tolerant of system
  load.
- Add focused regression coverage in the matching test module for scheduler,
  cron, timer, or timezone changes.
- Test exact boundaries and rollover behavior. Timer/timezone changes should
  cover DST gaps and overlaps, winter/summer offsets, and recurring rules after
  2037 when relevant.
- Keep timer parser and evaluator tests independent of the host timezone,
  operating-system zoneinfo, network access, and a systemd installation.
- At minimum run `nimble test` before claiming a code change is ready. Also run
  `nimble coverage` when changing tests or coverage behavior, `nimble docs` when
  changing public documentation, and the relevant example when changing its
  code or documented output.

## Timezone Catalog Maintenance

Applications never need timezone maintenance tools. Updating the embedded
catalog is a maintainer action requiring `curl`, `sha256sum`, `tar`, `make`,
and a C99 compiler:

```bash
nim r tools/update_timezones.nim -- 2026c
nim r tools/update_timezones.nim -- 2026c --check
```

When moving to another IANA release, update the pinned version and both tzdata
and tzcode SHA-256 values in the tool, review the generated catalog, run its
`--check` mode, and rerun timezone and timer tests. The updater deliberately
builds the matching pinned `zic` instead of using the host's timezone compiler.

## Generated And Local Artifacts

The following paths are generated or local and must not be committed:

- `docs/`, including generated NimDoc HTML/index files and `coverage.svg`
- `nimcache/`
- `coverage.info`
- `coverage_html/`
- compiled test binaries under `tests/`
- local Nimble files such as `nimble.paths`, `nimble.develop`, and `nimbledeps`
- `PLANS/`, `NOTES.md`, IDE files, and local logs

Do not hand-edit generated documentation or the coverage badge. Regenerate
them with their Nimble tasks. If generated documentation or coverage was
produced while working, mention that validation in the final response.

## CI And Releases

GitHub Actions installs Nim `2.2.10` and pinned `lcov` `2.1`, generates docs,
runs the instrumented tests, and enforces at least 80% line coverage. On pushes
to `master`, CI uploads `docs/` as a GitHub Pages artifact and deploys it with a
separate Pages job. CI must not commit generated documentation or badges back
to `master`.

Pull requests run documentation and coverage validation but do not deploy
Pages. Tags matching `v*` create a GitHub release using `CHANGELOG.md` as the
release body.
