source(here::here("R", "00_setup.R"))

cps_micro <- readRDS(FILE_MICRO_RDS)
cat(sprintf("[02] Loaded raw microdata: %d rows\n", nrow(cps_micro)))

analysis <- cps_micro |>
  mutate(
    educ_25plus_raw = case_when(
      educ >= 2   & educ <= 72  ~ "3. No HS",
      educ == 73                ~ "4. HS Grad",
      educ >= 81  & educ <= 110 ~ "5. Some Coll.",
      educ >= 111 & educ <= 125 ~ "6. Coll. Grad",
      TRUE                       ~ NA_character_
    ),
    school_raw = case_when(
      age >= 16 & age <= 24 & schlcoll >= 1 & schlcoll <= 4 ~ "2. In School",
      age >= 16 & age <= 24                                  ~ "1. Not In School",
      TRUE                                                    ~ NA_character_
    ),
    educgroup_raw = if_else(age >= 16 & age <= 24,
                            school_raw,
                            educ_25plus_raw),
    educgroup = factor(educgroup_raw, levels = EDUCGROUP_LEVELS),
    education = factor(
      if_else(age >= 25,
              recode(educ_25plus_raw,
                     "3. No HS"      = "Less than HS",
                     "4. HS Grad"    = "HS",
                     "5. Some Coll." = "Some college",
                     "6. Coll. Grad" = "College+"),
              NA_character_),
      levels = EDU_LEVELS_FINAL
    ),
    school_status = factor(
      if_else(age >= 16 & age <= 24,
              recode(school_raw,
                     "1. Not In School" = "Not in school",
                     "2. In School"     = "In school"),
              NA_character_),
      levels = SCHOOL_LEVELS
    ),
    sex = factor(case_when(sex == 1L ~ "Male",
                           sex == 2L ~ "Female",
                           TRUE      ~ NA_character_),
                 levels = SEX_LEVELS),
    employed = as.integer(empstat %in% EMPLOYED_STATUSES),
    weight   = compwt,
    age_group_detailed = cut(age, breaks = AGE_BREAKS_DET,
                             labels = AGE_LABELS_DET, right = FALSE,
                             include.lowest = TRUE),
    age_group_summary  = cut(age, breaks = AGE_BREAKS_SUMM,
                             labels = AGE_LABELS_SUMM, right = FALSE,
                             include.lowest = TRUE),
    age_group_decomp   = cut(age, breaks = AGE_BREAKS_DECOMP,
                             labels = AGE_LABELS_DECOMP, right = FALSE,
                             include.lowest = TRUE)
  ) |>
  select(
    year, month, age,
    age_group_detailed, age_group_summary, age_group_decomp,
    sex, education, school_status, educgroup,
    employed, weight
  )

stopifnot(
  all(is.na(analysis$education) == (analysis$age < 25)),
  all(is.na(analysis$school_status) == (analysis$age >= 25)),
  !anyNA(analysis$sex),
  sum(is.na(analysis$educgroup) & analysis$age >= 25) == 0,
  !anyNA(analysis$age_group_detailed),
  !anyNA(analysis$age_group_summary),
  !anyNA(analysis$age_group_decomp)
)

cat(sprintf("[02] Built analysis frame: %d rows, %d cols\n",
            nrow(analysis), ncol(analysis)))

col_labels <- c(
  year               = "Survey year",
  month              = "Survey month (1-12)",
  age                = "Age in years (top-coded at 90 by IPUMS)",
  age_group_detailed = "Age group, 13-bin: 16-19, 20-24, ..., 75+",
  age_group_summary  = "Age group, 6-bin (Tables 1A-C)",
  age_group_decomp   = "Age group, 4-bin (Tables 2A-B decomposition)",
  sex                = "Sex: Male / Female (IPUMS 1=M, 2=F)",
  education          = "Educational attainment, ages 25+ (4-level recode)",
  school_status      = "Enrollment status, ages 16-24",
  educgroup          = "Stata `educgroup`: enrollment (16-24) or education (25+), 6 levels",
  employed           = "Employed indicator (empstat in {10, 12} = at work or has job not at work)",
  weight             = "CPS composite weight (compwt, rescaled /10000 per cps_9918_input.do)"
)
stopifnot(setequal(names(col_labels), names(analysis)))
for (col in names(col_labels)) {
  attr(analysis[[col]], "label") <- col_labels[[col]]
}

write_parquet(analysis, FILE_ANALYSIS,
              compression = "zstd", compression_level = 9)

cat(sprintf("[02] Wrote %s (%.1f MB)\n", FILE_ANALYSIS,
            file.info(FILE_ANALYSIS)$size / 1024^2))

back <- read_parquet(FILE_ANALYSIS)
walk(names(col_labels), \(col) {
  got <- attr(back[[col]], "label")
  if (!identical(got, col_labels[[col]]))
    stop(sprintf("[02] Label round-trip failed for `%s` (got %s)", col,
                 ifelse(is.null(got), "NULL", paste0("'", got, "'"))))
})
cat(sprintf("[02] All %d column labels round-trip through parquet.\n",
            length(col_labels)))

walk(c("age_group_detailed", "age_group_summary",
       "age_group_decomp", "sex", "education",
       "school_status", "educgroup"),
     \(col) cat(sprintf("[02] %s levels: %s\n", col,
                        paste(levels(analysis[[col]]), collapse = " | "))))
