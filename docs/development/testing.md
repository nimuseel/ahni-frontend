# Testing Guide

## Layers

- Unit: pure Dart calculations and state transitions under `test/unit/`.
- Widget: screen rendering, semantics, loading/error/empty states, and user gestures.
- Integration: complete app-shell and cross-layer flows under `test/integration/`, runnable without a device in the default harness.

Write a failing unit test before GPA, graduation, timetable, or recommendation behavior. Keep widget tests focused on user-visible outcomes and avoid testing private widget implementation details.

The baseline protects environment parsing with unit tests, the AHNI shell with a widget test, the pinned backend contract with a unit test, and full app-shell composition with a host-independent integration test.

Run each layer with `./scripts/test-unit`, `./scripts/test-widget`, or `./scripts/test-integration`. Real-device journeys require an explicitly provisioned emulator or physical-device CI job and are added with the feature they protect.
