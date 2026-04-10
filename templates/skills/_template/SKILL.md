---
name: <skill-name>
description: |
  <One-line description including trigger words.
  This is what OpenClaw sees when matching skills.>
user-invocable: true
---

# <Skill Name>

## Role Activation

When this skill loads, IMMEDIATELY:

1. Source credentials: `source ../../secrets/<skill>.env`
2. Verify authentication (test call)
3. Confirm ready to the user

## Credentials & Auth

- **Location:** `secrets/<skill>.env`
- **Required variables:** `API_TOKEN`, `BASE_URL`
- **Required headers:** `Authorization: Bearer ${API_TOKEN}`

```bash
# Load credentials
# NOTE: This relative path assumes the script is at skills/<name>/scripts/<script>.sh
# If you move the script, update the path accordingly.
SECRETS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../secrets/<skill>.env"
if [[ -f "$SECRETS_FILE" ]]; then
  set -a; source "$SECRETS_FILE"; set +a
fi
: "${API_TOKEN:?API_TOKEN not set — create secrets/<skill>.env}"
: "${BASE_URL:?BASE_URL not set — add to secrets/<skill>.env}"
```

## HTTP Method

Use **ALWAYS `curl` via Bash** for all API calls.
Use NEVER Python `urllib`, `requests`, or WebFetch.

## Request Templates

### GET — List items
```bash
curl -sf -X GET "${BASE_URL}/api/items" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json"
```

### POST — Create item
```bash
curl -sf -X POST "${BASE_URL}/api/items" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "example", "value": "test"}'
```

## Error Handling

| HTTP Status | Meaning | Action |
|-------------|---------|--------|
| 200-299 | Success | Parse response, report to user |
| 401 | Unauthorized | Check API_TOKEN in secrets/<skill>.env |
| 403 | Forbidden | Escalate — user may need to adjust permissions |
| 404 | Not found | Verify endpoint URL and resource ID |
| 429 | Rate limited | Wait 30s, retry once, then report to user |
| 500+ | Server error | Report to user, suggest checking service status |

## Common Tasks

| Task | First API Call |
|------|---------------|
| List all items | `GET /api/items` |
| Get single item | `GET /api/items/{id}` |
| Create item | `POST /api/items` |
| Update item | `PUT /api/items/{id}` |
| Delete item | `DELETE /api/items/{id}` |

## Reference Navigation

<!-- If you have large reference docs in references/, map them here. -->
<!-- Example:
### API Docs (references/api-spec.md — 1500 lines)

| Section | Lines | When to load |
|---------|-------|--------------|
| Authentication | 1-50 | First time setup |
| Endpoints overview | 51-200 | General questions |
| Error codes | 800-900 | Troubleshooting |
-->

## Problem -> What to Load

<!-- Map common problems to specific reference sections. -->
<!-- Example:
| Problem | Load |
|---------|------|
| "Can't authenticate" | SKILL.md Credentials section + references/api-spec.md lines 1-50 |
| "Item not found" | SKILL.md Error Handling + references/api-spec.md lines 51-200 |
-->

## Safety Rules

- Never expose credentials in chat messages
- Always validate user input before API calls
- Ask before destructive operations (DELETE, bulk updates)

## Escalation

When to stop and escalate to the user:
- Authentication fails after re-checking credentials
- Unexpected data format from API
- Destructive action requested without explicit confirmation

**Escalation format:**
```
I need your help with [skill-name]:
- What I tried: [action]
- What happened: [result]
- What I need: [specific ask]
```
