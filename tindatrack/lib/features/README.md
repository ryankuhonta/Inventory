# Feature Modules

Future features live under `lib/features/{feature}` and own their meaningful
`presentation`, `domain`, and `data` code.

Dependency direction:

```text
presentation/controller
-> domain/use case
-> repository contract
<- data implementation
-> DAO
-> core database
```

Shared, feature-independent infrastructure belongs in `lib/core`. Feature
entities, failures, validators, repositories, and providers remain inside the
feature that owns them. Widgets must not access Drift, DAOs, or database tables
directly. Domain code owns repository contracts; data implementations depend on
and implement those contracts, never the reverse.
