# Replication check

## Files used

- `repkit/CPS-programs-and-data/Data/Raw-CPS-extract/cps_00036.dat.gz`: primary microdata
- `repkit/CPS-programs-and-data/Data/Raw-CPS-extract/cps_9918_input.do`: FWF positions, weight rescaling
- `repkit/CPS-programs-and-data/Data/Raw-CPS-extract/cps_main.dta`: cross-check
- `repkit/CPS-programs-and-data/Data/Raw-BLS-extract/ln.data.1.AllData.txt`: BLS LNS, Figure 1
- `repkit/CPS-programs-and-data/Data/Raw-BLS-extract/series_ids.csv`: 42 series
- `repkit/CPS-programs-and-data/Programs/Tables and Figures.do`: master script
- `repkit/CPS-programs-and-data/Programs/ado/*.ado`: sub-programs
- `repkit/CPS-programs-and-data/Output/*.xlsx`: published values
- `repkit/Table-3-data-and-calculations/Table 3 summary calculations.xlsx`: Table 3 pp values
- `repkit/Table-3-data-and-calculations/3a. Increased receipt of disability benefits SSDI.xlsx`: SSDI workers (K23)
- `repkit/Table-3-data-and-calculations/3b. Increased receipt of disability benefits VADC.xlsx`: VADC workers (E27)
- `repkit/Table-3-data-and-calculations/5.-Incarceration/Calculations.xlsx`: incarceration jobs (E36)

## Files ignored

- `summarize_by_age_det.ado`, `summarize_by_age_educ_det.ado`: not invoked by master
- `Data/temp/*.dta`: Stata scratch

## Decisions

- CPS reads via FWF (`readr::read_fwf`) using positions from `cps_9918_input.do`. `cps_main.dta` confirms n and `sum(compwt)` to zero diff.
- Education recoding mirrors `educgroup` in `Tables and Figures.do` lines 86-99.
- `epop_all` for Table 2 mirrors `decomp_by_age.ado`. The Stata `local epop_all = epop1999[1]` runs after `reshape wide epop, i(sex) j(year)`. For Male and Female panels this gives the gender's 1999 EPOP. For the Overall panel, the reshape produces two rows sorted by `sex`, so `epop1999[1]` picks up Male's 1999 EPOP instead of a both-genders value. The published cells use Male's value; so does the R code. Each Overall column still sums to 1 because `sum(sidiff) = 0`.
- Table 2B 16-24 has 2 educ categories (school status); 25+ has 4 (HS recode). The 14-cell-per-panel structure follows from `(agegroup_decomp, educgroup)`.
- Figure 1 `All ages` = `sum(emp) / sum(pop)` within `(year, gender)`, not a mean of per-age EPOPs.
- Zero NA `educgroup` rows for age 25+. Table 2B columns sum to 1.
- Table 2 cell sums use `na.rm = TRUE` to match Stata `collapse (sum)` behaviour on missing cells. The CPS extract has no missing (det × educ) cells, so this never fires. Belt and suspenders.
- Age cuts use `Inf` as the top break so any IPUMS top-code (current max 90) maps to the `75+` / `65+` bin without dropping rows.

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

810 points (3 genders × 54 years × 5 series) vs `Raw` sheet of `Abraham-Kearney-Figure1 (2019-06-07).xlsx`.

| Series | Failures | Max abs diff |
|--------|----------|--------------|
| epop16_24 | 0 | 7.65e-08 |
| epop25_54 | 0 | 7.43e-08 |
| epop55_64 | 0 | 7.02e-08 |
| epop65 | 0 | 5.43e-08 |
| epop_all | 0 | 7.82e-08 |

Per-cell diffs: `docs/diff_figure_1_cells.csv`. Float-precision noise. BLS LNS aggregation matches Stata.

Figure 1 EPOPs (BLS LNS) differ from Table 1A E/P (CPS micro) because the underlying populations differ. Spot check: `docs/fig1_spotcheck.csv`.

## Table 3 diff

Table 3 synthesises effect-size estimates from several external studies. `R/07_table3.R` re-implements the authors' arithmetic from `repkit/Table-3-data-and-calculations/*.xlsx`. The check compares the 5 computed cells to the authors' summary workbook at full precision, and to the paper's rounded values.

| Factor | Computed pp | Workbook pp | Diff | Paper (2 dp) | Status |
|--------|------------:|------------:|-----:|-------------:|:------:|
| Import competition from China | 0.9193 | 0.9193 | 1.11e-15 | 0.92 | PASS |
| Adoption of industrial robots | 0.4339 | 0.4339 | 7.27e-15 | 0.43 | PASS |
| Increased receipt of disability benefits (SSDI, VADC) | 0.1701 | 0.1701 | 2.39e-09 | 0.17 | PASS |
| Higher minimum wages | 0.1000 | 0.1000 | 0.00e+00 | 0.10 | PASS |
| Increased rate of incarceration | 0.1191 | 0.1191 | 1.45e-07 | 0.12 | PASS |

Intermediate job-count check vs per-factor workbooks (max abs diff = 1.16e-10):

| Intermediate | Ours (jobs) | Workbook (jobs) | Diff |
|--------------|------------:|----------------:|-----:|
| Disability (SSDI K23 + VADC E27) | 438436.682 | 438436.682 | 1.16e-10 |
| Incarceration (|E36|) | 307065.625 | 307065.625 | 0.00e+00 |

Per-cell diffs: `docs/diff_table_3.csv` and `docs/diff_table_3_intermediates.csv`.

Five `~0` rows and six `unclear` rows in `output/table_3.csv` are the authors' qualitative judgments, so there is no arithmetic to verify. `TOTAL NET EPOP DECLINE = 3.8` comes from Table 1A.

`output/table_3.txt` lays Table 3 out the way the paper does, for side-by-side reading.

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

- Variable labels:
- `year`: Survey year
- `month`: Survey month (1-12)
- `age`: Age in years (top-coded at 90 by IPUMS)
- `age_group_detailed`: Age group, 13-bin: 16-19, 20-24, ..., 75+
- `age_group_summary`: Age group, 6-bin (Tables 1A-C)
- `age_group_decomp`: Age group, 4-bin (Tables 2A-B decomposition)
- `sex`: Sex: Male / Female (IPUMS 1=M, 2=F)
- `education`: Educational attainment, ages 25+ (4-level recode)
- `school_status`: Enrollment status, ages 16-24
- `educgroup`: Stata `educgroup`: enrollment (16-24) or education (25+), 6 levels
- `employed`: Employed indicator (empstat in {10, 12} = at work or has job not at work)
- `weight`: CPS composite weight (compwt, rescaled /10000 per cps_9918_input.do)

- `NA(education) <-> age < 25`: TRUE
- `NA(school_status) <-> age >= 25`: TRUE
