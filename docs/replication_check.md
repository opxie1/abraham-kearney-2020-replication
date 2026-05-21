# Replication check

Generated: 2026-05-21 17:27:59.471379

## Files used

- `repkit/CPS-programs-and-data/Data/Raw-CPS-extract/cps_00036.dat.gz`: primary microdata
- `repkit/CPS-programs-and-data/Data/Raw-CPS-extract/cps_9918_input.do`: FWF positions, weight rescaling
- `repkit/CPS-programs-and-data/Data/Raw-CPS-extract/cps_main.dta`: cross-check
- `repkit/CPS-programs-and-data/Data/Raw-BLS-extract/ln.data.1.AllData.txt`: BLS LNS, Figure 1
- `repkit/CPS-programs-and-data/Data/Raw-BLS-extract/series_ids.csv`: 42 series
- `repkit/CPS-programs-and-data/Programs/Tables and Figures.do`: master script
- `repkit/CPS-programs-and-data/Programs/ado/*.ado`: sub-programs
- `repkit/CPS-programs-and-data/Output/*.xlsx`: published values

## Files ignored

- `summarize_by_age_det.ado`, `summarize_by_age_educ_det.ado`: not invoked by master
- `Data/temp/*.dta`: Stata scratch
- `Table-3-data-and-calculations/`: out of scope

## Decisions

- CPS reads via FWF (`readr::read_fwf`) using positions from `cps_9918_input.do`. `cps_main.dta` confirms n and `sum(compwt)` to zero diff.
- Education recoding mirrors `educgroup` in `Tables and Figures.do` lines 86-99.
- `epop_all` for Table 2 follows `decomp_by_age.ado` exactly. The Stata `local epop_all = epop1999[1]` runs after `reshape wide epop, i(sex) j(year)`. For Male and Female panels this gives the gender's 1999 EPOP. For the Overall panel the reshape produces two rows sorted by `sex`, so `epop1999[1]` is Male's 1999 EPOP rather than the both-genders value the spec assumed. Published cells use Male's value; the R code does too. Each Overall column still sums to 1 because `sum(sidiff) = 0`.
- Table 2B 16-24 has 2 educ categories (school status); 25+ has 4 (HS recode). The 14-cell-per-panel structure follows from `(agegroup_decomp, educgroup)`.
- Figure 1 `All ages` = `sum(emp) / sum(pop)` within `(year, gender)`, not a mean of per-age EPOPs.
- Zero NA `educgroup` rows for age 25+. Table 2B columns sum to 1.
- Table 2 cell sums use `na.rm = TRUE` to match Stata `collapse (sum)` behaviour on missing cells. Our data has no missing (det × educ) cells, so this is dormant; included for robustness.

## Diff vs authors' xlsx

Tolerance: 0.001 on the published unit (0..1).

| Table | Cells | Failures | Max abs diff |
|-------|-------|----------|--------------|
| 1A | 174 | 0 | 1.60e-13 |
| 1B | 174 | 0 | 3.18e-13 |
| 1C | 174 | 0 | 2.22e-13 |
| 2A | 39 | 0 | 2.09e-06 |
| 2B | 126 | 0 | 4.56e-06 |

Per-cell diffs: `docs/diff_table_*.csv`.

## Figure 1 diff

162 rows (3 genders × 54 years) vs `Raw` sheet of `Abraham-Kearney-Figure1 (2019-06-07).xlsx`.

| Series | Max abs diff |
|--------|--------------|
| epop16_24 | 7.65e-08 |
| epop25_54 | 7.43e-08 |
| epop55_64 | 7.02e-08 |
| epop65 | 5.43e-08 |
| epop_all | 7.82e-08 |

Float-precision noise. BLS LNS aggregation matches Stata.

Figure 1 EPOPs (BLS LNS) differ from Table 1A E/P (CPS micro) because the underlying populations differ. Spot check: `docs/fig1_spotcheck.csv`.

## Parquet

- File: `C:/Users/xief/.local/bin/uchicago/data/analysis.parquet`
- Size: 15.9 MB
- Rows: 2,312,616
- Columns: 12
- Levels:
- `age_group_detailed`: 16-19 | 20-24 | 25-29 | 30-34 | 35-39 | 40-44 | 45-49 | 50-54 | 55-59 | 60-64 | 65-69 | 70-74 | 75+
- `age_group_summary`: 16-24 | 25-34 | 35-44 | 45-54 | 55-64 | 65+
- `age_group_decomp`: 16-24 | 25-54 | 55-64 | 65+
- `sex`: Male | Female
- `education`: Less than HS | HS | Some college | College+
- `school_status`: In school | Not in school
- `educgroup`: 1. Not In School | 2. In School | 3. No HS | 4. HS Grad | 5. Some Coll. | 6. Coll. Grad

- `NA(education) <-> age < 25`: TRUE
- `NA(school_status) <-> age >= 25`: TRUE
