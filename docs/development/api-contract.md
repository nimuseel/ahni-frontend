# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend commit: `9318e1d0f29289a19b13f5b2d32303ba744f5a83`
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `5948ba9e9749834fd8597464afacfe9ec0a886387ffb6059fff54ca145f03992`

## Update procedure

From the mobile repository root, run:

```bash
./scripts/update-api-contract /absolute/path/to/ahni-backend/docs/api/openapi.json
```

The script copies the exact generated JSON and immediately runs the contract test. Do not edit `contracts/backend-openapi.json` manually. Every update must record the source backend commit and SHA-256 in this guide.

A backend API change is ready for mobile consumption only after the backend implementation, tests, authentication and authorization requirements, stable error examples, and generated OpenAPI document are updated together.
