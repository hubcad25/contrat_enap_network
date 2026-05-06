library(tidyverse)
library(clessnize)
library(showtext)
library(sysfonts)

# Setup fonts as per user conventions
font_add_google("Nunito Sans", "nunito")
showtext_auto()

# Colors from dashboard_colors
col_present <- "#00A087" # Green
col_missing <- "#f0695a" # Red

# Create validation directory if it doesn't exist
if (!dir.exists("data/validation")) {
  dir.create("data/validation", recursive = TRUE)
}

# 1. Read digital_flows.csv from zip
# read_csv from readr handles zip files directly if they contain one file
# or we can use unz for more explicit control if needed.
data_path <- "data/processed/digital_flows.csv.zip"
df <- read_csv(data_path)

# 2. Identify countries with missing IDP values
# Flag: 1 if all IDP entries for that country-year are NA, 0 otherwise
idp_summary <- df %>%
  group_by(country1, year) %>%
  summarise(
    idp_na_flag = as.integer(all(is.na(IDP))),
    .groups = "drop"
  )

# Identify countries that have at least one NA flag across all years
countries_with_any_na <- idp_summary %>%
  group_by(country1) %>%
  filter(any(idp_na_flag == 1)) %>%
  pull(country1) %>%
  unique()

# Filter summary to only include these countries
report_data <- idp_summary %>%
  filter(country1 %in% countries_with_any_na)

# 3. Pivot data to have years as columns and save report
report_pivoted <- report_data %>%
  pivot_wider(
    names_from = year,
    values_from = idp_na_flag
  ) %>%
  arrange(country1)

write_csv(report_pivoted, "data/validation/idp_na_report.csv")

# 4. Generate ggplot2 heatmap
# Sort countries alphabetically (A at the top)
# ggplot y-axis goes from bottom to top, so we reverse the levels
report_data <- report_data %>%
  mutate(country1 = factor(country1, levels = rev(sort(unique(country1)))))

p <- ggplot(report_data, aes(x = year, y = country1)) +
  geom_tile(aes(fill = factor(idp_na_flag)), color = "white", linewidth = 0.1) +
  scale_fill_manual(
    values = c("0" = col_present, "1" = col_missing),
    labels = c("0" = "Present", "1" = "Missing"),
    name = "IDP Data Status"
  ) +
  scale_x_continuous(
    breaks = seq(min(report_data$year), max(report_data$year), by = 5),
    expand = c(0, 0)
  ) +
  labs(
    title = "Validation of IDP Data Availability",
    subtitle = "Red indicates all IDP entries are NA for a given country and year",
    x = "Year",
    y = "Country",
    caption = stringr::str_wrap(
      "Countries shown have at least one year with missing IDP data. Green = data present, Red = data missing.",
      width = 80
    )
  ) +
  clessnize::theme_clean_light() +
  theme(
    # Background must be white
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# 5. Save the plot
# Adjust height based on the number of countries to ensure readability
n_countries <- length(unique(report_data$country1))
plot_height <- max(6, n_countries * 0.2)

ggsave(
  "data/validation/idp_na_heatmap.png",
  plot = p,
  width = 12,
  height = plot_height,
  dpi = 300
)
