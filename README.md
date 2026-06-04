# Abraham & Kearney (2020, JEL) replication

Reproduces all 7 exhibits (Tables 1A/B/C, 2A/B, 3, Figure 1) of:

> Abraham, K., and M. Kearney. 2020. "Explaining the Decline in the US Employment-to-Population Ratio: A Review of the Evidence." JEL 58(3): 585-643.

## Setup

1. R 4.x. On Windows: `winget install RProject.R`.
2. Grab the authors' replication kit from [openICPSR project 119453](https://www.openicpsr.org/openicpsr/project/119453) and unzip it to `./repkit/`. 180 MB zipped, 575 MB unzipped (a 328 MB BLS time series is most of the bulk).
3. Install packages:

```r
install.packages(c("tidyverse", "arrow", "readxl", "haven",
                   "here", "janitor", "scales", "glue"))
```

## Run

```sh
Rscript R/run_all.R
```

About 3 minutes. The pipeline loads the CPS extract, builds the parquet, writes the five tables and Figure 1, computes Table 3 from the authors' workbooks, then runs the diff.

A run that finishes prints a `[run_all] SUCCESS.` banner. On Windows the R process may then report a non-zero exit code: that is a known Apache Arrow shutdown bug (the arrow DLL unloads after R has finished), and every output is already written by the time it happens. Treat the SUCCESS banner, not the exit code, as the signal.

## Outputs

- `data/analysis.parquet`: CPS microdata, 2.3M rows, zstd-9, factor-encoded with variable labels. 12 columns, only what the tables need.
- `output/table_1a.csv`, `table_1b.csv`, `table_1c.csv`: Tables 1A/B/C
- `output/table_2a.csv`, `table_2b.csv`: Tables 2A/B
- `output/table_3.csv`, `table_3.txt`: Table 3 (CSV plus a text version laid out like the paper)
- `output/figure_1.png`, `figure_1.pdf`, `figure_1_data.csv`: Figure 1
- `docs/replication_check.md`: cell-by-cell diff against the authors' Excel and Table 3 workbooks
- `docs/diff_table_*.csv`, `diff_figure_1.csv`: per-cell diffs
- `docs/sessionInfo.txt`: R session

## Verification

The diff covers 687 Tables 1–2 cells, 810 Figure 1 points, and 5 Table 3 cells. Zero failures at tolerance 0.001. Max absolute diff: 1.6e-13 for 1A/B/C, 4.6e-6 for 2A/B, 7.8e-8 for Figure 1, and 1.5e-7 for Table 3 against the workbook at full precision (the paper's two-decimal values match exactly).

The full diff lives in `docs/replication_check.md`. It also flags the one Stata quirk preserved here: Male's 1999 EPOP centres `term2` in the Overall Table 2 column.
