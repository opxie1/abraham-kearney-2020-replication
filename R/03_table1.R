source(here::here("R", "00_setup.R"))

analysis <- read_parquet(FILE_ANALYSIS)
cat("Loaded", nrow(analysis), "rows for Table 1.\n")

edu_order <- c("Not In School", "In School", "Less than HS", "HS", "Some College", "College")

edu_display <- function(x) {
  recode(as.character(x),
         "1. Not In School" = "Not In School",
         "2. In School" = "In School",
         "3. No HS" = "Less than HS",
         "4. HS Grad" = "HS",
         "5. Some Coll." = "Some College",
         "6. Coll. Grad" = "College")
}

build_table1 <- function(d) {
  by_age <- d |>
    group_by(year, age_group_summary) |>
    summarise(emp = sum(employed * weight), pop = sum(weight), .groups = "drop") |>
    group_by(year) |>
    mutate(share = pop / sum(pop)) |>
    ungroup() |>
    mutate(epop = emp / pop) |>
    select(age_group_summary, year, epop, share) |>
    pivot_wider(names_from = year, values_from = c(epop, share))

  age_rows <- tibble(
    age_group = as.character(by_age$age_group_summary),
    education = NA_character_,
    `E/P_1999` = by_age$epop_1999,
    `E/P_2018` = by_age$epop_2018,
    dEP_99_18 = by_age$epop_2018 - by_age$epop_1999,
    s_1999 = by_age$share_1999,
    s_2018 = by_age$share_2018,
    ds_99_18 = by_age$share_2018 - by_age$share_1999
  )
  age_rows <- age_rows[order(match(age_rows$age_group, AGE_LABELS_SUMM)), ]

  by_edu <- d |>
    filter(!is.na(educgroup)) |>
    group_by(year, age_group_summary, educgroup) |>
    summarise(emp = sum(employed * weight), pop = sum(weight), .groups = "drop") |>
    group_by(year) |>
    mutate(share = pop / sum(pop)) |>
    ungroup() |>
    mutate(epop = emp / pop) |>
    select(age_group_summary, educgroup, year, epop, share) |>
    pivot_wider(names_from = year, values_from = c(epop, share))

  edu_rows <- tibble(
    age_group = as.character(by_edu$age_group_summary),
    education = edu_display(by_edu$educgroup),
    `E/P_1999` = by_edu$epop_1999,
    `E/P_2018` = by_edu$epop_2018,
    dEP_99_18 = by_edu$epop_2018 - by_edu$epop_1999,
    s_1999 = by_edu$share_1999,
    s_2018 = by_edu$share_2018,
    ds_99_18 = by_edu$share_2018 - by_edu$share_1999
  )
  edu_rows <- edu_rows[order(match(edu_rows$age_group, AGE_LABELS_SUMM),
                             match(edu_rows$education, edu_order)), ]

  total <- d |>
    group_by(year) |>
    summarise(emp = sum(employed * weight), pop = sum(weight), .groups = "drop") |>
    mutate(epop = emp / pop) |>
    select(year, epop) |>
    pivot_wider(names_from = year, values_from = epop, names_prefix = "epop_")

  total_row <- tibble(
    age_group = "TOTAL",
    education = NA_character_,
    `E/P_1999` = total$epop_1999,
    `E/P_2018` = total$epop_2018,
    dEP_99_18 = total$epop_2018 - total$epop_1999,
    s_1999 = 1,
    s_2018 = 1,
    ds_99_18 = 0
  )

  bind_rows(age_rows, edu_rows, total_row)
}

tab_1a <- build_table1(analysis)
tab_1b <- build_table1(filter(analysis, sex == "Male"))
tab_1c <- build_table1(filter(analysis, sex == "Female"))

write_csv(tab_1a, file.path(PATH_OUTPUT, "table_1a.csv"))
write_csv(tab_1b, file.path(PATH_OUTPUT, "table_1b.csv"))
write_csv(tab_1c, file.path(PATH_OUTPUT, "table_1c.csv"))

cat("Wrote table_1a, 1b, 1c (", nrow(tab_1a), "rows each).\n")
cat("Overall E/P change  All:", round(tab_1a$dEP_99_18[tab_1a$age_group == "TOTAL"], 4),
    " Male:", round(tab_1b$dEP_99_18[tab_1b$age_group == "TOTAL"], 4),
    " Female:", round(tab_1c$dEP_99_18[tab_1c$age_group == "TOTAL"], 4), "\n")
