# ==============================================================================
# Script : 01_descriptive_plots.R
# Projet : Contrat ENAP Network
# Objectif : Visualisations descriptives (Certification et Exports)
# ==============================================================================

library(tidyverse)
library(showtext)
library(sysfonts)
library(scales)
library(patchwork)

# --- Configuration des polices ---
# Tentative de chargement de Nunito Sans
font_add_google("Nunito Sans", "nunito")
showtext_auto()

# --- Couleurs personnalisées ---
dashboard_colors <- list(
  green  = "#00A087",
  red    = "#f0695a",
  blue   = "#0072B2",
  yellow = "#E69F00",
  purple = "#CC79A7",
  gray   = "grey70"
)

# --- Chargement des données ---
df <- read_csv("data/processed/digital_flows.csv")

# ==============================================================================
# Graphique A : Évolution temporelle du nombre de pays certifiés
# ==============================================================================

data_temp <- df %>%
  group_by(year, country1) %>%
  summarise(is_certified = max(is_certified_state, na.rm = TRUE), .groups = "drop") %>%
  group_by(year) %>%
  summarise(n_certified = sum(is_certified == 1, na.rm = TRUE))

p_temp <- ggplot(data_temp, aes(x = year, y = n_certified)) +
  geom_line(color = dashboard_colors$blue, size = 1.2) +
  geom_point(color = dashboard_colors$blue, size = 3) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Évolution du nombre de pays certifiés",
    subtitle = "Nombre cumulé de pays ayant le statut 'is_certified_state'",
    x = "Année",
    y = "Nombre de pays\n",
    caption = stringr::str_wrap("Source : Dataset digital_flows.csv", width = 80)
  ) +
  theme_minimal(base_size = 14, base_family = "nunito") +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    panel.grid.minor = element_blank(),
    axis.title.y = element_text(angle = 90, vjust = 0.5)
  )

# ==============================================================================
# Graphique B : Distribution des flux digital exports (Échelle Log)
# ==============================================================================

p_dist <- df %>%
  filter(`digital exports` > 0) %>%
  ggplot(aes(x = `digital exports`)) +
  geom_histogram(fill = dashboard_colors$green, color = "white", bins = 50) +
  scale_x_log10(labels = scales::comma) +
  labs(
    title = "Distribution des exports numériques",
    subtitle = "Échelle logarithmique (base 10)",
    x = "Valeur des exports (log)",
    y = "Fréquence\n"
  ) +
  theme_minimal(base_size = 14, base_family = "nunito") +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    panel.grid.minor = element_blank()
  )

# ==============================================================================
# Graphique C : Proportion de certification par "model1"
# ==============================================================================

data_prop <- df %>%
  group_by(country1) %>%
  summarise(
    model = first(model1),
    certified = max(is_certified_state, na.rm = TRUE)
  ) %>%
  filter(!is.na(model)) %>%
  mutate(status = ifelse(certified == 1, "Certifié", "Non certifié"))

p_prop <- ggplot(data_prop, aes(x = reorder(model, certified), fill = status)) +
  geom_bar(position = "fill", width = 0.7) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = c("Certifié" = dashboard_colors$green, "Non certifié" = dashboard_colors$red)) +
  labs(
    title = "Proportion de certification par modèle",
    x = "Modèle (model1)",
    y = "Proportion\n",
    fill = "Statut"
  ) +
  theme_minimal(base_size = 14, base_family = "nunito") +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "bottom"
  )

# --- Sauvegarde ---
final_plot <- (p_temp | p_dist) / p_prop + plot_annotation(tag_levels = 'A')
ggsave("analysis/01_descriptive_plots.png", final_plot, width = 12, height = 10, dpi = 300)
