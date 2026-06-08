source(here::here("R", "00_setup.R"))

EMP_2018 <- 155761000
POP_2018 <- 257791000
pp <- function(jobs) 100 * jobs / POP_2018

jobs_china <- 2370000

robots_1999 <- 79959
robots_2018 <- 279683
jobs_robots <- (robots_2018 - robots_1999) * 5.6

ssdi <- tibble(
  caseload = c(132.631, 589.422, 503.437, 763.631, 1228.959, 2095.526, 3227.601) * 1000,
  pop = c(52088932.2392, 42776598.7096, 19426102.9369, 20496775.8233,
          20730951.6824, 21679796.7603, 27600163.3505),
  share99 = c(0.003084749971103774, 0.014399147222374063, 0.025210144375159983,
              0.03534822490718291, 0.05100146981302061, 0.0765506271562933,
              0.08930626749906115),
  elast = c(0.336, 0.369, 0.355, 0.355, 0.29, 0.29, 0.105)
)
ssdi$workers <- (ssdi$caseload - ssdi$share99 * ssdi$pop) * ssdi$elast
jobs_ssdi <- sum(ssdi$workers)

vadc <- tibble(
  num18 = c(578371, 1434440, 2130807),
  pop18 = c(82584989.2502, 81797040.9248, 72452114.888),
  num99 = c(80897, 1181658, 828236),
  pop99 = c(52346371.0798, 112606144.5849, 35202792.1143),
  elast = c(0.09, 0.18, 0.09)
)
vadc$workers <- (vadc$num18 - vadc$pop18 * (vadc$num99 / vadc$pop99)) * vadc$elast
jobs_vadc <- sum(vadc$workers)
jobs_disability <- jobs_ssdi + jobs_vadc

pp_minwage <- 0.10

denom <- 92526 + 228499 + 70048
share_low <- 228499 / denom
share_high <- 70048 / denom
former <- mean(c(6100000, 6900000))
count_1yr <- 0.24 * former * 0.6
count_2yr <- 0.416 * former * 0.6
jobs_incarceration <- -(share_low * count_1yr * -0.09 +
                        share_low * count_2yr * -0.11 +
                        share_high * count_1yr * -0.24 +
                        share_high * count_2yr * -0.39)

table3 <- tibble(
  category = c(rep("Major contributing", 2), rep("Other contributing", 3),
               rep("Insignificant", 5), rep("Indeterminate", 6), "Total"),
  factor = c(
    "Import competition from China",
    "Adoption of industrial robots",
    "Increased receipt of disability benefits (SSDI, VADC)",
    "Higher minimum wages",
    "Increased rate of incarceration",
    "SNAP expansions",
    "Public health insurance expansions",
    "More generous EITC",
    "Increased difficulties due to lack of family leave",
    "Expanded immigration",
    "Increased difficulties due to lack of child care",
    "Changes in leisure options",
    "Changes in social norms",
    "Increased use of opioids",
    "Rise in occupational licensing",
    "Increases in institutional frictions and/or mismatch",
    "TOTAL NET EPOP DECLINE"
  ),
  jobs_affected = c(jobs_china, jobs_robots, jobs_disability, NA, jobs_incarceration,
                    rep(NA, 11), NA),
  epop_pp_computed = c(pp(jobs_china), pp(jobs_robots), pp(jobs_disability),
                       pp_minwage, pp(jobs_incarceration), rep(NA, 11), 3.8),
  epop_pp_published = c("0.92", "0.43", "0.17", "0.10", "0.12",
                        rep("~0", 5), rep("unclear", 6), "3.8"),
  source = c(
    "Acemoglu et al. 2016, jobs lost 1999-2011",
    "IFR robot stock, 5.6 jobs per robot (Acemoglu and Restrepo 2017)",
    "Excess caseload times elasticity (Maestas et al. 2013; Autor et al. 2016)",
    "Authors' weighted judgment of the minimum-wage literature",
    "Mueller-Smith employment effects, NLSY97 shares, former-prisoner stock",
    rep(NA_character_, 11),
    "Table 1A overall EPOP change"
  )
)

write_csv(table3, file.path(PATH_OUTPUT, "table_3.csv"))
cat("Wrote table_3.csv (", nrow(table3), "rows).\n")

groups <- c("Major contributing", "Other contributing", "Insignificant", "Indeterminate")
group_titles <- c("Major contributing factors", "Other contributing factors",
                  "Insignificant factors", "Indeterminate given state of evidence")
lines <- c("TABLE 3",
           "Factors Contributing to Decline in Employment-Population Ratio, 1999-2018",
           "",
           sprintf("%-58s %s", "Factor", "Reduction in EPOP (percentage points)"))
for (g in seq_along(groups)) {
  sub <- filter(table3, category == groups[g])
  lines <- c(lines, "", group_titles[g])
  for (i in 1:nrow(sub)) {
    if (!is.na(sub$epop_pp_computed[i])) {
      val <- sprintf("%.2f", sub$epop_pp_computed[i])
    } else {
      val <- sub$epop_pp_published[i]
    }
    lines <- c(lines, sprintf("  %-56s %s", sub$factor[i], val))
  }
}
lines <- c(lines, "", sprintf("%-58s %s", "TOTAL NET EPOP DECLINE", "3.8"))
writeLines(lines, file.path(PATH_OUTPUT, "table_3.txt"))
cat("Wrote table_3.txt\n")

china_pp <- pp(jobs_china)
robots_pp <- pp(jobs_robots)
disability_pp <- pp(jobs_disability)
incarceration_pp <- pp(jobs_incarceration)
cat("\nTable 3 check (computed vs paper):\n")
cat(sprintf("  China:         %.4f  (paper 0.92)\n", china_pp))
cat(sprintf("  Robots:        %.4f  (paper 0.43)\n", robots_pp))
cat(sprintf("  Disability:    %.4f  (paper 0.17)\n", disability_pp))
cat(sprintf("  Minimum wage:  %.4f  (paper 0.10)\n", pp_minwage))
cat(sprintf("  Incarceration: %.4f  (paper 0.12)\n", incarceration_pp))
ok <- round(china_pp, 2) == 0.92 && round(robots_pp, 2) == 0.43 &&
      round(disability_pp, 2) == 0.17 && round(pp_minwage, 2) == 0.10 &&
      round(incarceration_pp, 2) == 0.12
if (!ok) stop("Table 3 does not match the paper.")
cat("All five match.\n")
