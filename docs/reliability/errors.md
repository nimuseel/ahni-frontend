# Error and State Guide

Every remote or permission-dependent screen defines these states:

```text
initial → loading → success
                  ↘ empty
                  ↘ recoverable error → retry
                  ↘ permission required → settings or fallback
```

Do not show raw exceptions to students. Preserve a diagnostic cause for logs while presenting a safe, actionable message. Cached data must be labeled when it may be stale.
