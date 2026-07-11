# R01_B DB Lineage Migration Plan — CR-DB-0147

## Razón de no aplicar en 0147
El esquema actual no expone un camino limpio y seguro para registrar la dependencia '. F.BS2.01' sin asumir columnas/constraints fuera de introspección.

## Lineage a registrar
- Source depth: '. F.BS2.01'!G35:R52
- Internal aggregation: '. F.BS2.01'!G54:R54 = SUM(G35:G52):SUM(R35:R52)
- Target range: F.D.KUM.01!R26:AC26
- Critical trace: F.D.KUM.01!S26 -> '. F.BS2.01'!H54 -> SUM(H35:H52)

## Tablas propuestas
- `report_dependency_cell_rule` para fórmulas/targets si se agregan columnas seguras de marker/source.
- `report_dependency_staging_value` para source depth values si se confirma soporte idempotente.

## Requisitos para aplicar
- marker column explícita o notes column gobernada.
- unique/idempotent key por `sheet_name + cell_address + marker`.
- default/nullable safe para columnas no pobladas.
- rollback validado por marker `CR_DB_0147`.

## Relación futura con generator
El generator debe producir '. F.BS2.01' internamente desde DB/rules para que main.xlsx siga siendo solo benchmark/bootstrap histórico.
