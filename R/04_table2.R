source(here::here("R", "00_setup.R"))

analysis <- read_parquet(FILE_ANALYSIS)
cat("Loaded", nrow(analysis), "rows for Table 2.\n")

overall_epop <- function(d, yr) {
  rows <- d[d$year == yr, ]
  sum(rows$employed * rows$weight) / sum(rows$weight)
}

edu_display <- function(x) {
  recode(as.character(x),
         "1. Not In School" = "Not In School",
         "2. In School" = "In School",
         "3. No HS" = "Less than HS",
         "4. HS Grad" = "HS",
         "5. Some Coll." = "Some College",
         "6. Coll. Grad" = "College")
}

panel_2a <- function(all_data, gender) {
  if (gender == "All") d <- all_data else d <- filter(all_data, sex == gender)
  dEP <- overall_epop(d, 2018) - overall_epop(d, 1999)
  if (gender == "Female") {
    center <- overall_epop(filter(all_data, sex == "Female"), 1999)
  } else {
    center <- overall_epop(filter(all_data, sex == "Male"), 1999)
  }
  cells <- d |>
    group_by(year, age_group_detailed, age_group_decomp) |>
    summarise(emp = sum(employed * weight), pop = sum(weight), .groups = "drop") |>
    group_by(year) |>
    mutate(si = pop / sum(pop)) |>
    ungroup() |>
    mutate(epop = emp / pop) |>
    select(age_group_detailed, age_group_decomp, year, epop, si) |>
    pivot_wider(names_from = year, values_from = c(epop, si)) |>
    mutate(
      term1 = si_1999 * (epop_2018 - epop_1999),
      term2 = (si_2018 - si_1999) * (epop_1999 - center),
      term3 = (si_2018 - si_1999) * (epop_2018 - epop_1999)
    )
  cells |>
    group_by(age_group_decomp) |>
    summarise(term1 = sum(term1, na.rm = TRUE) / dEP,
              term2 = sum(term2, na.rm = TRUE) / dEP,
              term3 = sum(term3, na.rm = TRUE) / dEP,
              .groups = "drop") |>
    arrange(age_group_decomp)
}

panel_2b <- function(all_data, gender) {
  if (gender == "All") d <- all_data else d <- filter(all_data, sex == gender)
  dEP <- overall_epop(d, 2018) - overall_epop(d, 1999)
  if (gender == "Female") {
    center <- overall_epop(filter(all_data, sex == "Female"), 1999)
  } else {
    center <- overall_epop(filter(all_data, sex == "Male"), 1999)
  }
  cells <- d |>
    filter(!is.na(educgroup)) |>
    group_by(year, age_group_detailed, age_group_decomp, educgroup) |>
    summarise(emp = sum(employed * weight), pop = sum(weight), .groups = "drop") |>
    group_by(year) |>
    mutate(si = pop / sum(pop)) |>
    ungroup() |>
    mutate(epop = emp / pop) |>
    select(age_group_detailed, age_group_decomp, educgroup, year, epop, si) |>
    pivot_wider(names_from = year, values_from = c(epop, si)) |>
    mutate(
      term1 = si_1999 * (epop_2018 - epop_1999),
      term2 = (si_2018 - si_1999) * (epop_1999 - center),
      term3 = (si_2018 - si_1999) * (epop_2018 - epop_1999)
    )
  cells |>
    group_by(age_group_decomp, educgroup) |>
    summarise(term1 = sum(term1, na.rm = TRUE) / dEP,
              term2 = sum(term2, na.rm = TRUE) / dEP,
              term3 = sum(term3, na.rm = TRUE) / dEP,
              .groups = "drop")
}

panel_names <- c("s_i x dE/P_i", "(E/P_i - E/P) x ds_i", "ds_i x dE/P_i")
term_names <- c("term1", "term2", "term3")

a_all <- panel_2a(analysis, "All")
a_male <- panel_2a(analysis, "Male")
a_female <- panel_2a(analysis, "Female")

tab_2a <- tibble()
for (i in 1:3) {
  tm <- term_names[i]
  for (ag in AGE_LABELS_DECOMP) {
    tab_2a <- bind_rows(tab_2a, tibble(
      panel = panel_names[i],
      age_group = ag,
      Overall = a_all[[tm]][as.character(a_all$age_group_decomp) == ag],
      Male = a_male[[tm]][as.character(a_male$age_group_decomp) == ag],
      Female = a_female[[tm]][as.character(a_female$age_group_decomp) == ag]
    ))
  }
}
tab_2a <- bind_rows(tab_2a, tibble(panel = "Total", age_group = NA_character_,
                                   Overall = 1, Male = 1, Female = 1))

b_all <- panel_2b(analysis, "All")
b_male <- panel_2b(analysis, "Male")
b_female <- panel_2b(analysis, "Female")

tab_2b <- tibble()
for (i in 1:3) {
  tm <- term_names[i]
  for (r in 1:nrow(b_all)) {
    ag <- as.character(b_all$age_group_decomp[r])
    eg <- as.character(b_all$educgroup[r])
    m <- which(as.character(b_male$age_group_decomp) == ag & as.character(b_male$educgroup) == eg)
    f <- which(as.character(b_female$age_group_decomp) == ag & as.character(b_female$educgroup) == eg)
    tab_2b <- bind_rows(tab_2b, tibble(
      panel = panel_names[i],
      age_group = ag,
      education = edu_display(eg),
      Overall = b_all[[tm]][r],
      Male = b_male[[tm]][m],
      Female = b_female[[tm]][f]
    ))
  }
}

write_csv(tab_2a, file.path(PATH_OUTPUT, "table_2a.csv"))
write_csv(tab_2b, file.path(PATH_OUTPUT, "table_2b.csv"))
cat("Wrote table_2a (", nrow(tab_2a), "rows) and table_2b (", nrow(tab_2b), "rows).\n")
cat("Table 2A Overall column sum:", round(sum(tab_2a$Overall[tab_2a$panel != "Total"]), 4), "\n")
cat("Table 2B Overall column sum:", round(sum(tab_2b$Overall), 4), "\n")
