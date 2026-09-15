# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend commit: `ab03e096e3ecf06429a09c6081fd831ba6771792`
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `a2e7449e0a5a2eb5e9fe60a83dc882533c1ae14b0215c2905ced24862defa2bc`

## Update procedure

From the mobile repository root, run:

```bash
./scripts/update-api-contract /absolute/path/to/ahni-backend/docs/api/openapi.json
```

The script copies the exact generated JSON and immediately runs the contract test. Do not edit `contracts/backend-openapi.json` manually. Every update must record the source backend commit and SHA-256 in this guide.

A backend API change is ready for mobile consumption only after the backend implementation, tests, authentication and authorization requirements, stable error examples, and generated OpenAPI document are updated together.
