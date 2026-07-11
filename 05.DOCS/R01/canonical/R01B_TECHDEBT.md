# R01_B Technical Debt — CR-DB-0148

## Deuda activa
- El esquema DB no ofrece una ruta limpia, idempotente y trazable para registrar el lineage corregido sin asumir columnas/constraints.
- La continuidad histórica del repo todavía refleja workstreams antiguos de input-template y no solo el cierre R01_B.
- El working tree contiene mucho material no consolidado/no committed fuera del alcance de esta sesión.

## Deuda no bloqueante
- Visual refinement pendiente.
- Ausencia de readiness formal unificado para CloseReport.
- Necesidad de canonizar una política de nombres cortos a escala de proyecto, no solo R01.

## Deuda estratégica
- Llevar el lineage hoy resuelto en workbook/evidencia hacia generator/DB runtime.
- Reducir dispersión entre docs de continuidad, governance y canónicos de R01.
