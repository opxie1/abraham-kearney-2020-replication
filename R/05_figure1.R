source(here::here("R", "00_setup.R"))

cat("Reading the BLS data (this takes a minute)...\n")

bls_raw <- suppressWarnings(read_tsv(
  FILE_BLS_TS,
  col_types = cols(
    series_id = col_character(),
    year = col_integer(),
    period = col_character(),
    value = col_double(),
    footnote_codes = col_character()
  )
))

series_ids <- read_csv(FILE_BLS_IDS, show_col_types = FALSE)
series_ids$series_id <- str_trim(series_ids$series_id)

bls <- bls_raw |>
  filter(period == "M13", year >= YEAR_FIG1_START, year <= YEAR_FIG1_END) |>
  inner_join(series_ids, by = "series_id")

cat("Kept", nrow(bls), "BLS rows.\n")

bls <- bls |>
  mutate(
    gender = case_when(
      str_detect(series_title, "Women") ~ "Female",
      str_detect(series_title, "Men") ~ "Male",
      TRUE ~ "All"
    ),
    age = case_when(
      str_detect(series_title, "16-19|20-24") ~ "16-24",
      str_detect(series_title, "25-34|35-44|45-54") ~ "25-54",
      str_detect(series_title, "55-64") ~ "55-64",
      str_detect(series_title, "65 yrs") ~ "65+"
    ),
    var = case_when(
      str_detect(series_title, "Population") ~ "pop",
      str_detect(series_title, "Employment") ~ "emp"
    )
  ) |>
  select(year, gender, age, var, value)

agg <- bls |>
  group_by(year, gender, age, var) |>
  summarise(value = sum(value), .groups = "drop") |>
  pivot_wider(names_from = var, values_from = value) |>
  mutate(epop = emp / pop)

all_ages <- agg |>
  group_by(year, gender) |>
  summarise(emp = sum(emp), pop = sum(pop), .groups = "drop") |>
  mutate(age = "All ages", epop = emp / pop)

fig_data <- bind_rows(agg, all_ages) |>
  mutate(age = factor(age, levels = c("16-24", "25-54", "55-64", "65+", "All ages"))) |>
  arrange(gender, age, year)

write_csv(fig_data, file.path(PATH_OUTPUT, "figure_1_data.csv"))
cat("Wrote figure_1_data.csv (", nrow(fig_data), "rows).\n")

plot_df <- filter(fig_data, gender == "All")

p <- ggplot(plot_df, aes(x = year, y = epop, colour = age, group = age)) +
  geom_line(linewidth = 0.7) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1), limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(YEAR_FIG1_START, YEAR_FIG1_END, by = 5)) +
  scale_colour_brewer(palette = "Dark2") +
  labs(
    title = sprintf("Figure 1. Annual employment-to-population ratio by age group, %d-%d",
                    YEAR_FIG1_START, YEAR_FIG1_END),
    x = NULL, y = "Employment-to-population ratio", colour = "Age group",
    caption = "Source: BLS Labor Force Statistics from the CPS (annual averages, unadjusted)."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "right",
        plot.title.position = "plot",
        plot.title = element_text(face = "bold"))

ggsave(file.path(PATH_OUTPUT, "figure_1.png"), p, width = 7, height = 5, dpi = 300)
ggsave(file.path(PATH_OUTPUT, "figure_1.pdf"), p, width = 7, height = 5, device = cairo_pdf)
cat("Wrote figure_1.png and figure_1.pdf\n")
