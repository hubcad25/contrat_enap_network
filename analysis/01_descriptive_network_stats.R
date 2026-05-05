# 01_descriptive_network_stats.R
# Expert: ggplot2 network analysis

library(tidyverse)
library(showtext)
library(sysfonts)
library(scales)
library(colorspace)

# Setup fonts
font_add_google("Nunito Sans", "nunito")
showtext_auto()

# Dashboard Colors
dashboard_colors <- list(
  green  = "#00A087",
  red    = "#f0695a",
  blue   = "#0072B2",
  yellow = "#E69F00",
  purple = "#CC79A7",
  gray   = "grey70",
  # Opubliq
  opubliq_red       = "#f0695a",
  opubliq_lightblue = "#0d8491",
  opubliq_teal      = "#56d1d7",
  opubliq_darkblue  = "#012326",
  # Repensons Lévis
  repensons_yellow = "#f6b600",
  repensons_blue   = "#193e62"
)

# Theme Dashboard Light
theme_dashboard_light <- function(base_size = 32) {
  theme_minimal(base_size = base_size, base_family = "nunito") %+replace%
    theme(
      text = element_text(color = "grey20", lineheight = 0.3),
      plot.title = element_text(face = "bold", hjust = 0, size = base_size * 1.2),
      plot.subtitle = element_text(size = base_size * 0.9, margin = margin(b = 10)),
      plot.caption = element_text(hjust = 1, size = base_size * 0.8, lineheight = 0.45),
      panel.grid = element_blank(),
      axis.ticks = element_blank(),
      axis.line = element_blank(),
      legend.position = "bottom",
      legend.box = "horizontal",
      plot.margin = margin(15, 15, 15, 15),
      strip.text = element_text(face = "bold"),
      panel.spacing = unit(1.5, "lines")
    )
}

# 1. Load Data
df <- read_csv("data/processed/digital_flows.csv") %>%
  mutate(
    is_certified_state = as.numeric(is_certified_state),
    `digital exports` = as.numeric(`digital exports`)
  )

# --- 1. Evolution du nombre de liens de certification ---
p1_data <- df %>%
  group_by(year) %>%
  summarise(n_cert = sum(is_certified_state, na.rm = TRUE))

p1 <- ggplot(p1_data, aes(x = year, y = n_cert)) +
  geom_line(color = dashboard_colors$blue, size = 1.5) +
  geom_point(color = dashboard_colors$blue, size = 4) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Évolution des liens de certification numérique",
    subtitle = "Nombre total de paires d'États avec certification active",
    x = "",
    y = "Nombre de liens\n",
    caption = str_wrap("Source: Données de flux numériques et certifications.", width = 80)
  ) +
  theme_dashboard_light()

ggsave("analysis/evolution_certifications.png", p1, width = 12, height = 8, dpi = 300)


# --- 2. Comparaison des flux d'exports ---
# Filtrer les exports > 0 pour l'échelle log
p2_data <- df %>%
  filter(`digital exports` > 0) %>%
  mutate(status = if_else(is_certified_state == 1, "Certifié", "Non-certifié"))

p2 <- ggplot(p2_data, aes(x = status, y = `digital exports`, fill = status)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.1) +
  scale_y_log10(labels = scales::label_number()) +
  scale_fill_manual(values = c("Certifié" = dashboard_colors$green, "Non-certifié" = dashboard_colors$gray)) +
  labs(
    title = "Volume d'exports numériques et certification",
    subtitle = "Comparaison des flux (échelle log) entre paires certifiées et non-certifiées",
    x = "",
    y = "Digital Exports (Log10)\n",
    caption = str_wrap("Note: Seuls les flux supérieurs à zéro sont inclus.", width = 80)
  ) +
  guides(fill = "none") +
  theme_dashboard_light()

ggsave("analysis/exports_vs_certification.png", p2, width = 12, height = 8, dpi = 300)


# --- 3. Analyse simple de la réciprocité ---
# On regarde par année la proportion de liens réciproques
reciprocity_data <- df %>%
  filter(is_certified_state == 1) %>%
  select(year, ccode1, ccode2) %>%
  mutate(dyad = map2_chr(ccode1, ccode2, ~paste(sort(c(.x, .y)), collapse = "-"))) %>%
  group_by(year, dyad) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(year) %>%
  summarise(
    mutual = sum(n == 2),
    asymmetric = sum(n == 1),
    total = mutual + asymmetric,
    prop_mutual = mutual / total
  )

p3 <- ggplot(reciprocity_data, aes(x = year, y = prop_mutual)) +
  geom_area(fill = dashboard_colors$opubliq_teal, alpha = 0.3) +
  geom_line(color = dashboard_colors$opubliq_lightblue, size = 1.2) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1), expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "Réciprocité du réseau de certification",
    subtitle = "Proportion de liens mutuels (A certifie B ET B certifie A) parmi les paires liées",
    x = "",
    y = "% de liens mutuels\n",
    caption = str_wrap("La réciprocité indique une reconnaissance mutuelle des standards numériques.", width = 80)
  ) +
  theme_dashboard_light()

ggsave("analysis/reciprocity_certification.png", p3, width = 12, height = 8, dpi = 300)
