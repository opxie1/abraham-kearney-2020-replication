# Abraham & Kearney (2020, JEL) replication

Reproduces Tables 1A/B/C, 2A/B, and Figure 1 of:

> Abraham, K., and M. Kearney. 2020. "Explaining the Decline in the US Employment-to-Population Ratio: A Review of the Evidence." JEL 58(3): 585-643.

## Setup

1. R 4.x. Install via `winget install RProject.R` on Windows.
2. Download the authors' package from [openICPSR project 119453](https://www.openicpsr.org/openicpsr/project/119453) and unzip to `./repkit/`. The package is 180 MB zipped, 575 MB unzipped (includes a 328 MB BLS time series).
3. Install packages:

```r
install.packages(c("tidyverse", "arrow", "readxl", "haven",
                   "here", "janitor", "scales", "glue"))
```

## Run

```sh
Rscript R/run_all.R
```

Takes ~3 min. Sources `R/00_setup.R`, then `01` through `06` in order.

## Outputs

- `data/analysis.parquet`: labelled CPS microdata, 2.3M rows
- `output/table_1a.csv`, `table_1b.csv`, `table_1c.csv`: Tables 1A/B/C
- `output/table_2a.csv`, `table_2b.csv`: Tables 2A/B
- `output/figure_1.png`, `figure_1.pdf`, `figure_1_data.csv`: Figure 1
- `docs/replication_check.md`: cell-by-cell diff vs the authors' Excel
- `docs/diff_table_*.csv`, `diff_figure_1.csv`: per-cell diffs
- `docs/sessionInfo.txt`: R session

## Verification

687 Table cells and 810 Figure 1 points compared against the authors' Excel. Zero failures at tolerance 0.001. Max abs diff: 5e-6 (Tables 2A/B), 1e-13 (Tables 1A/B/C), 8e-8 (Figure 1).

See `docs/replication_check.md` for the diff and the one Stata quirk we replicate (Male's 1999 EPOP used as `term2` centring for the Overall Table 2 column).
