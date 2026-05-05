# ---
# Visualisation des flux numériques (ggplot2)
# Date: 2026-05-05
# ---

library(tidyverse)
library(igraph)
library(showtext)
library(sysfonts)
library(scales)
library(colorspace)
library(ggnewscale)

# --- Configuration des polices ---
tryCatch({
  font_add_google("Nunito Sans", "nunito")
  showtext_auto()
}, error = function(e) {
  message("Could not load Nunito Sans from Google. Using default sans.")
})

# --- Thèmes et Couleurs ---
dashboard_colors <- list(
  green  = "#00A087",
  red    = "#f0695a",
  blue   = "#0072B2",
  yellow = "#E69F00",
  purple = "#CC79A7",
  gray   = "grey70",
  opubliq_red       = "#f0695a",
  opubliq_lightblue = "#0d8491",
  opubliq_teal      = "#56d1d7",
  opubliq_darkblue  = "#012326",
  repensons_yellow = "#f6b600",
  repensons_blue   = "#193e62"
)

theme_dashboard <- function(base_size = 22) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      text = element_text(family = "nunito", color = "grey90", lineheight = 0.3),
      plot.background = element_rect(fill = "#333333", color = NA),
      panel.background = element_rect(fill = "#333333", color = NA),
      panel.grid = element_blank(),
      axis.ticks = element_blank(),
      axis.line = element_blank(),
      axis.text = element_text(color = "grey90"),
      plot.title = element_text(face = "bold", hjust = 0, size = base_size * 1.2, margin = margin(b = 10)),
      plot.subtitle = element_text(hjust = 0, size = base_size * 0.9, margin = margin(b = 20)),
      plot.caption = element_text(hjust = 1, size = base_size * 0.8, lineheight = 0.45, margin = margin(t = 15)),
      legend.position = "bottom",
      legend.box = "horizontal",
      plot.margin = margin(15, 15, 15, 15),
      strip.text = element_text(face = "bold", color = "grey90"),
      panel.spacing = unit(1.5, "lines")
    )
}

theme_dashboard_light <- function(base_size = 32) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      text = element_text(family = "nunito", color = "grey20", lineheight = 0.3),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      panel.grid = element_blank(),
      axis.ticks = element_blank(),
      axis.line = element_blank(),
      axis.text = element_text(color = "grey20"),
      plot.title = element_text(face = "bold", hjust = 0, size = base_size * 1.2, margin = margin(b = 10)),
      plot.subtitle = element_text(hjust = 0, size = base_size * 0.9, margin = margin(b = 20)),
      plot.caption = element_text(hjust = 1, size = base_size * 0.8, lineheight = 0.45, margin = margin(t = 15)),
      legend.position = "bottom",
      legend.box = "horizontal",
      plot.margin = margin(15, 15, 15, 15),
      strip.text = element_text(face = "bold", color = "grey20"),
      panel.spacing = unit(1.5, "lines")
    )
}

# --- 1. Chargement des données ---
data_path <- "/home/hubcad25/opubliq/repos/contrat_enap_network/data/processed/digital_flows.csv"
df <- read_csv(data_path)

# Nettoyage et définition du réseau binaire
# On considère un lien si digital exports > 0
df_binary <- df %>%
  filter(!is.na(country1), !is.na(country2)) %>%
  mutate(edge = ifelse(`digital exports` > 0, 1, 0))

# --- 2. Calcul des métriques globales ---

calculate_metrics <- function(dyads) {
  # Création du graph pour une année
  edges <- dyads %>% filter(edge == 1) %>% select(country1, country2)
  nodes <- unique(c(dyads$country1, dyads$country2))
  
  g <- graph_from_data_frame(edges, directed = TRUE, vertices = data.frame(name = nodes))
  
  data.frame(
    density = edge_density(g),
    reciprocity = reciprocity(g),
    transitivity = transitivity(g, type = "global")
  )
}

metrics_by_year <- df_binary %>%
  group_by(year) %>%
  do(calculate_metrics(.)) %>%
  ungroup()

# Calcul des degrés (In/Out) pour les années clés
years_keys <- c(2000, 2010, 2022)
degree_dist <- df_binary %>%
  filter(year %in% years_keys) %>%
  group_by(year) %>%
  group_modify(~ {
    edges <- .x %>% filter(edge == 1) %>% select(country1, country2)
    nodes <- unique(c(.x$country1, .x$country2))
    g <- graph_from_data_frame(edges, directed = TRUE, vertices = data.frame(name = nodes))
    data.frame(
      country = V(g)$name,
      degree_in = degree(g, mode = "in"),
      degree_out = degree(g, mode = "out")
    )
  }) %>%
  ungroup()

# Heatmap inter-model density (Year 2022 as snapshot)
heatmap_data <- df_binary %>%
  filter(year == 2022) %>%
  filter(!is.na(model1), !is.na(model2), model1 != "", model2 != "") %>%
  group_by(model1, model2) %>%
  summarise(
    n_edges = sum(edge),
    n_possible = n(),
    density = n_edges / n_possible,
    .groups = "drop"
  )

# --- 3. Visualisations ---

# Plot 1: Évolution des métriques globales
metrics_long <- metrics_by_year %>%
  pivot_longer(cols = c(density, reciprocity, transitivity), names_to = "metric", values_to = "value") %>%
  mutate(metric_label = case_when(
    metric == "density" ~ "Densité",
    metric == "reciprocity" ~ "Réciprocité",
    metric == "transitivity" ~ "Transitivité"
  ))

p1 <- ggplot(metrics_long, aes(x = year, y = value, color = metric_label)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  scale_color_manual(values = c(dashboard_colors$blue, dashboard_colors$green, dashboard_colors$red)) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.05))) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.02))) +
  labs(
    title = "Évolution des métriques globales du réseau numérique",
    subtitle = "Densité, réciprocité et transitivité des flux d'exportations numériques (1995-2024)",
    x = "Année",
    y = "Valeur (%)\n",
    caption = str_wrap("Source: Analyse des flux numériques ENAP. La densité mesure la proportion de liens existants sur le total possible.", width = 100)
  ) +
  theme_dashboard_light() +
  theme(legend.title = element_blank())

# Plot 2: Distribution des degrés (In/Out)
degree_long <- degree_dist %>%
  pivot_longer(cols = starts_with("degree"), names_to = "type", values_to = "degree") %>%
  mutate(type_label = ifelse(type == "degree_in", "Degré entrant (Importations)", "Degré sortant (Exportations)"))

p2 <- ggplot(degree_long, aes(x = degree, fill = type_label)) +
  geom_density(alpha = 0.7, color = NA) +
  facet_wrap(~year, ncol = 3) +
  scale_fill_manual(values = c(dashboard_colors$blue, dashboard_colors$opubliq_teal)) +
  scale_x_log10() +
  labs(
    title = "Distribution des degrés de connectivité",
    subtitle = "Comparaison des degrés entrants et sortants pour les années 2000, 2010 et 2022",
    x = "Degré (échelle log10)",
    y = "Densité\n",
    fill = "",
    caption = str_wrap("Note: L'axe X est en échelle logarithmique pour mieux visualiser la distribution de longue traîne.", width = 100)
  ) +
  theme_dashboard_light()

# Plot 3: Heatmap des modèles
p3 <- ggplot(heatmap_data, aes(x = model1, y = model2, fill = density)) +
  geom_tile(color = "white", size = 0.5) +
  geom_text(aes(label = percent(density, accuracy = 0.1)), color = "white", fontface = "bold", size = 8) +
  scale_fill_gradient(low = lighten(dashboard_colors$opubliq_darkblue, 0.2), high = dashboard_colors$opubliq_red, labels = percent) +
  labs(
    title = "Densité des flux entre modèles de gouvernance (2022)",
    subtitle = "Proportion de liens actifs entre pays selon leur modèle de régulation numérique",
    x = "Modèle de l'exportateur",
    y = "Modèle de l'importateur\n",
    fill = "Densité",
    caption = str_wrap("Source: Calculs basés sur les données de flux dyadiques 2022.", width = 100)
  ) +
  theme_dashboard_light() +
  theme(legend.position = "right", legend.direction = "vertical")

# --- 4. Sauvegarde ---
dir.create("output/plots", recursive = TRUE, showWarnings = FALSE)
ggsave("output/plots/01_global_metrics.png", p1, width = 14, height = 8, dpi = 300)
ggsave("output/plots/02_degree_distribution.png", p2, width = 14, height = 8, dpi = 300)
ggsave("output/plots/03_model_heatmap.png", p3, width = 12, height = 10, dpi = 300)

message("Analyses et graphiques terminés. Fichiers sauvegardés dans output/plots/")
