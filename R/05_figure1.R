source(here::here("R", "00_setup.R"))

cat("[05] Reading BLS LN time series (this can take a minute) …\n")

bls_raw <- suppressWarnings(read_tsv(
  FILE_BLS_TS,
  col_types = cols(
    series_id       = col_character(),
    year            = col_integer(),
    period          = col_character(),
    value           = col_double(),
    footnote_codes  = col_character()
  ),
  trim_ws  = TRUE,
  progress = FALSE
))

cat(sprintf("[05] Read %d BLS rows; filtering to M13 and 1965-2018 …\n",
            nrow(bls_raw)))

series_ids <- read_csv(FILE_BLS_IDS, show_col_types = FALSE) |>
  mutate(series_id = str_trim(series_id))

bls <- bls_raw |>
  filter(period == "M13",
         year >= YEAR_FIG1_START, year <= YEAR_FIG1_END) |>
  inner_join(series_ids, by = "series_id")

cat(sprintf("[05] After filter & join with series_ids: %d rows\n",
            nrow(bls)))

stopifnot(!anyNA(bls$value))

parse_meta <- function(title) {
  tibble(
    gender = case_when(
      str_detect(title, "Women") ~ "Female",
      str_detect(title, "Men")   ~ "Male",
      TRUE                        ~ "All"
    ),
    age = case_when(
      str_detect(title, "16-19|20-24") ~ "16-24",
      str_detect(title, "25-34|35-44|45-54") ~ "25-54",
      str_detect(title, "55-64") ~ "55-64",
      str_detect(title, "65 yrs")  ~ "65+"
    ),
    var = case_when(
      str_detect(title, "Population") ~ "pop",
      str_detect(title, "Employment") ~ "emp"
    )
  )
}

bls <- bls |>
  bind_cols(parse_meta(bls$series_title)) |>
  select(year, gender, age, var, value)

stopifnot(!anyNA(bls$age), !anyNA(bls$var), !anyNA(bls$gender))

bls_agg <- bls |>
  summarise(value = sum(value), .by = c(year, gender, age, var)) |>
  pivot_wider(names_from = var, values_from = value) |>
  mutate(epop = emp / pop)

all_ages <- bls_agg |>
  summarise(
    emp = sum(emp),
    pop = sum(pop),
    .by = c(year, gender)
  ) |>
  mutate(age = "All ages", epop = emp / pop)

fig_data <- bind_rows(bls_agg, all_ages) |>
  mutate(age = factor(age,
                      levels = c("16-24", "25-54", "55-64", "65+",
                                 "All ages"))) |>
  arrange(gender, age, year)

write_csv(fig_data, file.path(PATH_OUTPUT, "figure_1_data.csv"))
cat(sprintf("[05] Wrote figure_1_data.csv (%d rows)\n", nrow(fig_data)))

plot_df <- fig_data |>
  filter(gender == "All") |>
  filter(age %in% c("16-24", "25-54", "55-64", "65+", "All ages"))

p <- ggplot(plot_df,
            aes(x = year, y = epop, colour = age, group = age)) +
  geom_line(linewidth = 0.7) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1),
                     limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(YEAR_FIG1_START, YEAR_FIG1_END, by = 5)) +
  scale_colour_brewer(palette = "Dark2") +
  labs(
    title = sprintf("Figure 1. Annual employment-to-population ratio by age group, %d-%d",
                    YEAR_FIG1_START, YEAR_FIG1_END),
    x = NULL, y = "Employment-to-population ratio",
    colour = "Age group",
    caption = "Source: BLS Labor Force Statistics from the CPS (annual averages, unadjusted)."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "right",
        plot.title.position = "plot",
        plot.title = element_text(face = "bold"))

ggsave(file.path(PATH_OUTPUT, "figure_1.png"), plot = p,
       width = 7, height = 5, units = "in", dpi = 300)
ggsave(file.path(PATH_OUTPUT, "figure_1.pdf"), plot = p,
       width = 7, height = 5, units = "in", device = cairo_pdf)

cat(sprintf("[05] Wrote figure_1.png/.pdf\n"))
