source(here::here("R", "00_setup.R"))

cat("Reading the CPS data...\n")

cps <- read_fwf(
  FILE_CPS_FWF,
  fwf_positions(CPS_FWF_POSITIONS$start, CPS_FWF_POSITIONS$end, CPS_FWF_POSITIONS$name),
  col_types = cols(
    year = col_integer(),
    month = col_integer(),
    wtfinl = col_double(),
    age = col_integer(),
    sex = col_integer(),
    race = col_integer(),
    empstat = col_integer(),
    ind1990 = col_integer(),
    educ = col_integer(),
    schlcoll = col_integer(),
    compwt = col_double()
  )
)

cps$wtfinl <- cps$wtfinl / WEIGHT_SCALE
cps$compwt <- cps$compwt / WEIGHT_SCALE

cps <- cps |>
  filter(year %in% YEARS, age >= 16)

cat("Rows after keeping 1999 and 2018, age 16+:", nrow(cps), "\n")

cps_stata <- read_dta(FILE_CPS_DTA) |>
  filter(year %in% YEARS, age >= 16)

if (nrow(cps) != nrow(cps_stata)) {
  stop("Row count does not match the authors' Stata file.")
}
cat("Weight check vs Stata file (should be about 0):",
    abs(sum(cps$compwt) - sum(cps_stata$compwt)), "\n")

saveRDS(cps, FILE_MICRO_RDS)
cat("Saved the raw microdata.\n")
