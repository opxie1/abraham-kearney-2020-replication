source(here::here("R", "00_setup.R"))

cat("Running the replication...\n\n")

scripts <- c("01_load_microdata.R", "02_build_analysis.R", "03_table1.R",
             "04_table2.R", "05_figure1.R", "07_table3.R", "06_verify.R")
for (s in scripts) {
  cat("====", s, "====\n")
  source(here::here("R", s), local = new.env())
  cat("\n")
}

sink(file.path(PATH_DOCS, "sessionInfo.txt"))
print(sessionInfo())
sink()

cat("Done. The tables, Figure 1, the parquet, and the check report are in the output and docs folders.\n")
if (.Platform$OS.type == "windows") {
  cat("(On Windows, R may show a non-zero exit code after this line from an arrow shutdown bug; the files are all written.)\n")
}
