# Naming Conventions

## The Golden Rule

```hcl
service_name = "payment-api"
```

## Auto-Generated Names

| Resource | Pattern | Example |
|----------|---------|---------|
| Octopus Project | {service_name} | payment-api |
| ECS Service | {service_name}-{env} | payment-api-dev |
| ALB | {service_name}-alb-{env} | payment-api-alb-dev |
| Cluster | {service_name}-cluster-{env} | payment-api-cluster-dev |
| Blue TG | {service_name}-blue-{long_env} | payment-api-blue-development |
| Green TG | {service_name}-green-{long_env} | payment-api-green-development |

## Best Practices

Keep service_name under 15 characters:
- ✅ payment-api (11 chars)
- ✅ user-service (12 chars)
- ❌ payment-processing-api (22 chars - too long)

See full artifact for complete naming reference.
