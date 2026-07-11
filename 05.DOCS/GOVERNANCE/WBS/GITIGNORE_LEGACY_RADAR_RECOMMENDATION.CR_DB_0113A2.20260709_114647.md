# Gitignore / RADAR Recommendation - CR-DB-0113A2

Recommended gitignore patterns:
90.LEGACY/**
**/legacy/**
**/_legacy/**
**/archive/**

RADAR policy:
- Do not process legacy contents in CORE/FULL.
- Keep index-level visibility only: path, size, count, latest timestamp.
- Current accepted outputs must live outside legacy under WBS current folders.
