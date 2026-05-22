# Tables 1A/B/C.

source(here::here("R", "00_setup.R"))

analysis <- read_parquet(FILE_ANALYSIS)
cat(sprintf("[03] Loaded analysis parquet: %d rows\n", nrow(analysis)))

# EPOP and share within year.
epop_and_share <- function(df, ...) {
  group_cols <- enquos(...)
  df |>
    summarise(
      wt_emp = sum(employed * weight),
      wt_pop = sum(weight),
      .by    = c(year, !!!group_cols)
    ) |>
    group_by(year) |>
    mutate(si = wt_pop / sum(wt_pop)) |>
    ungroup() |>
    mutate(epop = wt_emp / wt_pop)
}

# Long to published wide.
to_wide <- function(df, group_cols) {
  df |>
    select(all_of(group_cols), year, epop, si) |>
    pivot_wider(names_from = year,
                values_from = c(epop, si),
                names_glue   = "{.value}_{year}") |>
    mutate(
      dEP_99_18 = .data[[paste0("epop_", YEAR_END)]] -
                  .data[[paste0("epop_", YEAR_BASE)]],
      ds_99_18  = .data[[paste0("si_",  YEAR_END)]] -
                  .data[[paste0("si_",  YEAR_BASE)]]
    ) |>
    rename(
      `E/P_1999` = !!paste0("epop_", YEAR_BASE),
      `E/P_2018` = !!paste0("epop_", YEAR_END),
      dEP_99_18  = dEP_99_18,
      s_1999     = !!paste0("si_",   YEAR_BASE),
      s_2018     = !!paste0("si_",   YEAR_END),
      ds_99_18   = ds_99_18
    ) |>
    select(all_of(group_cols),
           `E/P_1999`, `E/P_2018`, dEP_99_18,
           s_1999, s_2018, ds_99_18)
}

# Strip prefix.
educgroup_to_display <- function(x) {
  x <- as.character(x)
  out <- recode(x,
                "1. Not In School" = "Not In School",
                "2. In School"     = "In School",
                "3. No HS"         = "Less than HS",
                "4. HS Grad"       = "HS",
                "5. Some Coll."    = "Some College",
                "6. Coll. Grad"    = "College")
  factor(out,
         levels = c("Not In School", "In School",
                    "Less than HS", "HS", "Some College", "College"))
}

# Assemble one table.
build_table1 <- function(df, gender_label) {
  src <- if (gender_label == "All") df else filter(df, sex == gender_label)

  by_age <- src |>
    epop_and_share(age_group_summary) |>
    to_wide(c("age_group_summary")) |>
    rename(age_group = age_group_summary) |>
    mutate(education = NA_character_, .after = age_group)

  by_age_educ <- src |>
    filter(!is.na(educgroup)) |>
    epop_and_share(age_group_summary, educgroup) |>
    to_wide(c("age_group_summary", "educgroup")) |>
    rename(age_group = age_group_summary) |>
    mutate(education = as.character(educgroup_to_display(educgroup))) |>
    select(-educgroup) |>
    relocate(education, .after = age_group)

  by_total <- src |>
    epop_and_share() |>
    to_wide(character(0)) |>
    mutate(age_group = "TOTAL", education = NA_character_, .before = 1)

  age_order <- AGE_LABELS_SUMM
  by_age      <- arrange(by_age,      factor(age_group, levels = age_order))
  by_age_educ <- arrange(by_age_educ, factor(age_group, levels = age_order),
                                       factor(education,
                                              levels = c("Not In School",
                                                         "In School",
                                                         "Less than HS",
                                                         "HS",
                                                         "Some College",
                                                         "College")))

  bind_rows(by_age, by_age_educ, by_total) |>
    mutate(across(c(`E/P_1999`, `E/P_2018`, dEP_99_18,
                    s_1999, s_2018, ds_99_18),
                  ~ as.numeric(.)))
}

tab_1a <- build_table1(analysis, "All")
tab_1b <- build_table1(analysis, "Male")
tab_1c <- build_table1(analysis, "Female")

write_csv(tab_1a, file.path(PATH_OUTPUT, "table_1a.csv"))
write_csv(tab_1b, file.path(PATH_OUTPUT, "table_1b.csv"))
write_csv(tab_1c, file.path(PATH_OUTPUT, "table_1c.csv"))

cat(sprintf("[03] Wrote table_1a.csv / 1b / 1c (%d rows each)\n",
            nrow(tab_1a)))

# Total share == 1.
walk2(list(tab_1a, tab_1b, tab_1c), c("1A", "1B", "1C"), \(t, lab) {
  tot <- t |> filter(age_group == "TOTAL")
  stopifnot(abs(tot$s_1999 - 1) < SHARE_TOL, abs(tot$s_2018 - 1) < SHARE_TOL)
  cat(sprintf("[03] Table %s TOTAL: ΔE/P = %+.4f (paper: -0.038 All, -0.053 M, -0.025 F)\n",
              lab, tot$dEP_99_18))
})
