# ==============================================================================
# Script : 04_safe_harbor_no_certifications.R
# Projet : Contrat ENAP Network
# Objectif : Identifier les pays "safe harbor" qui n'ont emis AUCUNE
#            certification (is_certified_state == 0 pour toutes leurs dyades).
#            Ces pays ont le statut de modele de gouvernance "safe harbor" mais
#            n'ont certifie aucun autre pays.
# Mesure : is_certified_state (stock, chaque annee compte).
# ==============================================================================

library(tidyverse)
library(clessnize)

# --- Couleurs ---
dashboard_colors <- list(
  green  = "#00A087", red = "#f0695a", blue = "#0072B2",
  yellow = "#E69F00", purple = "#CC79A7", gray = "grey70"
)

# --- Donnees ---
df <- read.csv(unz("data/processed/digital_flows.csv.zip", "digital_flows.csv"))

# --- 1. Identifier les pays safe harbor ---
sh_all <- df %>%
  filter(model1 == "safe harbor") %>%
  distinct(country1, ccode1)

cat("=== Total des pays safe harbor :", nrow(sh_all), "===\n\n")

# --- 2. Identifier les SH qui ont certifie au moins un pays ---
sh_certs <- df %>%
  filter(model1 == "safe harbor", is_certified_state == 1) %>%
  distinct(country1, ccode1)

cat("Pays SH ayant certifie au moins un pays :", nrow(sh_certs), "\n\n")

# --- 3. Pays SH sans aucune certification ---
no_cert <- anti_join(sh_all, sh_certs, by = "country1") %>%
  arrange(country1)

cat("=== Pays safe harbor SANS aucune certification :", nrow(no_cert), "===\n\n")

if (nrow(no_cert) > 0) {
  cat("Liste complete :\n")
  print(as.data.frame(no_cert), row.names = FALSE)

  # --- 4. Graphique : liste visuelle horizontale ---
  plot_data <- no_cert %>%
    mutate(country1 = fct_rev(fct_reorder(country1, country1)))

  n_countries <- nrow(plot_data)
  plot_height <- max(6, n_countries * 0.35 + 2)

  p <- ggplot(plot_data, aes(x = 1, y = country1)) +
    geom_tile(
      fill = dashboard_colors$red, color = dashboard_colors$red,
      alpha = 0.15, width = 0.9, height = 0.9
    ) +
    geom_text(
      aes(label = country1),
      hjust = 0, x = 0.05, size = 4, color = "grey20",
      lineheight = 0.45
    ) +
    scale_x_continuous(expand = expansion(mult = c(0, 1))) +
    scale_y_discrete(expand = expansion(mult = c(0.02, 0.02))) +
    labs(
      title = str_wrap(
        paste0(
          "Pays class\u00e9s \u00ab safe harbor \u00bb ",
          "sans aucune certification \u00e9mise (",
          n_countries, " sur ", nrow(sh_all), ")"
        ),
        width = 70
      ),
      subtitle = str_wrap(
        "Ces pays appliquent un mod\u00e8le de gouvernance safe harbor mais n'ont certifi\u00e9 aucun autre pays dans le r\u00e9seau",
        width = 80
      ),
      x = NULL,
      y = NULL,
      caption = str_wrap(
        "Source : digital_flows.csv | Mesure : is_certified_state (stock)",
        width = 80
      )
    ) +
    theme_void() +
    theme(
      plot.title = element_text(
        face = "bold", size = 16, color = "grey20",
        hjust = 0, margin = margin(b = 5)
      ),
      plot.subtitle = element_text(
        size = 11, color = "grey40",
        hjust = 0, margin = margin(b = 15)
      ),
      plot.caption = element_text(
        size = 9, color = "grey50",
        hjust = 1, margin = margin(t = 15)
      ),
      plot.margin = margin(15, 20, 15, 15)
    )

  ggsave(
    "analysis/plots/safe_harbor_no_certifications.png",
    p, width = 10, height = plot_height, dpi = 300
  )

  cat("\nPlot sauvegarde : analysis/plots/safe_harbor_no_certifications.png\n")

} else {
  cat("Aucun pays safe harbor sans certification. Rien a afficher.\n")
}
