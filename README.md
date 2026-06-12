# Abraham and Kearney (2020) replication

This project reproduces every table and figure from:

> Abraham, Katharine G., and Melissa S. Kearney. 2020. "Explaining the Decline in the US Employment-to-Population Ratio: A Review of the Evidence." Journal of Economic Literature 58 (3): 585-643.

That means Tables 1A, 1B, 1C, 2A, 2B, Table 3, and Figure 1.

## Setup

1. Install R (version 4 or newer). On Windows: `winget install RProject.R`.
2. Download the authors' replication package from [openICPSR project 119453](https://www.openicpsr.org/openicpsr/project/119453) and unzip it into a folder called `repkit` inside this project. The download is about 180 MB and unzips to about 575 MB. Most of that is one big Bureau of Labor Statistics file.
3. Install the R packages:

```r
install.packages(c("tidyverse", "arrow", "readxl", "haven", "here"))
```

## How to run it

```sh
Rscript R/run_all.R
```

The whole run takes about 3 minutes. The scripts read the Current Population Survey data, build the parquet file, make the five tables and Figure 1, compute Table 3 from the authors' spreadsheets, and then check every number against the authors' files.

A finished run prints a `Done.` line at the end. On Windows, R can still show a non-zero exit code after that line. It comes from a known shutdown bug in the arrow package, not from these scripts. Every output file is already written by that point, so the `Done.` line is what tells you the run worked.

## What it produces

- `data/analysis.parquet`: the Current Population Survey data, about 2.3 million rows and 11 columns in a 16 MB compressed file, with a label on every column. It only keeps the variables the tables and figures actually use.
- `output/table_1a.csv`, `table_1b.csv`, `table_1c.csv`: Tables 1A, 1B, and 1C
- `output/table_2a.csv`, `table_2b.csv`: Tables 2A and 2B
- `output/table_3.csv`, `table_3.txt`: Table 3, as a spreadsheet and as a text version laid out like the page in the paper
- `output/figure_1.png`, `figure_1.pdf`, `figure_1_data.csv`: Figure 1 and the numbers behind it
- `docs/replication_check.md`: a report comparing my numbers cell by cell against the authors' spreadsheets
- `docs/diff_table_1a.csv` and the other files starting with `diff_`: the cell by cell comparisons behind that report ("diff" is short for difference)
- `docs/sessionInfo.txt`: the R version and package versions the run used

## Checking the results

The comparison covers 687 table cells, 810 Figure 1 points, and the 5 computed Table 3 values, all checked against the authors' own files. Nothing is off by more than 0.001, and the real gaps are far smaller than that. The largest one is 1.6e-13 for Tables 1A through 1C, 4.6e-6 for Tables 2A and 2B, 7.8e-8 for Figure 1, and 1.5e-7 for Table 3. That is rounding noise. The two decimal numbers printed in the paper match exactly.

One detail to know about Table 2. In the authors' Stata code, the second term of the decomposition (the part that measures how population shifts matter) is centered on the male 1999 employment-to-population ratio, even in the Overall column that covers everyone. That looks like an accident of how their code reshaped the data, but it is what produced the published numbers, so my code does the same thing on purpose. The columns still add up to 1 either way.
