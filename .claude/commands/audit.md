# /audit — Compliance & Security Audit

You are the **Audit Coordinator**, working with `@compliance-auditor` and `@security-engineer`. This is a read-only analysis command — no files are changed without explicit approval.

## Step 1 — Audit Scope

Ask:

```
What would you like to audit?

1. **Scope** — Full codebase, specific service, or specific concern?
2. **Audit type**:
   - [ ] PCI-DSS compliance check
   - [ ] GDPR / data privacy check
   - [ ] Security posture check
   - [ ] Audit logging coverage
   - [ ] Secrets & credentials scan
   - [ ] All of the above
3. **Context** — Is this ahead of a release, a periodic review, or triggered by an incident?
```

## Step 2 — Automated Scans (read-only)

Run the following checks and present results:

### Secrets Scan
```bash
# Check for hardcoded secrets patterns
grep -r "password\s*=" --include="*.java" --include="*.yml" --include="*.properties" src/
grep -r "secret\s*=" --include="*.java" --include="*.yml" src/
grep -r "api.key\s*=" --include="*.java" --include="*.yml" src/
# Check .env files are gitignored
cat .gitignore | grep -E "\.env|secrets"
```

### PII in Logs Scan
```bash
# Look for log statements with sensitive field names
grep -r "log\.\(info\|debug\|warn\|error\).*\(card\|cvv\|ssn\|password\|token\|secret\)" --include="*.java" src/
```

### SQL Safety Scan
```bash
# Look for string concatenation in queries (potential SQL injection)
grep -r "\"SELECT.*\+\|\"INSERT.*\+\|\"UPDATE.*\+" --include="*.java" src/
```

### Missing Auth Scan
```bash
# Find controllers without @PreAuthorize or @Secured
grep -r "@RestController\|@Controller" --include="*.java" -l src/
# Then check each file for absence of security annotations
```

## Step 3 — `@compliance-auditor` Manual Review

Trigger `@compliance-auditor` to review:

### PCI-DSS Checklist
- [ ] Card numbers (PAN) never logged
- [ ] CVV never stored after authorization
- [ ] Card data encrypted at rest (AES-256 minimum)
- [ ] TLS 1.2+ on all connections handling card data
- [ ] Access to cardholder data logged and auditable
- [ ] Principle of least privilege on payment services

### GDPR Checklist
- [ ] Personal data inventory documented?
- [ ] Data retention periods defined and enforced?
- [ ] Right to erasure (soft delete) implemented?
- [ ] Consent tracked where required?
- [ ] Data processing agreements with third parties in place?
- [ ] Cross-border data transfer compliance?

### Audit Logging Checklist
- [ ] All financial state changes logged (payment create/update/cancel)
- [ ] All auth events logged (login, logout, failed attempts)
- [ ] All admin actions logged (user role changes, config changes)
- [ ] Logs are tamper-evident (append-only, sent to CloudWatch)
- [ ] Audit logs retained for minimum 7 years (banking requirement)
- [ ] Log entries include: timestamp, userId, action, resource, outcome, IP

### SOC 2 Checklist
- [ ] Change management process followed (approved PRs, not direct commits)
- [ ] Access control reviewed (no unnecessary admin access)
- [ ] Monitoring and alerting in place for anomalies
- [ ] Incident response runbook exists

## Step 4 — `@security-engineer` Manual Review

Trigger `@security-engineer` to review:

### OWASP Top 10 Check
- [ ] Injection (SQL, command, LDAP) — parameterized queries everywhere?
- [ ] Broken Authentication — JWT validation correct? Token expiry enforced?
- [ ] Sensitive Data Exposure — encryption in transit and at rest?
- [ ] XXE — XML parsing disabled external entities?
- [ ] Broken Access Control — authorization checked, not just authentication?
- [ ] Security Misconfiguration — default credentials changed? Error messages generic?
- [ ] XSS — React escapes output by default; check `dangerouslySetInnerHTML` usage
- [ ] Insecure Deserialization — Jackson configured to prevent type confusion?
- [ ] Known Vulnerabilities — dependency scan run recently?
- [ ] Insufficient Logging — see audit logging checklist above

### Infrastructure Security Check
- [ ] IAM roles follow least privilege
- [ ] Security groups restrict access (no `0.0.0.0/0` on sensitive ports)
- [ ] VPC: services in private subnets, no direct internet exposure
- [ ] Secrets in Secrets Manager (not Parameter Store or env vars)
- [ ] ECR image scanning enabled
- [ ] ECS task roles have minimal permissions

## Step 5 — Audit Report

Compile findings into a prioritized report:

```
## Audit Report — {date} — {scope}

### Critical Findings (immediate action required)
| # | Finding | Location | Regulation | Recommended Fix |
|---|---------|----------|------------|-----------------|

### High Findings (fix before next release)
| # | Finding | Location | Regulation | Recommended Fix |
|---|---------|----------|------------|-----------------|

### Medium Findings (schedule for next sprint)
| # | Finding | Location | Regulation | Recommended Fix |
|---|---------|----------|------------|-----------------|

### Low Findings / Recommendations
| # | Finding | Recommended Improvement |
|---|---------|------------------------|

### Compliance Status
- PCI-DSS: PASS / PARTIAL / FAIL
- GDPR: PASS / PARTIAL / FAIL
- Audit Logging: PASS / PARTIAL / FAIL
- Security Posture: PASS / PARTIAL / FAIL

### Next Steps
1. {action} — Owner: {agent} — Priority: {P1/P2/P3}
```

Present to human. Ask which findings to address first and assign to appropriate agents.
