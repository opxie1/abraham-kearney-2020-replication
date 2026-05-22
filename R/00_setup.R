# Paths, constants, factor levels.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(readr)
  library(stringr)
  library(forcats)
  library(ggplot2)
  library(tibble)
  library(arrow)
  library(readxl)
  library(haven)
  library(here)
  library(janitor)
  library(scales)
  library(glue)
})

# Paths.
PATH_REPKIT      <- here("repkit", "CPS-programs-and-data")
PATH_RAW_CPS     <- file.path(PATH_REPKIT, "Data", "Raw-CPS-extract")
PATH_RAW_BLS     <- file.path(PATH_REPKIT, "Data", "Raw-BLS-extract")
PATH_OUTPUT_XLSX <- file.path(PATH_REPKIT, "Output")

PATH_DATA        <- here("data")
PATH_OUTPUT      <- here("output")
PATH_DOCS        <- here("docs")
dir.create(PATH_DATA,   showWarnings = FALSE, recursive = TRUE)
dir.create(PATH_OUTPUT, showWarnings = FALSE, recursive = TRUE)
dir.create(PATH_DOCS,   showWarnings = FALSE, recursive = TRUE)

FILE_CPS_FWF  <- file.path(PATH_RAW_CPS, "cps_00036.dat.gz")
FILE_CPS_DTA  <- file.path(PATH_RAW_CPS, "cps_main.dta")
FILE_BLS_TS   <- file.path(PATH_RAW_BLS, "ln.data.1.AllData.txt")
FILE_BLS_IDS  <- file.path(PATH_RAW_BLS, "series_ids.csv")
FILE_XLSX_TAB <- file.path(PATH_OUTPUT_XLSX, "Abraham-Kearney-Decompositions (2019-06-09).xlsx")
FILE_XLSX_FIG <- file.path(PATH_OUTPUT_XLSX, "Abraham-Kearney-Figure1 (2019-06-07).xlsx")

FILE_MICRO_RDS <- file.path(PATH_DATA, "cps_microdata_raw.rds")
FILE_ANALYSIS  <- file.path(PATH_DATA, "analysis.parquet")

# Anchor years.
YEAR_BASE       <- 1999L
YEAR_END        <- 2018L
YEARS           <- c(YEAR_BASE, YEAR_END)
YEAR_FIG1_START <- 1965L
YEAR_FIG1_END   <- 2018L

# Tolerances.
WEIGHT_DIFF_TOL <- 1e-3
SHARE_TOL       <- 1e-9
TOL_DIFF        <- 0.001

# Top-open to absorb any IPUMS top-code.
AGE_BREAKS_DET <- c(16, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, Inf)
AGE_LABELS_DET <- c(
  "16-19", "20-24", "25-29", "30-34", "35-39",
  "40-44", "45-49", "50-54", "55-59", "60-64",
  "65-69", "70-74", "75+"
)

# 6-bin age cuts.
AGE_BREAKS_SUMM <- c(16, 25, 35, 45, 55, 65, Inf)
AGE_LABELS_SUMM <- c("16-24", "25-34", "35-44", "45-54", "55-64", "65+")

# 4-bin age cuts.
AGE_BREAKS_DECOMP <- c(16, 25, 55, 65, Inf)
AGE_LABELS_DECOMP <- c("16-24", "25-54", "55-64", "65+")

# Display factors.
EDU_LEVELS_FINAL <- c("Less than HS", "HS", "Some college", "College+")
SCHOOL_LEVELS    <- c("In school", "Not in school")

# Stata sort-order prefixes.
EDUCGROUP_LEVELS <- c(
  "1. Not In School", "2. In School",
  "3. No HS", "4. HS Grad", "5. Some Coll.", "6. Coll. Grad"
)
EDUCGROUP_DISPLAY <- c(
  "Not in school", "In school",
  "Less than HS", "HS", "Some college", "College+"
)

# IPUMS sex codes.
SEX_LEVELS <- c("Male", "Female")

# FWF positions from cps_9918_input.do.
CPS_FWF_POSITIONS <- tibble::tribble(
  ~name,     ~start, ~end, ~type,
  "year",     1L,     4L,   "i",
  "month",    5L,     6L,   "i",
  "wtfinl",   7L,    20L,   "d",
  "age",     21L,    22L,   "i",
  "sex",     23L,    23L,   "i",
  "race",    24L,    26L,   "i",
  "empstat", 27L,    28L,   "i",
  "ind1990", 29L,    31L,   "i",
  "educ",    32L,    34L,   "i",
  "schlcoll", 35L,   35L,   "i",
  "compwt",  36L,    49L,   "d"
)
# Stata divides by this on read.
WEIGHT_SCALE <- 10000

# At-work + has-job-not-at-work.
EMPLOYED_STATUSES <- c(10L, 12L)

invisible(NULL)
