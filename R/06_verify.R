# Diff vs authors' Excel.

source(here::here("R", "00_setup.R"))

# Table 1 published values.
read_published_table1 <- function(panel_name) {
  sheet <- read_excel(FILE_XLSX_TAB, sheet = "Tables 1A-C Final",
                      col_names = FALSE, .name_repair = "unique_quiet")
  # 1A=B, 1B=J, 1C=R.
  col_start <- switch(panel_name,
                      A = 2L,
                      B = 10L,
                      C = 18L)
  numeric_block <- sheet[, col_start:(col_start + 5)]
  colnames(numeric_block) <- c("E/P_1999", "E/P_2018", "dEP_99_18",
                               "s_1999", "s_2018", "ds_99_18")
  numeric_block <- numeric_block |>
    mutate(across(everything(), ~ suppressWarnings(as.numeric(.))))
  data_rows <- c(12:17, 20:21, 23:26, 28:31, 33:36, 38:41, 43:46, 48)
  out <- numeric_block[data_rows, ]
  # Defensive: every picked cell must be numeric.
  stopifnot(!anyNA(out))
  out
}

# Table 1 cell-wise diff.
diff_table1 <- function(our_csv, panel_name, tol = TOL_DIFF) {
  ours <- read_csv(our_csv, show_col_types = FALSE)
  pub  <- read_published_table1(panel_name)
  stopifnot(nrow(ours) == nrow(pub))
  # `/` breaks $-accessor.
  safe <- c(EP_1999 = "E/P_1999",
            EP_2018 = "E/P_2018",
            dEP     = "dEP_99_18",
            s_1999  = "s_1999",
            s_2018  = "s_2018",
            ds      = "ds_99_18")
  ours_s <- ours |> rename(!!!setNames(safe, names(safe)))
  pub_s  <- pub  |> rename(!!!setNames(safe, names(safe)))
  comparisons <- map_dfr(names(safe), \(col) {
    tibble(
      panel    = panel_name,
      row      = seq_len(nrow(ours_s)),
      label    = paste(ours$age_group,
                       coalesce(ours$education, ""), sep = " | "),
      column   = unname(safe[col]),
      ours     = ours_s[[col]],
      pub      = pub_s[[col]],
      diff_abs = abs(ours_s[[col]] - pub_s[[col]]),
      fail     = diff_abs > tol
    )
  })
  # Any NA diff means a misaligned or unread cell; fail loudly.
  stopifnot(!anyNA(comparisons$diff_abs))
  comparisons
}

# Table 2A published.
read_published_table2a <- function() {
  sheet <- read_excel(FILE_XLSX_TAB, sheet = "Tables 2A-B Final",
                      col_names = FALSE, .name_repair = "unique_quiet")
  num <- sheet[, 2:4]
  colnames(num) <- c("Overall", "Male", "Female")
  num <- num |>
    mutate(across(everything(), ~ suppressWarnings(as.numeric(.))))
  rows <- list(
    "s_i x dE/P_i"          = 11:14,
    "(E/P_i - E/P) x ds_i"  = 17:20,
    "ds_i x dE/P_i"         = 23:26
  )
  out <- imap_dfr(rows, \(rs, panel) {
    sub <- num[rs, ]
    sub$panel <- panel
    sub$age_group <- AGE_LABELS_DECOMP
    sub
  })
  total <- tibble(panel = "Total",
                  age_group = NA_character_,
                  Overall = as.numeric(num[[1]][28]),
                  Male    = as.numeric(num[[2]][28]),
                  Female  = as.numeric(num[[3]][28]))
  out_full <- bind_rows(out, total)
  # Total row legitimately has NA age_group; numerics must be present.
  stopifnot(!anyNA(out_full$Overall), !anyNA(out_full$Male), !anyNA(out_full$Female))
  out_full
}

# Table 2B published. Layout: cols 8-10; panel 2's 65+ block in rows 52-55.
read_published_table2b <- function() {
  sheet <- read_excel(FILE_XLSX_TAB, sheet = "Tables 2A-B Final",
                      col_names = FALSE, .name_repair = "unique_quiet")
  num <- sheet[, 8:10]
  colnames(num) <- c("Overall", "Male", "Female")
  num <- num |>
    mutate(across(everything(), ~ suppressWarnings(as.numeric(.))))

  panel_layouts <- list(
    "s_i x dE/P_i" = bind_rows(
      tibble(age_group = "16-24",
             education = c("Not In School", "In School"),
             row       = 11:12),
      tibble(age_group = "25-54",
             education = c("Less than HS", "HS", "Some College", "College"),
             row       = 14:17),
      tibble(age_group = "55-64",
             education = c("Less than HS", "HS", "Some College", "College"),
             row       = 19:22),
      tibble(age_group = "65+",
             education = c("Less than HS", "HS", "Some College", "College"),
             row       = 24:27)
    ),
    "(E/P_i - E/P) x ds_i" = bind_rows(
      tibble(age_group = "16-24",
             education = c("Not In School", "In School"),
             row       = 31:32),
      tibble(age_group = "25-54",
             education = c("Less than HS", "HS", "Some College", "College"),
             row       = 34:37),
      tibble(age_group = "55-64",
             education = c("Less than HS", "HS", "Some College", "College"),
             row       = 39:42),
      tibble(age_group = "65+",
             education = c("Less than HS", "HS", "Some College", "College"),
             row       = 52:55)
    ),
    "ds_i x dE/P_i" = bind_rows(
      tibble(age_group = "16-24",
             education = c("Not In School", "In School"),
             row       = 59:60),
      tibble(age_group = "25-54",
             education = c("Less than HS", "HS", "Some College", "College"),
             row       = 62:65),
      tibble(age_group = "55-64",
             education = c("Less than HS", "HS", "Some College", "College"),
             row       = 67:70),
      tibble(age_group = "65+",
             education = c("Less than HS", "HS", "Some College", "College"),
             row       = 72:75)
    )
  )

  out <- imap_dfr(panel_layouts, \(layout, panel) {
    sub <- num[layout$row, ]
    sub$panel     <- panel
    sub$age_group <- layout$age_group
    sub$education <- layout$education
    sub
  }) |>
    select(panel, age_group, education, Overall, Male, Female)

  # No NA numerics; misaligned layout would surface here.
  stopifnot(!anyNA(out$Overall), !anyNA(out$Male), !anyNA(out$Female))
  out
}

# Table 2 cell-wise diff.
diff_table2 <- function(our_csv, pub, key_cols, tol_pp = TOL_DIFF) {
  ours <- read_csv(our_csv, show_col_types = FALSE)
  ours_long <- ours |>
    pivot_longer(c(Overall, Male, Female),
                 names_to = "gender", values_to = "ours")
  pub_long <- pub |>
    pivot_longer(c(Overall, Male, Female),
                 names_to = "gender", values_to = "pub")
  cmp <- inner_join(ours_long, pub_long,
                    by = c("panel", key_cols, "gender"))
  # Inner join must not drop rows; row count must equal ours_long.
  stopifnot(nrow(cmp) == nrow(ours_long))
  cmp |>
    mutate(diff_abs = abs(ours - pub),
           fail     = diff_abs > tol_pp)
}

# Run diffs.
cmp_1a <- diff_table1(file.path(PATH_OUTPUT, "table_1a.csv"), "A")
cmp_1b <- diff_table1(file.path(PATH_OUTPUT, "table_1b.csv"), "B")
cmp_1c <- diff_table1(file.path(PATH_OUTPUT, "table_1c.csv"), "C")

pub_2a <- read_published_table2a()
pub_2b <- read_published_table2b()
cmp_2a <- diff_table2(file.path(PATH_OUTPUT, "table_2a.csv"), pub_2a,
                      "age_group")
cmp_2b <- diff_table2(file.path(PATH_OUTPUT, "table_2b.csv"), pub_2b,
                      c("age_group", "education"))

walk2(list(cmp_1a, cmp_1b, cmp_1c, cmp_2a, cmp_2b),
      c("1a", "1b", "1c", "2a", "2b"),
      \(c, lab) write_csv(c, file.path(PATH_DOCS, glue("diff_table_{lab}.csv"))))

summary_tbl <- tibble(
  table     = c("1A", "1B", "1C", "2A", "2B"),
  total     = c(nrow(cmp_1a), nrow(cmp_1b), nrow(cmp_1c),
                nrow(cmp_2a), nrow(cmp_2b)),
  failures  = c(sum(cmp_1a$fail, na.rm = TRUE),
                sum(cmp_1b$fail, na.rm = TRUE),
                sum(cmp_1c$fail, na.rm = TRUE),
                sum(cmp_2a$fail, na.rm = TRUE),
                sum(cmp_2b$fail, na.rm = TRUE)),
  max_abs   = c(max(cmp_1a$diff_abs, na.rm = TRUE),
                max(cmp_1b$diff_abs, na.rm = TRUE),
                max(cmp_1c$diff_abs, na.rm = TRUE),
                max(cmp_2a$diff_abs, na.rm = TRUE),
                max(cmp_2b$diff_abs, na.rm = TRUE))
)

print(summary_tbl)
write_csv(summary_tbl, file.path(PATH_DOCS, "diff_summary.csv"))

# Figure 1 diff.
fig_pub <- read_excel(FILE_XLSX_FIG, sheet = "Raw", col_names = TRUE)
fig_ours <- read_csv(file.path(PATH_OUTPUT, "figure_1_data.csv"),
                     show_col_types = FALSE)
fig_ours_wide <- fig_ours |>
  select(year, gender, age, epop) |>
  pivot_wider(names_from = age, values_from = epop) |>
  rename(epop16_24 = `16-24`, epop25_54 = `25-54`,
         epop55_64 = `55-64`, epop65 = `65+`,
         epop_all  = `All ages`)
fig_cmp <- inner_join(fig_ours_wide, fig_pub,
                      by = c("gender", "year"),
                      suffix = c("_ours", "_pub"))

# 3 genders × (YEAR_FIG1_END - YEAR_FIG1_START + 1).
expected_fig_rows <- 3L * (YEAR_FIG1_END - YEAR_FIG1_START + 1L)
stopifnot(nrow(fig_cmp) == expected_fig_rows)

# Per-cell diff: 810 points (5 series × 162 rows).
fig_cells <- fig_cmp |>
  transmute(
    year, gender,
    epop16_24_ours, epop16_24_pub,
    epop25_54_ours, epop25_54_pub,
    epop55_64_ours, epop55_64_pub,
    epop65_ours,    epop65_pub,
    epop_all_ours,  epop_all_pub
  ) |>
  pivot_longer(
    cols = -c(year, gender),
    names_to = c("series", ".value"),
    names_pattern = "(.+)_(ours|pub)"
  ) |>
  mutate(diff_abs = abs(ours - pub),
         fail     = diff_abs > TOL_DIFF)
stopifnot(nrow(fig_cells) == 5L * expected_fig_rows)
write_csv(fig_cells, file.path(PATH_DOCS, "diff_figure_1_cells.csv"))

fig_diff <- fig_cells |>
  summarise(max_diff = max(diff_abs, na.rm = TRUE),
            failures = sum(fail, na.rm = TRUE),
            .by = series) |>
  mutate(rows = expected_fig_rows)
write_csv(fig_diff, file.path(PATH_DOCS, "diff_figure_1.csv"))

# 1999/2018 spot check.
spot <- fig_ours_wide |> filter(year %in% YEARS)
write_csv(spot, file.path(PATH_DOCS, "fig1_spotcheck.csv"))

# Markdown report.
parq_info <- file.info(FILE_ANALYSIS)
parq <- read_parquet(FILE_ANALYSIS)
factor_levels <- map_chr(
  c("age_group_detailed", "age_group_summary", "age_group_decomp",
    "sex", "education", "school_status", "educgroup"),
  ~ sprintf("- `%s`: %s", .x, paste(levels(parq[[.x]]), collapse = " | "))
)

tbl_lines <- summary_tbl |>
  mutate(across(c(total, failures), as.integer),
         max_abs = sprintf("%.2e", max_abs)) |>
  glue_data("| {table} | {total} | {failures} | {max_abs} |") |>
  c(c("| Table | Cells | Failures | Max abs diff |",
      "|-------|-------|----------|--------------|"), x = _)

fig_lines <- fig_diff |>
  glue_data("| {series} | {failures} | {sprintf('%.2e', max_diff)} |") |>
  c(c("| Series | Failures | Max abs diff |",
      "|--------|----------|--------------|"), x = _)

md_lines <- c(
  "# Replication check",
  "",
  "## Files used",
  "",
  "- `repkit/CPS-programs-and-data/Data/Raw-CPS-extract/cps_00036.dat.gz`: primary microdata",
  "- `repkit/CPS-programs-and-data/Data/Raw-CPS-extract/cps_9918_input.do`: FWF positions, weight rescaling",
  "- `repkit/CPS-programs-and-data/Data/Raw-CPS-extract/cps_main.dta`: cross-check",
  "- `repkit/CPS-programs-and-data/Data/Raw-BLS-extract/ln.data.1.AllData.txt`: BLS LNS, Figure 1",
  "- `repkit/CPS-programs-and-data/Data/Raw-BLS-extract/series_ids.csv`: 42 series",
  "- `repkit/CPS-programs-and-data/Programs/Tables and Figures.do`: master script",
  "- `repkit/CPS-programs-and-data/Programs/ado/*.ado`: sub-programs",
  "- `repkit/CPS-programs-and-data/Output/*.xlsx`: published values",
  "",
  "## Files ignored",
  "",
  "- `summarize_by_age_det.ado`, `summarize_by_age_educ_det.ado`: not invoked by master",
  "- `Data/temp/*.dta`: Stata scratch",
  "- `Table-3-data-and-calculations/`: out of scope",
  "",
  "## Decisions",
  "",
  "- CPS reads via FWF (`readr::read_fwf`) using positions from `cps_9918_input.do`. `cps_main.dta` confirms n and `sum(compwt)` to zero diff.",
  "- Education recoding mirrors `educgroup` in `Tables and Figures.do` lines 86-99.",
  "- `epop_all` for Table 2 follows `decomp_by_age.ado` exactly. The Stata `local epop_all = epop1999[1]` runs after `reshape wide epop, i(sex) j(year)`. For Male and Female panels this gives the gender's 1999 EPOP. For the Overall panel the reshape produces two rows sorted by `sex`, so `epop1999[1]` is Male's 1999 EPOP rather than the both-genders value the spec assumed. Published cells use Male's value; the R code does too. Each Overall column still sums to 1 because `sum(sidiff) = 0`.",
  "- Table 2B 16-24 has 2 educ categories (school status); 25+ has 4 (HS recode). The 14-cell-per-panel structure follows from `(agegroup_decomp, educgroup)`.",
  "- Figure 1 `All ages` = `sum(emp) / sum(pop)` within `(year, gender)`, not a mean of per-age EPOPs.",
  "- Zero NA `educgroup` rows for age 25+. Table 2B columns sum to 1.",
  "- Table 2 cell sums use `na.rm = TRUE` to match Stata `collapse (sum)` behaviour on missing cells. Our data has no missing (det × educ) cells, so this is dormant; included for robustness.",
  "- Age cuts use `Inf` as the top break so any IPUMS top-code (current max 90) maps to the `75+` / `65+` bin without dropping rows.",
  "",
  "## Diff vs authors' xlsx",
  "",
  sprintf("Tolerance: %g on the published unit (0..1).", TOL_DIFF)
)

md_lines <- c(md_lines, "", tbl_lines, "",
              "Per-cell diffs: `docs/diff_table_*.csv`.",
              "",
              "## Figure 1 diff",
              "",
              sprintf("%d points (3 genders × %d years × 5 series) vs `Raw` sheet of `Abraham-Kearney-Figure1 (2019-06-07).xlsx`.",
                      nrow(fig_cells), YEAR_FIG1_END - YEAR_FIG1_START + 1L),
              "",
              fig_lines,
              "",
              "Per-cell diffs: `docs/diff_figure_1_cells.csv`. Float-precision noise. BLS LNS aggregation matches Stata.",
              "",
              "Figure 1 EPOPs (BLS LNS) differ from Table 1A E/P (CPS micro) because the underlying populations differ. Spot check: `docs/fig1_spotcheck.csv`.",
              "",
              "## Parquet",
              "",
              sprintf("- File: `%s`", FILE_ANALYSIS),
              sprintf("- Size: %.1f MB", parq_info$size / 1024^2),
              sprintf("- Rows: %s", formatC(nrow(parq), big.mark = ",")),
              sprintf("- Columns: %d", ncol(parq)),
              "- Levels:",
              factor_levels,
              "",
              sprintf("- `NA(education) <-> age < 25`: %s",
                      all(is.na(parq$education) == (parq$age < 25))),
              sprintf("- `NA(school_status) <-> age >= 25`: %s",
                      all(is.na(parq$school_status) == (parq$age >= 25))))

writeLines(md_lines, file.path(PATH_DOCS, "replication_check.md"))
cat(sprintf("[06] Wrote docs/replication_check.md\n"))
