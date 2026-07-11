# PKO R01 schema-aware DB promotion policy

- MB_ID: `CR-DB-0129G-SCHEMA-AWARE-PROMOTE-FCMC-STAGING-TO-CANONICAL-DB`
- Canonical tables must be populated only after SQLite schema introspection.
- Constraint values must be selected from real schema checks or defaults.
- `main.xlsx` is not a runtime source for this promotion runner.
- `R01_E.01_FORMAT_CONTROL.xlsx` is not used as data source.