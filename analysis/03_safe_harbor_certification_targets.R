# ==============================================================================
# Script : 03_safe_harbor_certification_targets.R
# Projet : Contrat ENAP Network
# Objectif : Les pays "safe harbor" certifient-ils des pays qui ne sont PAS
#            safe harbor ? Distribution du modele de gouvernance des pays
#            CERTIFIES (model2) par des certificateurs safe harbor (model1),
#            situee dans une matrice model1 x model2.
# Mesure principale : is_certified_state (stock, chaque annee compte).
# Robustesse verifiee : is_certified_event et dyades uniques (voir sorties).
# ==============================================================================

library(tidyverse)
library(clessnize)
library(scales)

# --- Couleurs ---
dashboard_colors <- list(
  green  = "#00A087", red = "#f0695a", blue = "#0072B2",
  yellow = "#E69F00", purple = "#CC79A7", gray = "grey70"
)

# Couleurs par modele de gouvernance du pays certifie (model2)
model_colors <- c(
  "Safe harbor"  = dashboard_colors$green,
  "Ouvert"       = dashboard_colors$blue,
  "Localisation" = dashboard_colors$red,
  "Non classe"   = dashboard_colors$gray
)

model_labels <- setNames(
  c("Safe harbor", "Ouvert", "Localisation", "Non classe"),
  c("safe harbor", "open", "localization", "")
)

recode_model <- function(x) factor(unname(model_labels[x]),
                                    levels = names(model_colors))

# --- Donnees ---
df <- read.csv(unz("data/processed/digital_flows.csv.zip", "digital_flows.csv"))

# ==============================================================================
# 1. Matrice model1 (certificateur) x model2 (certifie) -- mesure de stock
# ==============================================================================
cert_state <- df %>%
  filter(is_certified_state == 1, model1 != "")   # certificateur classe

crosstab <- table(certificateur = cert_state$model1,
                   certifie      = cert_state$model2)
cat("\n===== MATRICE model1 x model2 (is_certified_state, comptes) =====\n")
print(addmargins(crosstab))

cat("\n===== PROPORTIONS PAR LIGNE (comportement de chaque certificateur) =====\n")
print(round(prop.table(crosstab, margin = 1), 4))

# ==============================================================================
# 2. Focus : certificateurs SAFE HARBOR -> quel modele certifient-ils ?
# ==============================================================================
sh <- cert_state %>% filter(model1 == "safe harbor")

cat("\n===== SAFE HARBOR -> distribution model2 (stock) =====\n")
tab_sh <- table(sh$model2)
print(tab_sh)
cat("Proportions :\n"); print(round(prop.table(tab_sh), 4))

n_sh          <- nrow(sh)
n_sh_to_sh    <- sum(sh$model2 == "safe harbor")
n_sh_to_nonsh <- sum(sh$model2 %in% c("open", "localization"))
n_sh_to_na    <- sum(sh$model2 == "")
cat(sprintf(
  "\nTotal certifications safe harbor : %d\n  -> safe harbor      : %d (%.1f%%)\n  -> NON safe harbor  : %d (%.1f%%)  [ouvert + localisation]\n  -> non classe       : %d (%.1f%%)\n",
  n_sh, n_sh_to_sh, 100*n_sh_to_sh/n_sh,
  n_sh_to_nonsh, 100*n_sh_to_nonsh/n_sh,
  n_sh_to_na, 100*n_sh_to_na/n_sh))

# ==============================================================================
# 3. Verifications de robustesse : event (dyades-annee uniques) & dyades uniques
# ==============================================================================
cat("\n===== ROBUSTESSE : is_certified_event (safe harbor) =====\n")
sh_event <- df %>% filter(is_certified_event == 1, model1 == "safe harbor")
print(round(prop.table(table(sh_event$model2)), 4))

cat("\n===== ROBUSTESSE : dyades uniques i->j (safe harbor) =====\n")
sh_dyad <- cert_state %>% distinct(ccode1, ccode2, .keep_all = TRUE) %>%
  filter(model1 == "safe harbor")
print(round(prop.table(table(sh_dyad$model2)), 4))

# ==============================================================================
# 4. Visualisation : repartition du modele des pays certifies, par certificateur
# ==============================================================================

# --- Preparation des donnees ---
plot_data <- cert_state %>%
  mutate(
    certificateur = recode_model(model1),
    certifie      = recode_model(model2)
  ) %>%
  count(certificateur, certifie) %>%
  group_by(certificateur) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()

# Ordre des certificateurs : safe harbor en evidence
plot_data$certificateur <- factor(
  plot_data$certificateur,
  levels = c("Safe harbor", "Ouvert", "Localisation")
)

n_par_cert <- plot_data %>%
  group_by(certificateur) %>%
  summarise(total = sum(n), .groups = "drop")

# --- Graphique ---
p <- ggplot(plot_data, aes(x = certificateur, y = prop, fill = certifie)) +
  geom_col(width = 0.7, color = "white", linewidth = 0.4) +
  geom_text(
    data = subset(plot_data, prop >= 0.05),
    aes(label = percent(prop, accuracy = 1)),
    position = position_stack(vjust = 0.5),
    color = "white", fontface = "bold", size = 5,
    lineheight = 0.45
  ) +
  geom_text(
    data = n_par_cert,
    aes(x = certificateur, y = 1.03,
        label = paste0("n = ", format(total, big.mark = " "))),
    inherit.aes = FALSE,
    size = 4, color = "grey30", vjust = 0
  ) +
  scale_y_continuous(
    labels = percent,
    expand = expansion(mult = c(0, 0.08))
  ) +
  scale_fill_manual(values = model_colors) +
  labs(
    title = "Répartition du modèle de gouvernance des pays certifiés, par certificateur",
    x = "",
    y = "Part des certifications\n",
    fill = "Modèle du\npays certifié",
    caption = str_wrap(
      "Source : digital_flows.csv | Certificateurs non classés exclus",
      width = 80
    )
  ) +
  clessnize::theme_clean_light()

ggsave("analysis/plots/safe_harbor_certification_targets.png",
       p, width = 10, height = 6.5, dpi = 300)

cat("\nPlot sauvegarde : analysis/plots/safe_harbor_certification_targets.png\n")
