source(here::here("R", "00_setup.R"))

EMP_2018  <- 155761000L
POP_2018  <- 257791000L
EPOP_2018 <- 100 * EMP_2018 / POP_2018

pp_from_jobs <- function(jobs) 100 * jobs / POP_2018

jobs_china <- 2370000

robots_1999   <- 79959
robots_2018   <- 279683
jobs_per_robot <- 5.6
jobs_robots   <- (robots_2018 - robots_1999) * jobs_per_robot

ssdi <- tibble(
  caseload_2018 = c(132.631, 589.422, 503.437, 763.631,
                    1228.959, 2095.526, 3227.601) * 1000,
  pop_2018      = c(52088932.2392, 42776598.7096, 19426102.9369, 20496775.8233,
                    20730951.6824, 21679796.7603, 27600163.3505),
  share_1999    = c(0.003084749971103774, 0.014399147222374063, 0.025210144375159983,
                    0.03534822490718291,  0.05100146981302061,  0.0765506271562933,
                    0.08930626749906115),
  elasticity    = c(0.336, 0.369, 0.355, 0.355, 0.29, 0.29, 0.105)
) |>
  mutate(predicted = share_1999 * pop_2018,
         excess    = caseload_2018 - predicted,
         workers   = excess * elasticity)
jobs_ssdi <- sum(ssdi$workers)

vadc <- tibble(
  num_2018   = c(578371, 1434440, 2130807),
  pop_2018   = c(82584989.2502, 81797040.9248, 72452114.888),
  num_1999   = c(80897, 1181658, 828236),
  pop_1999   = c(52346371.0798, 112606144.5849, 35202792.1143),
  elasticity = c(0.09, 0.18, 0.09)
) |>
  mutate(share_1999 = num_1999 / pop_1999,
         projected  = pop_2018 * share_1999,
         excess     = num_2018 - projected,
         workers    = excess * elasticity)
jobs_vadc       <- sum(vadc$workers)
jobs_disability <- jobs_ssdi + jobs_vadc

pp_minwage <- 0.10

ms_low_1yr  <- -0.09; ms_low_2yr  <- -0.11
ms_high_1yr <- -0.24; ms_high_2yr <- -0.39
share_low   <- 228499 / (92526 + 228499 + 70048)
share_high  <-  70048 / (92526 + 228499 + 70048)
former_prisoners <- mean(c(6100000, 6900000))
nlsy_share_13_24 <- 0.24
nlsy_share_24plus <- 0.416
policy_share     <- 0.6
count_1yr <- nlsy_share_13_24  * former_prisoners * policy_share
count_2yr <- nlsy_share_24plus * former_prisoners * policy_share
jobs_incarceration <- -(
  share_low  * count_1yr * ms_low_1yr  +
  share_low  * count_2yr * ms_low_2yr  +
  share_high * count_1yr * ms_high_1yr +
  share_high * count_2yr * ms_high_2yr
)

mk <- function(category, factor, jobs = NA_real_, pp = NA_real_,
               published, source = NA_character_)
  tibble(category, factor, jobs_affected = jobs,
         epop_pp_computed = pp, epop_pp_published = published, source)

table3 <- bind_rows(
  mk("Major contributing", "Import competition from China",
     jobs_china, pp_from_jobs(jobs_china), "0.92",
     "Acemoglu et al. (2016), 1999-2011 jobs estimate"),
  mk("Major contributing", "Adoption of industrial robots",
     jobs_robots, pp_from_jobs(jobs_robots), "0.43",
     "IFR robot stock x 5.6 jobs/robot (Acemoglu & Restrepo 2017)"),
  mk("Other contributing", "Increased receipt of disability benefits (SSDI, VADC)",
     jobs_disability, pp_from_jobs(jobs_disability), "0.17",
     "Excess caseload x elasticity (Maestas et al. 2013; Autor et al. 2016)"),
  mk("Other contributing", "Higher minimum wages",
     NA_real_, pp_minwage, "0.10",
     "Weighted judgment of Powell and Meer-West vs. ~0 literature"),
  mk("Other contributing", "Increased rate of incarceration",
     jobs_incarceration, pp_from_jobs(jobs_incarceration), "0.12",
     "Mueller-Smith Table 8 x NLSY97 shares x Buckner/Barber stock"),
  mk("Insignificant", "SNAP expansions",                                  published = "~0"),
  mk("Insignificant", "Public health insurance expansions",              published = "~0"),
  mk("Insignificant", "More generous EITC",                              published = "~0"),
  mk("Insignificant", "Increased difficulties due to lack of family leave", published = "~0"),
  mk("Insignificant", "Expanded immigration",                            published = "~0"),
  mk("Indeterminate", "Increased difficulties due to lack of child care", published = "unclear"),
  mk("Indeterminate", "Changes in leisure options",                      published = "unclear"),
  mk("Indeterminate", "Changes in social norms",                         published = "unclear"),
  mk("Indeterminate", "Increased use of opioids",                        published = "unclear"),
  mk("Indeterminate", "Rise in occupational licensing",                  published = "unclear"),
  mk("Indeterminate", "Increases in institutional frictions and/or mismatch", published = "unclear"),
  mk("Total", "TOTAL NET EPOP DECLINE", NA_real_, 3.8, "3.8",
     "From Table 1A (overall EPOP change 1999-2018)")
)

write_csv(table3, file.path(PATH_OUTPUT, "table_3.csv"))
cat(sprintf("[07] Wrote table_3.csv (%d rows)\n", nrow(table3)))

render_value <- function(row) {
  if (row$category == "Total")                          return(row$epop_pp_published)
  if (is.na(row$epop_pp_computed))                      return(row$epop_pp_published)
  sprintf("%.2f", row$epop_pp_computed)
}
group_title <- c(
  "Major contributing" = "Major contributing factors",
  "Other contributing" = "Other contributing factors",
  "Insignificant"      = "Insignificant factors",
  "Indeterminate"      = "Indeterminate given state of evidence"
)
LW <- 60L
lines <- c(
  "TABLE 3",
  "Factors Contributing to Decline in Employment-Population Ratio, 1999–2018",
  "",
  sprintf("%-*s  %s", LW, "Factors",
          "Estimated reduction in EPOP (percentage points)")
)
for (gkey in names(group_title)) {
  rows <- filter(table3, category == gkey)
  if (nrow(rows) == 0) next
  lines <- c(lines, "", group_title[[gkey]])
  for (i in seq_len(nrow(rows))) {
    r <- rows[i, ]
    lines <- c(lines,
               sprintf("%-*s  %7s", LW, paste0("  ", r$factor), render_value(r)))
  }
}
total_row <- filter(table3, category == "Total")[1, ]
lines <- c(lines, "",
           sprintf("%-*s  %7s", LW,
                   "TOTAL NET EPOP DECLINE (percentage points)",
                   render_value(total_row)),
           "",
           "Note: EPOP stands for employment-to-population ratio.")
writeLines(lines, file.path(PATH_OUTPUT, "table_3.txt"))
cat(sprintf("[07] Wrote table_3.txt (%d lines, paper layout)\n", length(lines)))

checks <- tribble(
  ~factor,                          ~computed,            ~published,
  "China",                          pp_from_jobs(jobs_china),         0.92,
  "Robots",                         pp_from_jobs(jobs_robots),        0.43,
  "Disability (SSDI+VADC)",         pp_from_jobs(jobs_disability),    0.17,
  "Minimum wages",                  pp_minwage,                       0.10,
  "Incarceration",                  pp_from_jobs(jobs_incarceration), 0.12
) |>
  mutate(rounded = round(computed, 2),
         diff    = abs(rounded - published),
         ok      = diff < 1e-9)

cat("\n[07] Table 3 verification (computed pp -> rounded vs published):\n")
checks |>
  mutate(line = sprintf("   %-24s computed=%.4f  rounded=%.2f  published=%.2f  %s",
                        factor, computed, rounded, published,
                        ifelse(ok, "PASS", "FAIL"))) |>
  pull(line) |>
  walk(cat, "\n")

if (all(checks$ok)) {
  cat(sprintf("\n[07] ALL %d computed cells match published Table 3. Max diff = %.2e\n",
              nrow(checks), max(checks$diff)))
} else {
  stop("[07] Table 3 mismatch -- see FAIL rows above.")
}
