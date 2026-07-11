# PowerShell runner no dynamic regex rule - CR-DB-0124C

Effective immediately for PS.CierreMES runners:
1. Avoid dynamic PowerShell regex when parsing Excel formulas.
2. If formula parsing is required, prefer Python/openpyxl.
3. PowerShell runners should be used for orchestration, CSV/docs, and simple file operations.
4. Do not use escaped variable-like patterns such as backslash-dollar-question inside double-quoted strings.
5. For planning-only runners, prefer artifact-driven logic over formula parsing.

Reason:
CR-DB-0124B failed because PowerShell interpreted dollar-question in a regex string as the automatic success variable, producing invalid regex text.
