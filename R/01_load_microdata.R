source(here::here("R", "00_setup.R"))

cat("[01] Reading CPS fixed-width extract …\n")

fwf_col_types <- cols(
  year     = col_integer(),
  month    = col_integer(),
  wtfinl   = col_double(),
  age      = col_integer(),
  sex      = col_integer(),
  race     = col_integer(),
  empstat  = col_integer(),
  ind1990  = col_integer(),
  educ     = col_integer(),
  schlcoll = col_integer(),
  compwt   = col_double()
)

cps_fwf <- read_fwf(
  file = FILE_CPS_FWF,
  col_positions = fwf_positions(
    start     = CPS_FWF_POSITIONS$start,
    end       = CPS_FWF_POSITIONS$end,
    col_names = CPS_FWF_POSITIONS$name
  ),
  col_types = fwf_col_types,
  progress  = FALSE
)

cat(sprintf("[01] FWF read: %d rows, %d cols\n", nrow(cps_fwf), ncol(cps_fwf)))

cps_fwf <- cps_fwf |>
  mutate(
    wtfinl = wtfinl / WEIGHT_SCALE,
    compwt = compwt / WEIGHT_SCALE
  )

cps_micro <- cps_fwf |>
  filter(year %in% YEARS, age >= 16)

cat(sprintf("[01] After filter (age>=16, year in %s): %d rows\n",
            paste(YEARS, collapse = "/"), nrow(cps_micro)))

cat("[01] Loading authors' cps_main.dta for cross-check …\n")
cps_dta <- read_dta(FILE_CPS_DTA) |>
  filter(year %in% YEARS, age >= 16) |>
  mutate(across(c(year, age, sex, empstat, educ, schlcoll, month), as.integer))

stopifnot(nrow(cps_micro) == nrow(cps_dta))
diff_weight <- abs(sum(cps_micro$compwt) - sum(cps_dta$compwt))
stopifnot(diff_weight < WEIGHT_DIFF_TOL)
cat(sprintf("[01] FWF/dta cross-check OK (n=%d, |Δsum(compwt)|=%.3e)\n",
            nrow(cps_micro), diff_weight))

saveRDS(cps_micro, FILE_MICRO_RDS)
cat(sprintf("[01] Wrote %s (%.1f MB)\n", FILE_MICRO_RDS,
            file.info(FILE_MICRO_RDS)$size / 1024^2))
