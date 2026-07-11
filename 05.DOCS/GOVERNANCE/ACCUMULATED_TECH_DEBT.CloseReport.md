
========== CR-CLOSE-0081_TECH_DEBT_20260705_141014 ==========

- TD-001 [P0/OPEN]: Scripts interactivos Excel tardaron demasiado. Impact: Bloquea operacion diaria y genera sospecha de congelamiento. Next: Crear cache persistente y runtime budget con heartbeat.
- TD-002 [P0/OPEN]: No hay atlas global celda/formula/referencia para todos los Excel/PDF. Impact: Se repite analisis caro. Next: CR-INDEX-0001 offline.
- TD-003 [P0/OPEN]: No hay limite formal de 30 minutos interactivos. Impact: Riesgo de ejecuciones largas no autorizadas. Next: Registrar GRC.LONG_RUNNING_ANALYSIS_BUDGET.
- TD-004 [P0/OPEN]: Builder final bloqueado por dependencias circulares y Bases parcial. Impact: No prometer reporte oficial final aun. Next: DB/staging demo primero.
- TD-005 [P1/OPEN]: No hay evidencia RADAR/BATON/WHOAMI actual en este chat. Impact: Cierre queda WARN si no se valida localmente. Next: Ejecutar RADAR/readiness o aceptar WARN.

