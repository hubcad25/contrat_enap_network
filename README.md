# contrat_enap_network

Analyse du réseau de certification de modèles de gouvernance des flux de données numériques entre pays (1995–2024). Contrat pour l'ENAP.

## Contexte

Le projet construit un réseau dyadique (paires de pays, par année) des certifications de transfert de données entre pays, et modélise quels facteurs expliquent qu'un pays certifie un autre pays :
- distance politique entre les deux pays (IDP — Ideal Point Distance, votes à l'ONU)
- partage ou non du même modèle de gouvernance des données (ouvert / safe harbor / localisation)
- flux commerciaux de services et de services numériques entre les deux pays

Le contexte initial du projet et les sources de données sont détaillés dans `doc.md`. Les questions de recherche en cours et l'avancement sont documentés dans `rencontre_6mai.md` et dans le rapport `analysis/rapport_avancees.qmd` / `analysis/rapport_avancees.pdf`.

## Installation

### R
```r
install.packages(c("tidyverse", "fixest", "scales", "igraph", "plotly",
                    "htmlwidgets", "patchwork", "colorspace", "ggnewscale",
                    "showtext", "sysfonts"))
```

### Python
```
pip install pandas numpy
```

## Données

`data/interim/`, `data/processed/` (sauf `digital_flows.csv` non compressé, trop gros pour git — utiliser `digital_flows.csv.zip`) et `data/validation/` sont versionnés dans le repo : les résultats intermédiaires et finaux du pipeline sont donc disponibles sans avoir à relancer `data/raw/` → `data/processed/`. **Tu n'as besoin de `data/raw/` que si tu veux reconstruire le pipeline depuis zéro** (relancer `scripts/00` à `04`).

### Si tu as besoin de `data/raw/`

`data/raw/` n'est **pas versionné** (>600 Mo, incluant deux fichiers OCDE/OMC de plusieurs centaines de Mo — au-delà des limites de taille de fichier de GitHub). Demande ces fichiers directement à qui t'a remis le contrat, puis place-les à la racine du repo dans `data/raw/` avec exactement ces noms :

| Fichier | Description |
|---|---|
| `data/raw/Data.xlsx` | Edgelist des certifications (Certifier, Certified, Year), collectée manuellement |
| `data/raw/Data_localization.xlsx` | Modèle de gouvernance des données par pays et par année (safe harbor / localisation / ouvert) |
| `data/raw/COW-country-codes.csv` | Codes pays Correlates of War (COW), pour standardiser les identifiants de pays |
| `data/raw/IDP_dataverse_files.zip` | Archive Dataverse contenant `IdealPointDyads1946-2025.csv` (distance politique ONU, Bailey et al.) |
| `data/raw/OECD-WTO_BATIS_data.zip` | Données de commerce de services OCDE/OMC, définitions BPM5 (EBOPS 2002) |
| `data/raw/OECD-WTO_BATIS_data_BPM6-1.zip` | Données de commerce de services OCDE/OMC, définitions BPM6 |

`data/raw/structure/attribute.xlsx` n'a pas besoin d'être fourni : c'est une sortie intermédiaire générée par `scripts/00_process_attributes.py` (créé automatiquement si absent). `data/raw/litt/` contient des PDF de référence (articles cités dans `doc.md`), pas des données utilisées par les scripts — optionnel.

Une fois `data/raw/` en place, relance le pipeline dans l'ordre décrit ci-dessous depuis la racine du repo.

Structure :
- `data/raw/` — fichiers sources bruts (Excel, CSV, zips OCDE/OMC), non versionnés, voir ci-dessus
- `data/interim/` — sorties intermédiaires du pipeline de nettoyage
- `data/processed/digital_flows.csv.zip` — table dyadique finale (edgelist pays × pays × année), utilisée par les scripts d'analyse
- `data/validation/` — rapports de validation (ex. couverture des NA sur l'IDP)

## Pipeline

Les scripts dans `scripts/` reconstruisent `digital_flows.csv` à partir de `data/raw/` (nécessite donc les fichiers raw) :

1. `00_process_attributes.py` — extrait le modèle de gouvernance de chaque pays depuis `Data_localization.xlsx`
2. `01_clean_idp_data.py` — nettoie les données IDP (distance politique) depuis le zip Dataverse
3. `01b_impute_idp.py` — impute l'IDP manquant (Suisse, Congo, Côte d'Ivoire, Afghanistan) par l'année la plus proche
4. `02_fetch_wto_data.py` — traite les données de commerce de services (OCDE/OMC, BPM5 et BPM6)
5. `03_generate_skeleton.py` — construit le squelette dyadique (toutes les paires de pays × années, avec et sans certification)
6. `04_final_merge.py` — fusionne tout en `data/processed/digital_flows.csv` (+ zip)
7. `05_validate_idp.py` / `05_validate_idp.R` — valide la couverture de l'IDP dans le jeu final
8. `06_estimate_model.R` — estime le modèle logit de survie en temps discret (VD = `is_certified_event`) et produit `output/certification_model.rds`, `output/coefficients_plot.png`, `output/model_results.txt`

Tous les scripts s'exécutent depuis la racine du repo (chemins relatifs, ex. `Rscript scripts/06_estimate_model.R` depuis la racine).

## Analyses

Le dossier `analysis/` contient les scripts d'exploration et de visualisation (indépendants du pipeline ci-dessus, lisent directement `data/processed/digital_flows.csv`) :

- `01_*` — statistiques descriptives et visualisations du réseau
- `02_*` — carte interactive du réseau (plotly)
- `03_safe_harbor_certification_targets.R` — les pays safe harbor certifient-ils des pays non safe harbor ?
- `04_safe_harbor_no_certifications.R` — quels pays safe harbor n'ont certifié personne ?

Les figures sont écrites dans `analysis/plots/`. Le rapport `analysis/rapport_avancees.qmd` compile les réponses aux questions de la rencontre du 6 mai avec les graphiques correspondants (se génère avec `quarto render analysis/rapport_avancees.qmd`, nécessite Quarto).

## Variable dépendante

Deux variantes de la certification sont disponibles dans `digital_flows.csv` :
- `is_certified_state` — la dyade est certifiée cette année-là (stock, reste à 1 une fois certifiée)
- `is_certified_event` — l'année où la certification a lieu (événement, utilisé comme VD dans le modèle de survie)

