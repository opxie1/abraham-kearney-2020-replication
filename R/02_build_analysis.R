# Derive labels, write parquet.

source(here::here("R", "00_setup.R"))

cps_micro <- readRDS(FILE_MICRO_RDS)
cat(sprintf("[02] Loaded raw microdata: %d rows\n", nrow(cps_micro)))

# Match master .do lines 86-108.
analysis <- cps_micro |>
  mutate(
    # 25+ four-level recode.
    educ_25plus_raw = case_when(
      educ >= 2   & educ <= 72  ~ "3. No HS",
      educ == 73                ~ "4. HS Grad",
      educ >= 81  & educ <= 110 ~ "5. Some Coll.",
      educ >= 111 & educ <= 125 ~ "6. Coll. Grad",
      TRUE                       ~ NA_character_
    ),
    # 16-24 school flag.
    school_raw = case_when(
      age >= 16 & age <= 24 & schlcoll >= 1 & schlcoll <= 4 ~ "2. In School",
      age >= 16 & age <= 24                                  ~ "1. Not In School",
      TRUE                                                    ~ NA_character_
    ),
    # School overrides educ for 16-24.
    educgroup_raw = if_else(age >= 16 & age <= 24,
                            school_raw,
                            educ_25plus_raw),
    educgroup = factor(educgroup_raw, levels = EDUCGROUP_LEVELS),
    # Spec: NA when age<25.
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
    # Spec: NA when age>=25.
    school_status = factor(
      if_else(age >= 16 & age <= 24,
              recode(school_raw,
                     "1. Not In School" = "Not in school",
                     "2. In School"     = "In school"),
              NA_character_),
      levels = SCHOOL_LEVELS
    ),
    # IPUMS: 1=M, 2=F.
    sex = factor(if_else(sex == 1L, "Male", "Female"), levels = SEX_LEVELS),
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

# NA invariants.
stopifnot(
  all(is.na(analysis$education) == (analysis$age < 25)),
  all(is.na(analysis$school_status) == (analysis$age >= 25))
)
# Spec assumes 0 NA educgroup rows for 25+; verify.
stopifnot(sum(is.na(analysis$educgroup) & analysis$age >= 25) == 0)

cat(sprintf("[02] Built analysis frame: %d rows, %d cols\n",
            nrow(analysis), ncol(analysis)))

write_parquet(analysis, FILE_ANALYSIS,
              compression = "zstd", compression_level = 9)

cat(sprintf("[02] Wrote %s (%.1f MB)\n", FILE_ANALYSIS,
            file.info(FILE_ANALYSIS)$size / 1024^2))

# Audit factor levels.
for (col in c("age_group_detailed", "age_group_summary",
              "age_group_decomp", "sex", "education",
              "school_status", "educgroup")) {
  cat(sprintf("[02] %s levels: %s\n", col,
              paste(levels(analysis[[col]]), collapse = " | ")))
}
