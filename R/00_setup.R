library(tidyverse)
library(arrow)
library(readxl)
library(haven)
library(here)

PATH_REPKIT <- here("repkit", "CPS-programs-and-data")
PATH_RAW_CPS <- file.path(PATH_REPKIT, "Data", "Raw-CPS-extract")
PATH_RAW_BLS <- file.path(PATH_REPKIT, "Data", "Raw-BLS-extract")
PATH_OUTPUT_XLSX <- file.path(PATH_REPKIT, "Output")

PATH_DATA <- here("data")
PATH_OUTPUT <- here("output")
PATH_DOCS <- here("docs")
dir.create(PATH_DATA, showWarnings = FALSE)
dir.create(PATH_OUTPUT, showWarnings = FALSE)
dir.create(PATH_DOCS, showWarnings = FALSE)

FILE_CPS_FWF <- file.path(PATH_RAW_CPS, "cps_00036.dat.gz")
FILE_CPS_DTA <- file.path(PATH_RAW_CPS, "cps_main.dta")
FILE_BLS_TS <- file.path(PATH_RAW_BLS, "ln.data.1.AllData.txt")
FILE_BLS_IDS <- file.path(PATH_RAW_BLS, "series_ids.csv")
FILE_XLSX_TAB <- file.path(PATH_OUTPUT_XLSX, "Abraham-Kearney-Decompositions (2019-06-09).xlsx")
FILE_XLSX_FIG <- file.path(PATH_OUTPUT_XLSX, "Abraham-Kearney-Figure1 (2019-06-07).xlsx")

PATH_T3 <- here("repkit", "Table-3-data-and-calculations")
FILE_T3_SUMMARY <- file.path(PATH_T3, "Table 3 summary calculations.xlsx")
FILE_T3_SSDI <- file.path(PATH_T3, "3a. Increased receipt of disability benefits SSDI.xlsx")
FILE_T3_VADC <- file.path(PATH_T3, "3b. Increased receipt of disability benefits VADC.xlsx")
FILE_T3_INC <- file.path(PATH_T3, "5.-Incarceration", "Calculations.xlsx")

if (!file.exists(FILE_CPS_FWF)) {
  stop("Can't find the data. Download project 119453 from openICPSR and unzip it into the repkit folder (see README).")
}

FILE_MICRO_RDS <- file.path(PATH_DATA, "cps_microdata_raw.rds")
FILE_ANALYSIS <- file.path(PATH_DATA, "analysis.parquet")

YEAR_BASE <- 1999
YEAR_END <- 2018
YEARS <- c(YEAR_BASE, YEAR_END)
YEAR_FIG1_START <- 1965
YEAR_FIG1_END <- 2018

WEIGHT_SCALE <- 10000
EMPLOYED_STATUSES <- c(10, 12)

AGE_BREAKS_DET <- c(16, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, Inf)
AGE_LABELS_DET <- c("16-19", "20-24", "25-29", "30-34", "35-39", "40-44",
                    "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75+")

AGE_BREAKS_SUMM <- c(16, 25, 35, 45, 55, 65, Inf)
AGE_LABELS_SUMM <- c("16-24", "25-34", "35-44", "45-54", "55-64", "65+")

AGE_BREAKS_DECOMP <- c(16, 25, 55, 65, Inf)
AGE_LABELS_DECOMP <- c("16-24", "25-54", "55-64", "65+")

EDU_LEVELS_FINAL <- c("Less than HS", "HS", "Some college", "College+")
SCHOOL_LEVELS <- c("In school", "Not in school")
EDUCGROUP_LEVELS <- c("1. Not In School", "2. In School", "3. No HS",
                      "4. HS Grad", "5. Some Coll.", "6. Coll. Grad")
SEX_LEVELS <- c("Male", "Female")

CPS_FWF_POSITIONS <- tribble(
  ~name, ~start, ~end,
  "year", 1, 4,
  "month", 5, 6,
  "wtfinl", 7, 20,
  "age", 21, 22,
  "sex", 23, 23,
  "race", 24, 26,
  "empstat", 27, 28,
  "ind1990", 29, 31,
  "educ", 32, 34,
  "schlcoll", 35, 35,
  "compwt", 36, 49
)
