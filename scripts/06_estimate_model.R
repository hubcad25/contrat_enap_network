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
  # En fait, la condition ci-dessus garde l'année de l'événement (event=1, state=1)
  # et toutes les années avant (event=0, state=0).
  # Si une dyade a plusieurs années avec state=1 (après l'événement), elles seront exclues par is_certified_event == 0
  # SAUF si event est marqué 1 plusieurs fois (ce qui ne devrait pas arriver).
  filter(cumsum(is_certified_event) <= 1) %>%
  ungroup()

# 3. Estimer le modèle logit
# Variables indépendantes : IDP, same_model, services_import, services_export, digital_imports, digital_exports
# On inclut des effets fixes pour l'année pour contrôler les tendances temporelles
model <- feglm(
  is_certified_event ~ IDP + same_model + services_import + services_export + 
                       digital_imports + digital_exports | year,
  data = df_survival,
  family = "logit",
  cluster = ~dyad_id
)

# 4. Rapport des résultats
summary_model <- summary(model)
print(summary_model)

# Sauvegarder les résultats dans un fichier texte
sink("output/model_results.txt")
print(summary_model)
sink()

# 5. Visualisation des résultats (coefficients plot)
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

# Traduire les noms des variables pour le graphique
coef_df <- coef_df %>%
  mutate(term = case_when(
    term == "IDP" ~ "Ideal Distance (UN)",
    term == "same_model" ~ "Same Governance Model",
    term == "services_import" ~ "Services Imports",
    term == "services_export" ~ "Services Exports",
    term == "digital_imports" ~ "Digital Imports",
    term == "digital_exports" ~ "Digital Exports",
    TRUE ~ term
  ))

p <- ggplot(coef_df, aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high, color = color), height = 0.2) +
  geom_point(aes(color = color), size = 3) +
  scale_color_identity() +
  labs(
    title = "Coefficients of Certification Event Model",
    subtitle = "Discrete-time survival model (Logit with year fixed effects)",
    x = "Log-odds Estimate",
    y = NULL,
    caption = "Clustered standard errors by dyad. Error bars represent 95% CI."
  ) +
  theme_clean_light()

ggsave("output/coefficients_plot.png", p, width = 8, height = 6, dpi = 300)

# Sauvegarder le modèle pour usage futur si nécessaire
saveRDS(model, "output/certification_model.rds")
