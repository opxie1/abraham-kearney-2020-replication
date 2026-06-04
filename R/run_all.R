source(here::here("R", "00_setup.R"))

cat("================================================================\n")
cat("Abraham & Kearney (2020, JEL) replication pipeline\n")
cat("================================================================\n\n")

scripts <- c(
  "01_load_microdata.R",
  "02_build_analysis.R",
  "03_table1.R",
  "04_table2.R",
  "05_figure1.R",
  "07_table3.R",
  "06_verify.R"
)

walk(scripts, \(s) {
  cat(sprintf("\n>>> %s\n", s))
  source(here::here("R", s), local = new.env())
})

sink(file.path(PATH_DOCS, "sessionInfo.txt"))
print(sessionInfo())
sink()

cat("\n================================================================\n")
cat("Done. Deliverables:\n")
cat(sprintf("  - Parquet:   %s\n", FILE_ANALYSIS))
cat(sprintf("  - Tables:    %s\n", file.path(PATH_OUTPUT, "table_{1a,1b,1c,2a,2b,3}.csv")))
cat(sprintf("  - Table 3 visual: %s\n", file.path(PATH_OUTPUT, "table_3.txt")))
cat(sprintf("  - Figure:    %s + .pdf + figure_1_data.csv\n",
            file.path(PATH_OUTPUT, "figure_1.png")))
cat(sprintf("  - Report:    %s\n", file.path(PATH_DOCS, "replication_check.md")))
cat("================================================================\n")
cat("\n[run_all] SUCCESS. All tables, Figure 1, parquet, and verification written.\n")
if (.Platform$OS.type == "windows") {
  cat("[run_all] On Windows, R may report a non-zero exit code after this line.\n")
  cat("          That is a known Apache Arrow shutdown bug (its DLL unloads\n")
  cat("          after R finishes); every output above is already on disk.\n")
  cat("          This SUCCESS banner is the signal that the run completed.\n")
}
