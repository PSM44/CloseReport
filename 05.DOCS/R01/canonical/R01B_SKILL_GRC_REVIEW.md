# R01_B Skill / GRC Learning Review — CR-DB-0148

## Skills / execution learnings
- `openpyxl` fue suficiente para auditoría, trazabilidad y validación estructural sin COM.
- Excel COM solo fue útil cuando hubo que cerrar cached values reales; debe seguir encapsulado y excepcional.
- Higiene documental temprana reduce ruido operativo y simplifica handoff.

## GRC / control learnings
- Mantener `main.xlsx` solo como benchmark/bootstrap histórico evitó dependencia runtime indebida.
- Separar `technical acceptance`, `D1 review`, `admin signoff` y `DB lineage` evitó mezclar gates.
- La política de no borrar evidencia y archivar con manifiesto SHA256 funcionó bien.

## Recomendación
- Convertir este patrón en estándar para futuros reportes R02+.
