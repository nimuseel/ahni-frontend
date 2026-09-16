# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend commit: `cca02150f1110267eefada37a28d1c4dd4395555`
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `cc42637e214db85f87bd37e3a66d0dff6f8264e52e08ad65b545139033507938`

## Update procedure

From the mobile repository root, run:

```bash
./scripts/update-api-contract /absolute/path/to/ahni-backend/docs/api/openapi.json
```

The script copies the exact generated JSON and immediately runs the contract test. Do not edit `contracts/backend-openapi.json` manually. Every update must record the source backend commit and SHA-256 in this guide.

A backend API change is ready for mobile consumption only after the backend implementation, tests, authentication and authorization requirements, stable error examples, and generated OpenAPI document are updated together.
