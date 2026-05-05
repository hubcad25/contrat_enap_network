# ==============================================================================
# Script : 02_network_map_plotly.R
# Projet : Contrat ENAP Network
# Objectif : Réseau interactif des certifications (VD)
# ==============================================================================

library(tidyverse)
library(plotly)
library(igraph)
library(htmlwidgets)

# --- Configuration ---
TARGET_YEAR <- 2020

# --- Chargement des données ---
df <- read_csv("/home/hubcad25/opubliq/repos/contrat_enap_network/data/processed/digital_flows.csv")

# 1. Liens de certification (VD)
links_data <- df %>%
  filter(year == TARGET_YEAR) %>%
  filter(is_certified_state == 1) %>%
  select(from = country1, to = country2, exports = `digital exports`)

# 2. Données des pays (Nœuds)
# On agrège les exports totaux envoyés pour dimensionner les bulles
nodes_data <- df %>%
  filter(year == TARGET_YEAR) %>%
  group_by(country1) %>%
  summarise(
    model = first(model1),
    total_exports_sent = sum(`digital exports`, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(name = country1)

# --- Création du graphe ---
# On s'assure d'avoir tous les pays présents dans les liens
all_countries <- unique(c(links_data$from, links_data$to))
nodes_data <- nodes_data %>% filter(name %in% all_countries)

g <- graph_from_data_frame(d = links_data, vertices = nodes_data, directed = TRUE)

# Calcul du layout
coords <- layout_with_fr(g)
nodes_coords <- as.data.frame(coords)
colnames(nodes_coords) <- c("x", "y")
nodes_coords$name <- V(g)$name
nodes_coords$model <- V(g)$model
nodes_coords$total_exports <- V(g)$total_exports_sent

# Préparation des segments pour Plotly
edge_shapes <- list()
for(i in 1:nrow(links_data)) {
  v1 <- which(nodes_coords$name == links_data$from[i])
  v2 <- which(nodes_coords$name == links_data$to[i])
  
  if(length(v1) > 0 && length(v2) > 0) {
    edge_shape <- list(
      type = "line",
      line = list(color = "#cccccc", width = 0.5),
      x0 = nodes_coords$x[v1],
      y0 = nodes_coords$y[v1],
      x1 = nodes_coords$x[v2],
      y1 = nodes_coords$y[v2],
      layer = "below"
    )
    edge_shapes[[i]] <- edge_shape
  }
}

# --- Visualisation Plotly ---

p <- plot_ly() %>%
  add_trace(
    data = nodes_coords,
    x = ~x, y = ~y,
    type = "scatter",
    mode = "markers",
    color = ~model,
    colors = c("open" = "#00A087", "safe harbor" = "#0072B2", "localization" = "#f0695a"),
    marker = list(
      size = ~log10(total_exports + 1) * 5 + 5,
      line = list(color = "#ffffff", width = 1)
    ),
    text = ~paste("Pays:", name, 
                  "<br>Modèle:", model,
                  "<br>Exports totaux:", round(total_exports, 2)),
    hoverinfo = "text"
  ) %>%
  layout(
    title = list(text = paste("Réseau de certification en", TARGET_YEAR), x = 0.05),
    paper_bgcolor = "#ffffff",
    plot_bgcolor = "#ffffff",
    xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
    yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
    shapes = edge_shapes,
    margin = list(t = 100)
  )

# Sauvegarde
saveWidget(p, "/home/hubcad25/opubliq/repos/contrat_enap_network/analysis/network_map_2020.html")
