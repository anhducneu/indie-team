# Rules: AWS CDK Infrastructure

**Applies to:** `infrastructure/**/*.ts`, `infrastructure/bin/*.ts`

---

## Stack Organization
```
infrastructure/lib/stacks/
  network-stack.ts   ← VPC, subnets, security groups, NAT
  data-stack.ts      ← RDS, MSK, ElastiCache, S3 buckets
  service-stack.ts   ← ECS services, ALB, task definitions, IAM roles
```

One logical grouping per stack file. Cross-stack references via `stack.exportValue()` / SSM Parameters.

## Secrets Management
- **Never hardcode** secrets, passwords, or API keys in CDK code
- Reference existing Secrets Manager secrets by ARN: `Secret.fromSecretCompleteArn(...)`
- Reference existing Parameter Store values: `StringParameter.fromStringParameterName(...)`
- Never store secrets in CDK context (`cdk.json`) or environment variables in task definitions

## IAM Rules (least privilege enforced)
- No wildcard actions: ~~`iam:*`~~ → use specific actions
- No wildcard resources: ~~`"*"`~~ → scope to specific ARNs or use `arnFormat`
- Every ECS task role gets only the permissions its service needs — no shared roles
- All IAM policy documents must include a comment explaining why the permission is needed

```typescript
// ✅ Correct
taskRole.addToPolicy(new PolicyStatement({
  actions: ['secretsmanager:GetSecretValue'],
  resources: [paymentDbSecret.secretArn],
  // Needed: payment-service reads DB credentials at startup
}));

// ❌ Wrong
taskRole.addManagedPolicy(
  ManagedPolicy.fromAwsManagedPolicyName('AdministratorAccess')
);
```

## Security Groups
- No inbound rule open to `0.0.0.0/0` on any port except ALB port 443
- Service-to-service traffic via security group references (not CIDR ranges)
- Database security groups allow inbound only from ECS service security groups

## Networking
- All services deployed in **private subnets** — no direct internet exposure
- NAT Gateway for egress-only internet access
- VPC endpoints for S3 and Secrets Manager to avoid NAT traffic costs

## Encryption
- RDS: `storageEncrypted: true` — always
- S3: `encryption: BucketEncryption.S3_MANAGED` minimum; `KMS_MANAGED` for sensitive data
- ECS environment variables: never use `environment` for secrets — use `secrets` (Secrets Manager integration)
- MSK: encryption in transit (`clientBrokerEncryption: ClientBrokerEncryption.TLS`) and at rest

## Resource Tagging (required on all resources)
```typescript
Tags.of(this).add('Environment', props.env);
Tags.of(this).add('Service', props.serviceName);
Tags.of(this).add('Owner', 'indie-team');
Tags.of(this).add('ManagedBy', 'cdk');
```

## Before Deploying
Always run `cdk diff` and present output to human before `cdk deploy`.
Flag any resource **deletions** or **replacements** — these require explicit human approval.
