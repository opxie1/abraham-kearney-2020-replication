source(here::here("R", "00_setup.R"))

analysis <- read_parquet(FILE_ANALYSIS)

cell_stats <- function(df, ...) {
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
    mutate(epop = wt_emp / wt_pop) |>
    select(year, !!!group_cols, epop, si)
}

overall_epop <- function(df) {
  df |>
    summarise(epop = sum(employed * weight) / sum(weight),
              .by = year) |>
    arrange(year) |>
    deframe()
}

epop_centring_1999 <- function(df, gender_label) {
  sub <- if (gender_label %in% c("Male", "Female"))
    filter(df, sex == gender_label)
  else
    filter(df, sex == "Male")
  sum(sub$employed[sub$year == YEAR_BASE] *
      sub$weight[sub$year == YEAR_BASE]) /
    sum(sub$weight[sub$year == YEAR_BASE])
}

build_table2a_panel <- function(df, gender_label) {
  src <- if (gender_label == "All") df else filter(df, sex == gender_label)
  ep_all <- overall_epop(src)
  ep1999_for_term2 <- epop_centring_1999(df, gender_label)
  dEP_total <- ep_all[as.character(YEAR_END)] -
               ep_all[as.character(YEAR_BASE)]

  by_det <- src |>
    cell_stats(age_group_detailed, age_group_decomp) |>
    pivot_wider(names_from = year, values_from = c(epop, si)) |>
    mutate(
      epopdiff = .data[[paste0("epop_", YEAR_END)]] -
                 .data[[paste0("epop_", YEAR_BASE)]],
      sidiff   = .data[[paste0("si_",   YEAR_END)]] -
                 .data[[paste0("si_",   YEAR_BASE)]],
      term1 = .data[[paste0("si_",   YEAR_BASE)]] * epopdiff,
      term2 = sidiff *
              (.data[[paste0("epop_", YEAR_BASE)]] - ep1999_for_term2),
      term3 = sidiff * epopdiff
    )

  by_det |>
    summarise(
      term1 = sum(term1, na.rm = TRUE),
      term2 = sum(term2, na.rm = TRUE),
      term3 = sum(term3, na.rm = TRUE),
      .by   = age_group_decomp
    ) |>
    mutate(across(c(term1, term2, term3), ~ . / dEP_total)) |>
    arrange(age_group_decomp) |>
    rename(age_group = age_group_decomp) |>
    mutate(age_group = as.character(age_group))
}

build_table2a <- function(df) {
  panels <- map(c("All", "Male", "Female"),
                ~ build_table2a_panel(df, .x) |> rename_with(
                    \(c) ifelse(c %in% c("term1", "term2", "term3"),
                                paste0(c, "_", .x), c)))
  panels[[1]] |>
    inner_join(panels[[2]], by = "age_group") |>
    inner_join(panels[[3]], by = "age_group") |>
    pivot_longer(-age_group,
                 names_to = c("term", "gender"),
                 names_sep = "_") |>
    pivot_wider(names_from = gender, values_from = value) |>
    mutate(
      panel = recode(term,
                     term1 = "s_i x dE/P_i",
                     term2 = "(E/P_i - E/P) x ds_i",
                     term3 = "ds_i x dE/P_i"),
      panel = factor(panel,
                     levels = c("s_i x dE/P_i",
                                "(E/P_i - E/P) x ds_i",
                                "ds_i x dE/P_i"))
    ) |>
    arrange(panel, factor(age_group, levels = AGE_LABELS_DECOMP)) |>
    select(panel, age_group, Overall = All, Male, Female) |>
    bind_rows(
      tibble(panel = factor("Total",
                            levels = c("s_i x dE/P_i",
                                       "(E/P_i - E/P) x ds_i",
                                       "ds_i x dE/P_i", "Total")),
             age_group = NA_character_,
             Overall = 1, Male = 1, Female = 1)
    )
}

build_table2b_panel <- function(df, gender_label) {
  src <- if (gender_label == "All") df else filter(df, sex == gender_label)
  src <- filter(src, !is.na(educgroup))

  ep_all <- overall_epop(if (gender_label == "All") df
                         else filter(df, sex == gender_label))
  ep1999_for_term2 <- epop_centring_1999(df, gender_label)
  dEP_total <- ep_all[as.character(YEAR_END)] -
               ep_all[as.character(YEAR_BASE)]

  by_det_educ <- src |>
    cell_stats(age_group_detailed, age_group_decomp, educgroup) |>
    pivot_wider(names_from = year, values_from = c(epop, si)) |>
    mutate(
      epopdiff = .data[[paste0("epop_", YEAR_END)]] -
                 .data[[paste0("epop_", YEAR_BASE)]],
      sidiff   = .data[[paste0("si_",   YEAR_END)]] -
                 .data[[paste0("si_",   YEAR_BASE)]],
      term1 = .data[[paste0("si_",   YEAR_BASE)]] * epopdiff,
      term2 = sidiff *
              (.data[[paste0("epop_", YEAR_BASE)]] - ep1999_for_term2),
      term3 = sidiff * epopdiff
    )

  by_det_educ |>
    summarise(
      term1 = sum(term1, na.rm = TRUE),
      term2 = sum(term2, na.rm = TRUE),
      term3 = sum(term3, na.rm = TRUE),
      .by   = c(age_group_decomp, educgroup)
    ) |>
    mutate(across(c(term1, term2, term3), ~ . / dEP_total)) |>
    rename(age_group = age_group_decomp)
}

build_table2b <- function(df) {
  panels <- map(c("All", "Male", "Female"),
                ~ build_table2b_panel(df, .x) |> rename_with(
                    \(c) ifelse(c %in% c("term1", "term2", "term3"),
                                paste0(c, "_", .x), c)))
  combined <- panels[[1]] |>
    inner_join(panels[[2]], by = c("age_group", "educgroup")) |>
    inner_join(panels[[3]], by = c("age_group", "educgroup"))

  long <- combined |>
    pivot_longer(starts_with("term"),
                 names_to = c("term", "gender"),
                 names_sep = "_") |>
    pivot_wider(names_from = gender, values_from = value) |>
    mutate(
      panel = recode(term,
                     term1 = "s_i x dE/P_i",
                     term2 = "(E/P_i - E/P) x ds_i",
                     term3 = "ds_i x dE/P_i"),
      panel = factor(panel,
                     levels = c("s_i x dE/P_i",
                                "(E/P_i - E/P) x ds_i",
                                "ds_i x dE/P_i"))
    )

  display_levels <- c("Not In School", "In School",
                      "Less than HS", "HS", "Some College", "College")
  long |>
    mutate(
      education = recode(as.character(educgroup),
                         "1. Not In School" = "Not In School",
                         "2. In School"     = "In School",
                         "3. No HS"         = "Less than HS",
                         "4. HS Grad"       = "HS",
                         "5. Some Coll."    = "Some College",
                         "6. Coll. Grad"    = "College"),
      education = factor(education, levels = display_levels)
    ) |>
    arrange(panel,
            factor(age_group, levels = AGE_LABELS_DECOMP),
            education) |>
    mutate(age_group = as.character(age_group),
           education = as.character(education)) |>
    select(panel, age_group, education,
           Overall = All, Male, Female)
}

tab_2a <- build_table2a(analysis)
tab_2b <- build_table2b(analysis)

write_csv(tab_2a, file.path(PATH_OUTPUT, "table_2a.csv"))
write_csv(tab_2b, file.path(PATH_OUTPUT, "table_2b.csv"))

cat(sprintf("[04] Wrote table_2a.csv (%d rows) and table_2b.csv (%d rows)\n",
            nrow(tab_2a), nrow(tab_2b)))

walk(c("Overall", "Male", "Female"), \(col) {
  s2a <- tab_2a |>
    filter(panel != "Total") |>
    pull(.data[[col]]) |>
    sum()
  s2b <- tab_2b |>
    pull(.data[[col]]) |>
    sum()
  stopifnot(abs(s2a - 1) < SHARE_TOL, abs(s2b - 1) < SHARE_TOL)
  cat(sprintf("[04] Table 2A col %-7s sum = %.6f | Table 2B sum = %.6f\n",
              col, s2a, s2b))
})
