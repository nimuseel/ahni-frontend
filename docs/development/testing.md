# Testing Guide

## Layers

- Unit: pure Dart calculations and state transitions under `test/unit/`.
- Widget: screen rendering, semantics, loading/error/empty states, and user gestures.
- Integration: API and device-service flows on a real or controlled platform target.

Write a failing unit test before GPA, graduation, timetable, or recommendation behavior. Keep widget tests focused on user-visible outcomes and avoid testing private widget implementation details.

Current baseline: `test/widget_test.dart` proves the root app renders AHNI and responds to a gesture.
