# Global Tourism Data Analysis — SAS Case Study

SAS pipeline that cleans, transforms, and analyzes global IMF/World Bank tourism data. Applies DATA step control flow, type conversion, string functions, custom formats, conditional multi-table output, sorted merges, and PROC TRANSPOSE to compare inbound vs. outbound expenditures by country.

---

## Setup
Before running the main program, execute the setup script to load the required source tables into the WORK library:

```
Run PG2_CaseStudy_cre8data.sas
```

This creates the two input tables used throughout the case study:
- **`country_info`** — country metadata including continent codes
- **`tourism`** — raw IMF/World Bank tourism statistics

---

## Pipeline Steps
| Step | Description |
|---|---|
| 1 | Clean and standardize raw tourism data |
| 2 | Split into `expenditures` and `tourists` tables |
| 3 | Define custom continent format |
| 4 | Sort country metadata for merging |
| 5a–5b | Merge tourism data with country metadata |
| 6 | Transpose expenditures to wide format |
| 7 | Calculate inbound vs. outbound percentage difference |
| 8 | Print filtered results for target country |
