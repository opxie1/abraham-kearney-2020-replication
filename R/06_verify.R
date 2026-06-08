source(here::here("R", "00_setup.R"))

TOL <- 0.001
value_cols <- c("E/P_1999", "E/P_2018", "dEP_99_18", "s_1999", "s_2018", "ds_99_18")

read_pub_table1 <- function(panel) {
  sheet <- read_excel(FILE_XLSX_TAB, sheet = "Tables 1A-C Final",
                      col_names = FALSE, .name_repair = "unique_quiet")
  col_start <- switch(panel, A = 2, B = 10, C = 18)
  block <- sheet[, col_start:(col_start + 5)]
  names(block) <- value_cols
  for (cc in value_cols) block[[cc]] <- suppressWarnings(as.numeric(block[[cc]]))
  rows <- c(12:17, 20:21, 23:26, 28:31, 33:36, 38:41, 43:46, 48)
  block[rows, ]
}

diff_table1 <- function(csv, panel) {
  ours <- read_csv(csv, show_col_types = FALSE)
  pub <- read_pub_table1(panel)
  out <- tibble()
  for (cc in value_cols) {
    d <- abs(ours[[cc]] - pub[[cc]])
    out <- bind_rows(out, tibble(table = panel, column = cc,
                                 ours = ours[[cc]], pub = pub[[cc]],
                                 diff_abs = d, fail = d > TOL))
  }
  out
}

read_pub_table2a <- function() {
  sheet <- read_excel(FILE_XLSX_TAB, sheet = "Tables 2A-B Final",
                      col_names = FALSE, .name_repair = "unique_quiet")
  num <- sheet[, 2:4]
  names(num) <- c("Overall", "Male", "Female")
  for (cc in names(num)) num[[cc]] <- suppressWarnings(as.numeric(num[[cc]]))
  panels <- list("s_i x dE/P_i" = 11:14,
                 "(E/P_i - E/P) x ds_i" = 17:20,
                 "ds_i x dE/P_i" = 23:26)
  out <- tibble()
  for (p in names(panels)) {
    sub <- num[panels[[p]], ]
    sub$panel <- p
    sub$age_group <- AGE_LABELS_DECOMP
    out <- bind_rows(out, sub)
  }
  bind_rows(out, tibble(panel = "Total", age_group = NA_character_,
                        Overall = as.numeric(num[[1]][28]),
                        Male = as.numeric(num[[2]][28]),
                        Female = as.numeric(num[[3]][28])))
}

read_pub_table2b <- function() {
  sheet <- read_excel(FILE_XLSX_TAB, sheet = "Tables 2A-B Final",
                      col_names = FALSE, .name_repair = "unique_quiet")
  num <- sheet[, 8:10]
  names(num) <- c("Overall", "Male", "Female")
  for (cc in names(num)) num[[cc]] <- suppressWarnings(as.numeric(num[[cc]]))
  ages <- c("16-24", "16-24", "25-54", "25-54", "25-54", "25-54",
            "55-64", "55-64", "55-64", "55-64", "65+", "65+", "65+", "65+")
  edus <- c("Not In School", "In School",
            "Less than HS", "HS", "Some College", "College",
            "Less than HS", "HS", "Some College", "College",
            "Less than HS", "HS", "Some College", "College")
  panel_rows <- list("s_i x dE/P_i" = c(11:12, 14:17, 19:22, 24:27),
                     "(E/P_i - E/P) x ds_i" = c(31:32, 34:37, 39:42, 52:55),
                     "ds_i x dE/P_i" = c(59:60, 62:65, 67:70, 72:75))
  out <- tibble()
  for (p in names(panel_rows)) {
    sub <- num[panel_rows[[p]], ]
    sub$panel <- p
    sub$age_group <- ages
    sub$education <- edus
    out <- bind_rows(out, sub)
  }
  select(out, panel, age_group, education, Overall, Male, Female)
}

diff_table2 <- function(csv, pub, key_cols) {
  ours <- read_csv(csv, show_col_types = FALSE)
  ours_long <- pivot_longer(ours, c(Overall, Male, Female), names_to = "gender", values_to = "ours")
  pub_long <- pivot_longer(pub, c(Overall, Male, Female), names_to = "gender", values_to = "pub")
  cmp <- inner_join(ours_long, pub_long, by = c("panel", key_cols, "gender"))
  cmp$diff_abs <- abs(cmp$ours - cmp$pub)
  cmp$fail <- cmp$diff_abs > TOL
  cmp
}

read_pub_table3 <- function() {
  s <- read_excel(FILE_T3_SUMMARY, sheet = "calculations 2018",
                  col_names = FALSE, .name_repair = "unique_quiet")
  tibble(
    factor = c("Import competition from China",
               "Adoption of industrial robots",
               "Increased receipt of disability benefits (SSDI, VADC)",
               "Higher minimum wages",
               "Increased rate of incarceration"),
    pub_pp = c(as.numeric(s[[5]][8]), as.numeric(s[[5]][9]), as.numeric(s[[5]][13]),
               0.10, as.numeric(s[[5]][15])),
    paper = c(0.92, 0.43, 0.17, 0.10, 0.12)
  )
}

diff_table3 <- function(csv) {
  ours <- read_csv(csv, show_col_types = FALSE)
  pub <- read_pub_table3()
  cmp <- inner_join(ours, pub, by = "factor")
  cmp$ours_pp <- cmp$epop_pp_computed
  cmp$pp_diff <- abs(cmp$ours_pp - cmp$pub_pp)
  cmp$paper_ok <- round(cmp$ours_pp, 2) == cmp$paper
  cmp$fail <- cmp$pp_diff > TOL | !cmp$paper_ok
  select(cmp, factor, ours_pp, pub_pp, pp_diff, paper, fail)
}

cmp_1a <- diff_table1(file.path(PATH_OUTPUT, "table_1a.csv"), "A")
cmp_1b <- diff_table1(file.path(PATH_OUTPUT, "table_1b.csv"), "B")
cmp_1c <- diff_table1(file.path(PATH_OUTPUT, "table_1c.csv"), "C")
cmp_2a <- diff_table2(file.path(PATH_OUTPUT, "table_2a.csv"), read_pub_table2a(), "age_group")
cmp_2b <- diff_table2(file.path(PATH_OUTPUT, "table_2b.csv"), read_pub_table2b(), c("age_group", "education"))

write_csv(cmp_1a, file.path(PATH_DOCS, "diff_table_1a.csv"))
write_csv(cmp_1b, file.path(PATH_DOCS, "diff_table_1b.csv"))
write_csv(cmp_1c, file.path(PATH_DOCS, "diff_table_1c.csv"))
write_csv(cmp_2a, file.path(PATH_DOCS, "diff_table_2a.csv"))
write_csv(cmp_2b, file.path(PATH_DOCS, "diff_table_2b.csv"))

summary_tbl <- tibble(
  table = c("1A", "1B", "1C", "2A", "2B"),
  cells = c(nrow(cmp_1a), nrow(cmp_1b), nrow(cmp_1c), nrow(cmp_2a), nrow(cmp_2b)),
  failures = c(sum(cmp_1a$fail), sum(cmp_1b$fail), sum(cmp_1c$fail),
               sum(cmp_2a$fail), sum(cmp_2b$fail)),
  max_abs = c(max(cmp_1a$diff_abs), max(cmp_1b$diff_abs), max(cmp_1c$diff_abs),
              max(cmp_2a$diff_abs), max(cmp_2b$diff_abs))
)
print(summary_tbl)
write_csv(summary_tbl, file.path(PATH_DOCS, "diff_summary.csv"))

fig_pub <- read_excel(FILE_XLSX_FIG, sheet = "Raw", col_names = TRUE)
fig_ours <- read_csv(file.path(PATH_OUTPUT, "figure_1_data.csv"), show_col_types = FALSE)
fig_wide <- fig_ours |>
  select(year, gender, age, epop) |>
  pivot_wider(names_from = age, values_from = epop) |>
  rename(epop16_24 = `16-24`, epop25_54 = `25-54`, epop55_64 = `55-64`,
         epop65 = `65+`, epop_all = `All ages`)
fig_cmp <- inner_join(fig_wide, fig_pub, by = c("gender", "year"), suffix = c("_ours", "_pub"))

series <- c("epop16_24", "epop25_54", "epop55_64", "epop65", "epop_all")
fig_cells <- tibble()
for (s in series) {
  o <- fig_cmp[[paste0(s, "_ours")]]
  p <- fig_cmp[[paste0(s, "_pub")]]
  d <- abs(o - p)
  fig_cells <- bind_rows(fig_cells, tibble(series = s, year = fig_cmp$year, gender = fig_cmp$gender,
                                           ours = o, pub = p, diff_abs = d, fail = d > TOL))
}
write_csv(fig_cells, file.path(PATH_DOCS, "diff_figure_1_cells.csv"))

fig_diff <- fig_cells |>
  group_by(series) |>
  summarise(failures = sum(fail), max_diff = max(diff_abs), .groups = "drop")
write_csv(fig_diff, file.path(PATH_DOCS, "diff_figure_1.csv"))

spot <- filter(fig_wide, year %in% YEARS)
write_csv(spot, file.path(PATH_DOCS, "fig1_spotcheck.csv"))

cmp_3 <- diff_table3(file.path(PATH_OUTPUT, "table_3.csv"))
write_csv(cmp_3, file.path(PATH_DOCS, "diff_table_3.csv"))

ssdi_x <- read_excel(FILE_T3_SSDI, sheet = "SSDI effects", col_names = FALSE, .name_repair = "unique_quiet")
vadc_x <- read_excel(FILE_T3_VADC, sheet = "VADC effects", col_names = FALSE, .name_repair = "unique_quiet")
inc_x <- read_excel(FILE_T3_INC, sheet = "Incarceration", col_names = FALSE, .name_repair = "unique_quiet")
pub_disability <- as.numeric(ssdi_x[[11]][23]) + as.numeric(vadc_x[[5]][27])
pub_inc <- abs(as.numeric(inc_x[[5]][36]))

ours_t3 <- read_csv(file.path(PATH_OUTPUT, "table_3.csv"), show_col_types = FALSE)
ours_disability <- ours_t3$jobs_affected[ours_t3$factor == "Increased receipt of disability benefits (SSDI, VADC)"]
ours_inc <- ours_t3$jobs_affected[ours_t3$factor == "Increased rate of incarceration"]

inter_cmp <- tibble(
  intermediate = c("Disability (SSDI + VADC)", "Incarceration"),
  ours = c(ours_disability, ours_inc),
  pub = c(pub_disability, pub_inc),
  diff_abs = abs(c(ours_disability, ours_inc) - c(pub_disability, pub_inc))
)
write_csv(inter_cmp, file.path(PATH_DOCS, "diff_table_3_intermediates.csv"))

parq <- read_parquet(FILE_ANALYSIS)
parq_size <- file.info(FILE_ANALYSIS)$size / 1024^2

md <- c("# Replication check", "",
        "## Tables vs the authors' spreadsheets", "",
        sprintf("Tolerance: %g.", TOL), "",
        "| Table | Cells | Failures | Max abs diff |",
        "|-------|-------|----------|--------------|")
for (i in 1:nrow(summary_tbl)) {
  md <- c(md, sprintf("| %s | %d | %d | %.2e |",
                      summary_tbl$table[i], summary_tbl$cells[i],
                      summary_tbl$failures[i], summary_tbl$max_abs[i]))
}
md <- c(md, "", "## Figure 1 vs the authors' spreadsheet", "",
        "| Series | Failures | Max abs diff |",
        "|--------|----------|--------------|")
for (i in 1:nrow(fig_diff)) {
  md <- c(md, sprintf("| %s | %d | %.2e |",
                      fig_diff$series[i], fig_diff$failures[i], fig_diff$max_diff[i]))
}
md <- c(md, "", "## Table 3", "",
        "| Factor | Computed | Workbook | Diff | Paper | Status |",
        "|--------|----------|----------|------|-------|--------|")
for (i in 1:nrow(cmp_3)) {
  md <- c(md, sprintf("| %s | %.4f | %.4f | %.2e | %.2f | %s |",
                      cmp_3$factor[i], cmp_3$ours_pp[i], cmp_3$pub_pp[i],
                      cmp_3$pp_diff[i], cmp_3$paper[i],
                      if (cmp_3$fail[i]) "FAIL" else "PASS"))
}
md <- c(md, "",
        sprintf("Disability jobs: ours %.1f, workbook %.1f (diff %.2e).",
                inter_cmp$ours[1], inter_cmp$pub[1], inter_cmp$diff_abs[1]),
        sprintf("Incarceration jobs: ours %.1f, workbook %.1f (diff %.2e).",
                inter_cmp$ours[2], inter_cmp$pub[2], inter_cmp$diff_abs[2]),
        "", "## Parquet", "",
        sprintf("Rows: %s, columns: %d, size: %.1f MB.",
                formatC(nrow(parq), big.mark = ","), ncol(parq), parq_size),
        "", "Variable labels:", "")
for (col in names(parq)) {
  lbl <- attr(parq[[col]], "label")
  if (is.null(lbl) || !nzchar(lbl)) stop(paste("Missing variable label for", col))
  md <- c(md, sprintf("- %s: %s", col, lbl))
}
writeLines(md, file.path(PATH_DOCS, "replication_check.md"))
cat("Wrote docs/replication_check.md\n")

total_failures <- sum(summary_tbl$failures) + sum(fig_diff$failures) + sum(cmp_3$fail)
cat("\nAll checks done. Total failures across everything:", total_failures, "\n")
