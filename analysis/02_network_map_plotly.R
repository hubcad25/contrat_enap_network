# 02_network_map_plotly.R
# Expert: Plotly Interactive Network Visualization

library(tidyverse)
library(igraph)
library(plotly)
library(htmlwidgets)

# 1. Load Data
df <- read_csv("data/processed/digital_flows.csv")

# Sélection de l'année 2020 (ou la plus récente disponible si 2020 est vide)
target_year <- 2020
df_year <- df %>% filter(year == target_year)

if(nrow(df_year) == 0) {
  target_year <- max(df$year)
  df_year <- df %>% filter(year == target_year)
}

# 2. Préparation des Nœuds
# On calcule le volume total d'exports reçus par chaque pays (destination)
exports_received <- df_year %>%
  group_by(ccode2) %>%
  summarise(total_export_in = sum(`digital exports`, na.rm = TRUE), .groups = "drop") %>%
  rename(ccode = ccode2)

nodes_info <- df_year %>%
  select(ccode = ccode1, country = country1, model = model1) %>%
  distinct() %>%
  left_join(exports_received, by = "ccode") %>%
  mutate(total_export_in = replace_na(total_export_in, 0))

# 3. Préparation des Arêtes (Certifications uniquement)
edges_df <- df_year %>%
  filter(is_certified_state == 1) %>%
  select(from = ccode1, to = ccode2)

# Création de l'objet igraph pour le layout
g <- graph_from_data_frame(d = edges_df, vertices = nodes_info, directed = TRUE)

# On ne garde que les pays qui ont au moins un lien (ou tous ? l'utilisateur dit "bulles uniques")
# Utilisons un layout Fruchterman-Reingold pour la clarté
set.seed(42)
layout <- layout_with_fr(g)
nodes_info$x <- layout[, 1]
nodes_info$y <- layout[, 2]

# 4. Construction du Graphique Plotly

# Préparation des segments pour les arêtes
edge_shapes <- list()
for(i in 1:nrow(edges_df)) {
  v1 <- nodes_info %>% filter(ccode == edges_df$from[i])
  v2 <- nodes_info %>% filter(ccode == edges_df$to[i])
  
  if(nrow(v1) > 0 && nrow(v2) > 0) {
    edge_shapes[[i]] <- list(
      type = "line",
      line = list(color = "#D3D3D3", width = 0.5),
      x0 = v1$x, y0 = v1$y,
      x1 = v2$x, y1 = v2$y,
      layer = "below"
    )
  }
}

# Couleurs pour les modèles
# On définit une palette basée sur les préférences utilisateur
model_colors <- c(
  "open"        = "#00A087", # green
  "localization" = "#f0695a", # red
  "safe harbor"  = "#0072B2"  # blue
)

# Tracé des nœuds
p <- plot_ly(
  nodes_info, 
  x = ~x, 
  y = ~y, 
  type = 'scatter', 
  mode = 'markers',
  color = ~model,
  colors = model_colors,
  marker = list(size = 12, line = list(width = 1, color = "white")),
  text = ~paste0(
    "<b>Pays :</b> ", country, 
    "<br><b>Modèle :</b> ", model, 
    "<br><b>Exports reçus :</b> ", round(total_export_in, 2), " M$"
  ),
  hoverinfo = 'text'
) %>%
  layout(
    title = list(
      text = paste("Réseau de Certification Numérique (", target_year, ")"),
      x = 0.05,
      font = list(family = "Nunito Sans", size = 24)
    ),
    xaxis = list(title = "", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
    yaxis = list(title = "", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
    shapes = edge_shapes,
    showlegend = TRUE,
    legend = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.05),
    plot_bgcolor = "white",
    paper_bgcolor = "white",
    margin = list(l = 50, r = 50, b = 100, t = 100)
  )

# Sauvegarde
saveWidget(p, "analysis/network_map_2020.html", selfcontained = TRUE)
print("Graphique sauvegardé dans analysis/network_map_2020.html")
