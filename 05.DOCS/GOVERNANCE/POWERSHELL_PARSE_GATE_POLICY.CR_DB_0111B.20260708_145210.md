# PowerShell Parse Gate Policy — CR-DB-0111B

- MB_ID: CR-DB-0111B-BUILD-PKO-R01-C-AUDIT-VISUAL-PARSE-GATED
- Status: ACTIVE

Every generated PowerShell runner must pass Parser.ParseFile before execution and must report PARSE_GATE=PASS in TOVS.

Blocked anti-pattern: function calls inside array literals without parentheses, e.g. @(, SafeText ).
