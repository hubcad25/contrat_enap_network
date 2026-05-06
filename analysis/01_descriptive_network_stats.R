# ==============================================================================
# Script : 01_descriptive_network_stats.R
# Projet : Contrat ENAP Network
# Objectif : Statistiques descriptives du réseau de certification (VD)
# ==============================================================================

library(tidyverse)
library(clessnize)
library(scales)

# --- Chargement des données ---
df <- read_csv("/home/hubcad25/opubliq/repos/contrat_enap_network/data/processed/digital_flows.csv")

# --- 1. Évolution du nombre de liens de certification ---
# Calcul de la réciprocité en même temps
reciprocity_counts <- df %>%
  select(year, country1, country2, is_certified_state) %>%
  inner_join(
    df %>% select(year, country1, country2, is_certified_state),
    by = c("year" = "year", "country1" = "country2", "country2" = "country1"),
    suffix = c("_orig", "_dest")
  ) %>%
  filter(is_certified_state_orig == 1) %>%
  group_by(year) %>%
  summarise(
    total_certifications = n(),
    reciprocal_certifications = sum(is_certified_state_dest, na.rm = TRUE),
    .groups = "drop"
  )

# Conversion en format long pour ggplot
cert_evolution_long <- reciprocity_counts %>%
  pivot_longer(cols = c(total_certifications, reciprocal_certifications), 
               names_to = "type", values_to = "count")

p1 <- ggplot(cert_evolution_long, aes(x = year, y = count, color = type)) +
  geom_line(linewidth = 1) +
  geom_point() +
  scale_color_manual(
    values = c("total_certifications" = "#0072B2", "reciprocal_certifications" = "#00A087"),
    labels = c("Total", "Réciproques")
  ) +
  labs(
    title = "Évolution du nombre de certifications",
    subtitle = "Nombre total vs liens réciproques (A <-> B) par année",
    x = "Année",
    y = "Nombre de liens",
    color = "Type de lien"
  ) +
  clessnize::theme_clean_light()

ggsave("/home/hubcad25/opubliq/repos/contrat_enap_network/analysis/plots/certification_evolution.png", p1, width = 10, height = 6)

# --- 2. Comparaison des flux d'exports (Log Scale) ---
# On compare les paires certifiées vs non-certifiées
p2 <- ggplot(df %>% filter(`digital exports` > 0), aes(x = as.factor(is_certified_state), y = `digital exports`)) +
  geom_boxplot(aes(fill = as.factor(is_certified_state)), outlier.alpha = 0.2) +
  scale_y_log10(labels = scales::label_number()) +
  scale_fill_manual(values = c("0" = "#aaaaaa", "1" = "#00A087"), labels = c("Non-certifié", "Certifié")) +
  labs(
    title = "Volume d'exports numériques et certification",
    subtitle = "Comparaison en échelle logarithmique",
    x = "Statut de certification du lien",
    y = "Digital Exports (log10)",
    fill = "Lien certifié"
  ) +
  clessnize::theme_clean_light()

ggsave("/home/hubcad25/opubliq/repos/contrat_enap_network/analysis/plots/exports_vs_certification.png", p2, width = 10, height = 6)

# --- 3. Analyse de la réciprocité (Taux) ---
p3 <- reciprocity_counts %>%
  mutate(reciprocity_rate = reciprocal_certifications / total_certifications) %>%
  ggplot(aes(x = year, y = reciprocity_rate)) +
  geom_area(fill = "#00A087", alpha = 0.3) +
  geom_line(color = "#00A087", linewidth = 1) +
  labs(
    title = "Taux de réciprocité des certifications",
    subtitle = "Proportion de certifications mutuelles (A <-> B)",
    x = "Année",
    y = "Taux de réciprocité"
  ) +
  clessnize::theme_clean_light()

ggsave("/home/hubcad25/opubliq/repos/contrat_enap_network/analysis/plots/reciprocity_evolution.png", p3, width = 10, height = 6)

# --- 4. Proportion de certification par model1 ---
p4 <- df %>%
  filter(!is.na(model1)) %>%
  group_by(model1) %>%
  summarise(
    total = n(),
    certified = sum(is_certified_state, na.rm = TRUE),
    prop = certified / total
  ) %>%
  ggplot(aes(x = reorder(model1, -prop), y = prop, fill = model1)) +
  geom_col() +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("open" = "#00A087", "safe harbor" = "#0072B2", "localization" = "#f0695a")) +
  labs(
    title = "Proportion de liens certifiés par modèle",
    subtitle = "Basé sur le modèle de l'exportateur (model1)",
    x = "Modèle",
    y = "% de liens certifiés"
  ) +
  clessnize::theme_clean_light() +
  theme(legend.position = "none")

ggsave("/home/hubcad25/opubliq/repos/contrat_enap_network/analysis/plots/cert_prop_by_model.png", p4, width = 10, height = 6)
