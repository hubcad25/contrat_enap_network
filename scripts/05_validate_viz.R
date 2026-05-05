library(tidyverse)
library(readxl)
library(patchwork)
library(showtext)

# Setup fonts as per user conventions
tryCatch({
  font_add_google("Nunito Sans", "nunito")
  showtext_auto()
}, error = function(e) {
  message("Could not load Nunito Sans from Google. Using default font.")
})

# 1. Load data
df_flows <- read_xlsx("data/processed/digital_flows.xlsx")
df_attr <- read_xlsx("data/raw/structure/attribute.xlsx")

# 2. Plot A: Cumulative count of is_certified per year
plot_a <- df_flows %>%
  group_by(year) %>%
  summarise(count_year = sum(is_certified, na.rm = TRUE), .groups = "drop") %>%
  mutate(total_certified = cumsum(count_year)) %>%
  ggplot(aes(x = year, y = total_certified)) +
  geom_line(color = "#0072B2", linewidth = 1) +
  geom_point(color = "#0072B2") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  theme_light(base_size = 18) +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    text = element_text(family = "nunito")
  ) +
  labs(
    title = "Cumulative Certifications over Time",
    x = "Year",
    y = "Cumulative is_certified\n"
  )

# 2. Plot B: Scatter plot of 'digital exports' vs 'IDP' (Log Scale)
plot_b <- df_flows %>%
  filter(year == 2022) %>%
  # Add small constant to allow log of zero if necessary, or filter
  filter(`digital exports` > 0) %>%
  ggplot(aes(x = IDP, y = `digital exports`)) +
  geom_point(alpha = 0.4, color = "#56d1d7") +
  geom_smooth(method = "lm", formula = y ~ x, color = "#f0695a", fill = "#f0695a", alpha = 0.2) +
  scale_y_log10(labels = scales::comma, expand = expansion(mult = c(0, 0.05))) +
  theme_light(base_size = 18) +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    text = element_text(family = "nunito")
  ) +
  labs(
    title = "Digital Exports vs IDP (Log Scale, 2022)",
    x = "IDP",
    y = "Digital Exports (USD M, log)\n"
  )

# 2. Plot C: Evolution of governance models. Use data/raw/structure/attribute.xlsx to count countries per model per year.
plot_c <- df_attr %>%
  count(year, model) %>%
  ggplot(aes(x = year, y = n, fill = model)) +
  geom_area(alpha = 0.8) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  scale_fill_brewer(palette = "Set2") +
  theme_light(base_size = 18) +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    text = element_text(family = "nunito"),
    legend.position = "bottom"
  ) +
  labs(
    title = "Evolution of Governance Models",
    x = "Year",
    y = "Number of Countries\n",
    fill = "Model"
  )

# 3. Combine into a dashboard using patchwork
dashboard <- (plot_a + plot_b) / plot_c +
  plot_annotation(
    title = "Data Validation Summary",
    theme = theme(
      plot.title = element_text(family = "nunito", face = "bold", size = 24),
      plot.background = element_rect(fill = "white", color = NA)
    )
  ) &
  theme(plot.background = element_rect(fill = "white", color = NA))

# 4. Save the dashboard
ggsave("validation_summary.png", dashboard, width = 10, height = 8, dpi = 300)

message("Validation dashboard saved to validation_summary.png")
