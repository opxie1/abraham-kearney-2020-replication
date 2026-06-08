# Replication check

## Tables vs the authors' spreadsheets

Tolerance: 0.001.

| Table | Cells | Failures | Max abs diff |
|-------|-------|----------|--------------|
| 1A | 174 | 0 | 1.60e-13 |
| 1B | 174 | 0 | 3.18e-13 |
| 1C | 174 | 0 | 2.22e-13 |
| 2A | 39 | 0 | 2.09e-06 |
| 2B | 126 | 0 | 4.56e-06 |

## Figure 1 vs the authors' spreadsheet

| Series | Failures | Max abs diff |
|--------|----------|--------------|
| epop16_24 | 0 | 7.65e-08 |
| epop25_54 | 0 | 7.43e-08 |
| epop55_64 | 0 | 7.02e-08 |
| epop65 | 0 | 5.43e-08 |
| epop_all | 0 | 7.82e-08 |

## Table 3

| Factor | Computed | Workbook | Diff | Paper | Status |
|--------|----------|----------|------|-------|--------|
| Import competition from China | 0.9193 | 0.9193 | 1.11e-15 | 0.92 | PASS |
| Adoption of industrial robots | 0.4339 | 0.4339 | 7.27e-15 | 0.43 | PASS |
| Increased receipt of disability benefits (SSDI, VADC) | 0.1701 | 0.1701 | 2.39e-09 | 0.17 | PASS |
| Higher minimum wages | 0.1000 | 0.1000 | 0.00e+00 | 0.10 | PASS |
| Increased rate of incarceration | 0.1191 | 0.1191 | 1.45e-07 | 0.12 | PASS |

Disability jobs: ours 438436.7, workbook 438436.7 (diff 1.16e-10).
Incarceration jobs: ours 307065.6, workbook 307065.6 (diff 0.00e+00).

## Parquet

Rows: 2,312,616, columns: 12, size: 15.9 MB.

Variable labels:

- year: Survey year
- month: Survey month (1-12)
- age: Age in years (top-coded at 90 by IPUMS)
- age_group_detailed: Age group, 13 bins
- age_group_summary: Age group, 6 bins (Tables 1A-C)
- age_group_decomp: Age group, 4 bins (Tables 2A-B)
- sex: Sex (Male or Female)
- education: Education, ages 25 and up
- school_status: School enrollment, ages 16-24
- educgroup: Education or enrollment group, 6 levels
- employed: Employed (1 = yes, 0 = no)
- weight: CPS person weight
