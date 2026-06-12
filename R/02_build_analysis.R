source(here::here("R", "00_setup.R"))

cps <- readRDS(FILE_MICRO_RDS)
cat("Loaded", nrow(cps), "rows.\n")

analysis <- cps |>
  mutate(
    educ_group = case_when(
      educ >= 2 & educ <= 72 ~ "3. No HS",
      educ == 73 ~ "4. HS Grad",
      educ >= 81 & educ <= 110 ~ "5. Some Coll.",
      educ >= 111 & educ <= 125 ~ "6. Coll. Grad"
    ),
    school = case_when(
      age <= 24 & schlcoll >= 1 & schlcoll <= 4 ~ "2. In School",
      age <= 24 ~ "1. Not In School"
    ),
    educgroup = factor(if_else(age <= 24, school, educ_group), levels = EDUCGROUP_LEVELS),
    education = factor(
      if_else(age >= 25,
              recode(educ_group,
                     "3. No HS" = "Less than HS",
                     "4. HS Grad" = "HS",
                     "5. Some Coll." = "Some college",
                     "6. Coll. Grad" = "College+"),
              NA_character_),
      levels = EDU_LEVELS_FINAL
    ),
    school_status = factor(
      if_else(age <= 24,
              recode(school,
                     "1. Not In School" = "Not in school",
                     "2. In School" = "In school"),
              NA_character_),
      levels = SCHOOL_LEVELS
    ),
    sex = factor(if_else(sex == 1, "Male", "Female"), levels = SEX_LEVELS),
    employed = as.integer(empstat %in% EMPLOYED_STATUSES),
    weight = compwt,
    age_group_detailed = cut(age, AGE_BREAKS_DET, AGE_LABELS_DET, right = FALSE, include.lowest = TRUE),
    age_group_summary = cut(age, AGE_BREAKS_SUMM, AGE_LABELS_SUMM, right = FALSE, include.lowest = TRUE),
    age_group_decomp = cut(age, AGE_BREAKS_DECOMP, AGE_LABELS_DECOMP, right = FALSE, include.lowest = TRUE)
  ) |>
  select(year, age,
         age_group_detailed, age_group_summary, age_group_decomp,
         sex, education, school_status, educgroup, employed, weight)

cat("Built the analysis data:", nrow(analysis), "rows,", ncol(analysis), "columns.\n")

labels <- c(
  year = "Survey year",
  age = "Age in years (top-coded at 90 by IPUMS)",
  age_group_detailed = "Age group, 13 bins",
  age_group_summary = "Age group, 6 bins (Tables 1A-C)",
  age_group_decomp = "Age group, 4 bins (Tables 2A-B)",
  sex = "Sex (Male or Female)",
  education = "Education, ages 25 and up",
  school_status = "School enrollment, ages 16-24",
  educgroup = "Education or enrollment group, 6 levels",
  employed = "Employed (1 = yes, 0 = no)",
  weight = "CPS person weight"
)
for (col in names(labels)) {
  attr(analysis[[col]], "label") <- labels[[col]]
}

write_parquet(analysis, FILE_ANALYSIS, compression = "zstd", compression_level = 9)
cat("Wrote", FILE_ANALYSIS, "\n")
