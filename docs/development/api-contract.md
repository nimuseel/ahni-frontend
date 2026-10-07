# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend source: `feat/yearly-curriculum` commit `40309eacc70679eacf146326f9d62e23dd095eb9`
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `ca9608a745ddbf6f380663b99f63045ec7d660bffaf327c35e5656a14651e2a8`

## Update procedure

From the mobile repository root, run:

```bash
./scripts/update-api-contract /absolute/path/to/ahni-backend/docs/api/openapi.json
```

The script copies the exact generated JSON and immediately runs the contract test. Do not edit `contracts/backend-openapi.json` manually. Every update must record the source backend commit and SHA-256 in this guide.

A backend API change is ready for mobile consumption only after the backend implementation, tests, authentication and authorization requirements, stable error examples, and generated OpenAPI document are updated together.
