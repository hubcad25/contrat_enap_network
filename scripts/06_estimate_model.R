library(tidyverse)
library(fixest)
library(clessnize)

# 1. Lire les données
data_path <- "data/processed/digital_flows.csv.zip"
df <- read_csv(data_path)

# Nettoyer les noms de colonnes pour faciliter l'accès
df <- df %>% 
  rename(
    services_import = `services import`,
    services_export = `services export`,
    digital_imports = `digital imports`,
    digital_exports = `digital exports`
  )

# 2. Préparer les données pour le modèle de survie en temps discret
# Créer un ID de dyade unique
df <- df %>%
  mutate(dyad_id = paste(country1, country2, sep = "_"))

# Identifier les dyades déjà certifiées à la première année d'observation
already_certified <- df %>%
  group_by(dyad_id) %>%
  arrange(year) %>%
  filter(row_number() == 1, is_certified_state == 1) %>%
  pull(dyad_id)

# Filtrer les données
df_survival <- df %>%
  filter(!dyad_id %in% already_certified) %>%
  group_by(dyad_id) %>%
  arrange(year) %>%
  # On garde tant que is_certified_state était 0 l'année précédente
  # Ou plus simple: on garde si is_certified_state == 0 OU si c'est l'année de l'événement
  filter(is_certified_state == 0 | is_certified_event == 1) %>%
  # Mais on doit s'assurer de ne pas garder les années APRÈS l'événement si l'état reste à 1
  filter(cumsum(is_certified_event) <= 1) %>%
  ungroup()

# 3. Normaliser les variables indépendantes (z-score)
# Pour que les coefficients soient comparables (effet d'un écart-type)
# et éviter des coefficients minuscules pour les flux commerciaux en $
vars_to_scale <- c("IDP", "services_import", "services_export", "digital_imports", "digital_exports")
df_survival <- df_survival %>%
  mutate(across(all_of(vars_to_scale), ~ as.numeric(scale(.))))

# 4. Estimer le modèle logit
# Variables indépendantes : IDP, same_model, services_import, services_export, digital_imports, digital_exports
# On inclut des effets fixes pour l'année pour contrôler les tendances temporelles
model <- feglm(
  is_certified_event ~ IDP + same_model + services_import + services_export + 
                       digital_imports + digital_exports | year,
  data = df_survival,
  family = "logit",
  cluster = ~dyad_id
)

# 5. Rapport des résultats
summary_model <- summary(model)
print(summary_model)

# Sauvegarder les résultats dans un fichier texte
sink("output/model_results.txt")
print(summary_model)
sink()

# 6. Visualisation des résultats (coefficients plot)
# Extraire les coefficients et les intervalles de confiance
coef_df <- data.frame(
  term = names(coef(model)),
  estimate = coef(model),
  std.error = se(model)
) %>%
  mutate(
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error,
    color = ifelse(estimate > 0, "#00A087", "#f0695a") # Green for positive, Red for negative
  )

# Traduire les noms des variables pour le graphique (en français)
coef_df <- coef_df %>%
  mutate(term = case_when(
    term == "IDP" ~ "Distance idéale (ONU)",
    term == "same_model" ~ "Même modèle de gouvernance",
    term == "services_import" ~ "Importations de services",
    term == "services_export" ~ "Exportations de services",
    term == "digital_imports" ~ "Importations numériques",
    term == "digital_exports" ~ "Exportations numériques",
    TRUE ~ term
  ))

p <- ggplot(coef_df, aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high, color = color), height = 0.2) +
  geom_point(aes(color = color), size = 3) +
  scale_color_identity() +
  labs(
    title = "Coefficients du modèle d'événement de certification",
    subtitle = "Modèle de survie en temps discret (Logit avec effets fixes par année)",
    x = "Estimation (Log-odds, variables standardisées)",
    y = NULL,
    caption = "Erreurs-types robustes par dyade. Les barres représentent l'IC à 95%."
  ) +
  theme_clean_light()

ggsave("output/coefficients_plot.png", p, width = 8, height = 6, dpi = 300)

# Sauvegarder le modèle pour usage futur si nécessaire
saveRDS(model, "output/certification_model.rds")
