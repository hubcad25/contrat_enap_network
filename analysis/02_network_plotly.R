# ==============================================================================
# Script : 02_network_plotly.R
# Projet : Contrat ENAP Network
# Objectif : Visualisation réseau interactive via Plotly
# ==============================================================================

library(tidyverse)
library(plotly)
library(igraph)
library(htmlwidgets)
library(showtext)

# --- Configuration ---
TARGET_YEAR <- 2020

# --- Chargement des données ---
df <- read_csv("data/processed/digital_flows.csv")

# Filtrage pour l'année cible et préparation des liens
# On ne garde que les flux positifs significatifs pour la lisibilité
links_data <- df %>%
  filter(year == TARGET_YEAR) %>%
  filter(`digital exports` > 0) %>%
  select(from = country1, to = country2, weight = `digital exports`)

# Préparation des nœuds (attributs par pays)
nodes_data <- df %>%
  filter(year == TARGET_YEAR) %>%
  group_by(country1) %>%
  summarise(
    is_certified = max(is_certified_state, na.rm = TRUE),
    total_exports = sum(`digital exports`, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(name = country1)

# --- Création du graphe igraph ---
# On s'assure que tous les pays dans links sont dans nodes
all_countries <- unique(c(links_data$from, links_data$to))
nodes_data <- nodes_data %>% filter(name %in% all_countries)

g <- graph_from_data_frame(d = links_data, vertices = nodes_data, directed = TRUE)

# Calcul du layout (Fruchterman-Reingold pour un aspect organique)
layout <- layout_with_fr(g)
nodes_coords <- as.data.frame(layout)
colnames(nodes_coords) <- c("x", "y")
nodes_coords$name <- V(g)$name
nodes_coords$is_certified <- V(g)$is_certified
nodes_coords$total_exports <- V(g)$total_exports

# Préparation des segments pour les liens
edge_shapes <- list()
for(i in 1:nrow(links_data)) {
  v1 <- which(nodes_coords$name == links_data$from[i])
  v2 <- which(nodes_coords$name == links_data$to[i])
  
  if(length(v1) > 0 && length(v2) > 0) {
    edge_shape <- list(
      type = "line",
      line = list(color = "#aaaaaa", width = 0.3, opacity = 0.3),
      x0 = nodes_coords$x[v1],
      y0 = nodes_coords$y[v1],
      x1 = nodes_coords$x[v2],
      y1 = nodes_coords$y[v2],
      layer = "below"
    )
    edge_shapes[[i]] <- edge_shape
  }
}

# --- Construction du graphique Plotly ---

p <- plot_ly() %>%
  # Ajout des nœuds
  add_trace(
    data = nodes_coords,
    x = ~x, y = ~y,
    type = "scatter",
    mode = "markers",
    text = ~paste("Pays:", name, 
                  "<br>Certifié:", ifelse(is_certified == 1, "Oui", "Non"),
                  "<br>Exports totaux:", round(total_exports, 2)),
    hoverinfo = "text",
    marker = list(
      size = ~sqrt(total_exports) * 2 + 5, # Taille proportionnelle aux exports
      color = ~is_certified,
      colorscale = list(c(0, "#f0695a"), c(1, "#00A087")), # Rouge si non, Vert si oui
      showscale = FALSE,
      line = list(color = "white", width = 1)
    )
  ) %>%
  layout(
    title = paste("Réseau des flux numériques mondiaux (", TARGET_YEAR, ")", sep=""),
    shapes = edge_shapes,
    xaxis = list(title = "", showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
    yaxis = list(title = "", showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
    margin = list(l = 50, r = 50, b = 50, t = 80),
    hovermode = "closest"
  )

# --- Sauvegarde ---
saveWidget(p, "analysis/02_network_plotly.html", selfcontained = TRUE)
