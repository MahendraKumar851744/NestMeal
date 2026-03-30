# NestMeal Test Issues Report
**Generated:** 2026-03-29 23:25:36
**Total Issues Found:** 2

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 2 |

---

## T-001: Server version exposed in headers
**Severity:** LOW | **Category:** SECURITY
**Endpoint:** `GET /meals/`

Server header reveals: WSGIServer/0.2 CPython/3.11.3

**Expected:** Generic or no Server header
**Actual:** Server: WSGIServer/0.2 CPython/3.11.3

---

## T-002: 404 returns HTML instead of JSON
**Severity:** LOW | **Category:** API
**Endpoint:** `GET /nonexistent/`

API returns HTML error page for 404 instead of JSON response

**Expected:** JSON error response
**Actual:** HTML error page

---
