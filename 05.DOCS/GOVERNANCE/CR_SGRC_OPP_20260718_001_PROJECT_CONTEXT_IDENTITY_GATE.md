# CloseReport — Oportunidad acumulada de mejora Skills/GRCs

ENTRY_ID: CR-SGRC-OPP-20260718-001
DATE: 2026-07-18
SOURCE_PROJECT: PS.CierreMES / CloseReport
SOURCE_ROOT: C:\01. GitHub\CloseReport
TARGET_REGISTER: C:\01. GitHub\CloseReport\05.DOCS\GOVERNANCE\SKILLS_GRC_ACCUMULATED_LESSONS.md
STATUS: CANDIDATE
TYPE: GRC_CANDIDATE
PROPOSED_ID: GRC.PROJECT_CONTEXT_IDENTITY_GATE

## INCIDENT

Durante una conversación perteneciente a PS.CierreMES / CloseReport se continuó trabajo técnico y de cierre correspondiente a DeveFact, cuyo root operativo era:

C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\04_AGENTS\HIA.AGENTIC_FACTORY\DeveFact

La IA no detuvo el flujo ni advirtió que el proyecto activo de la conversación y el proyecto operativo de los comandos/TOVS no coincidían.

## PROBLEM

Falta un gate obligatorio de identidad de proyecto antes de proponer comandos, interpretar TOVS, modificar canon, ejecutar auditorías, preparar commit/push o declarar una minibattle o sesión como cerrada.

## PROPOSED CONTROL

Crear `GRC.PROJECT_CONTEXT_IDENTITY_GATE`.

Antes de continuar una acción gobernada, la IA debe comparar:

1. `CONVERSATION_PROJECT`
2. `EXPECTED_PROJECT`
3. `EXPECTED_ROOT`
4. `OPERATIVE_ROOT`
5. `MB_ID` o `TASK_ID`
6. `TARGET_ARTIFACTS`

## DECISION RULE

- Coincidencia completa: `PROJECT_CONTEXT_GATE=PASS`.
- Cruce explícitamente autorizado: `PROJECT_CONTEXT_GATE=PASS_WITH_EXPLICIT_CROSS_PROJECT_AUTHORIZATION`.
- Diferencia no explicada: `PROJECT_CONTEXT_GATE=FAIL`.

En `FAIL`, detenerse antes de entregar comandos de modificación, commit, push o cierre.

## REQUIRED WARNING

`PROJECT_CONTEXT_MISMATCH: esta conversación pertenece a <CONVERSATION_PROJECT>, pero la operación propuesta apunta a <OPERATIVE_PROJECT/ROOT>. No continuaré hasta confirmar el alcance correcto.`

## HARD-STOP CONDITIONS

- root operativo fuera del proyecto activo;
- MB_ID perteneciente a otro producto;
- TOVS con `PROJECT_ROOT` incompatible;
- archivos objetivo fuera del root esperado;
- cierre de sesión para un proyecto distinto;
- commit/push desde otro repositorio;
- cambio de proyecto inferido solo por arrastre contextual.

## CROSS-PROJECT EXCEPTION

Solo continuar si se declaran proyecto origen, proyecto destino, razón del cruce, root de cada proyecto, artefactos autorizados y proyecto donde se registrará el cierre.

## REQUIRED TOVS / AI_TAIL FIELDS

- `CONVERSATION_PROJECT`
- `EXPECTED_PROJECT`
- `EXPECTED_ROOT`
- `OPERATIVE_PROJECT`
- `OPERATIVE_ROOT`
- `PROJECT_CONTEXT_GATE`
- `CROSS_PROJECT_AUTHORIZED`
- `PROJECT_CONTEXT_MISMATCH_DETECTED`

## SESSION-CLOSE RULE

Antes de declarar `SESSION_CLOSED=YES`, verificar que cierre, último commit/push, BATON, SESSION_CLOSE y registros correspondan al mismo proyecto/root.

## ACCEPTANCE CRITERIA

1. Un TOVS con root de otro proyecto provoca advertencia antes de cualquier modificación.
2. Una petición de cierre en el proyecto equivocado no produce comandos de cierre.
3. Una operación cross-project autorizada continúa solo con alcance explícito.
4. El gate se ejecuta antes de commit/push y cierre.
5. El resultado queda visible en TOVS o AI_TAIL.
6. La regla es reusable por todos los proyectos gobernados.

## INCIDENT DISPOSITION

- El trabajo DeveFact ya realizado no se invalida.
- No debe continuar el cierre de DeveFact dentro de PS.CierreMES.
- La conversación debe volver al estado y backlog de CloseReport.
- El incidente sirve como evidencia para promover el GRC.

## PROMOTION TARGET

SkillsMachine.

Suggested downstream candidate:
`GRC.PROJECT_CONTEXT_IDENTITY_GATE`
