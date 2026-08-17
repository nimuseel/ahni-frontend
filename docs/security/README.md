# Security Baseline

- Store tokens only in platform secure storage.
- Never commit API keys, signing credentials, or device tokens.
- Treat OCR files, location, and push tokens as sensitive data.
- Send authenticated requests through one API boundary that handles expiry consistently.
- Do not trust student IDs from navigation arguments when the server can derive identity from the session.
