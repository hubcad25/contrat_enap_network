- boxplot: mettre IDP sur l'axe des y

- Modèle: si snapshot d'une année avec state comme VD, prendre l'idp au moment de la certif ou pendant le snapshot?
    - On serait donc mieux de faire modele sur toutes les années et prendre event comme VD

- Pour pays comme Suisse, Congo, Cote d'ivoire, Afghanistan
    - Prendre les données IDP de l'année la plus proche pour imputer leurs NA

- Clustering/PCA sur flux economiques? pertinent?

- Danemark et Pays-Bas cas spéciaux dans modele de gouv dans notre categorisation

- Est-ce que les pays safe harbor certifient des pays qui sont pas safe harbor?
    - VD: modele de gouv des pays qui sont certifiés par des SH

- Liste des pays SH qui ont certifié personne


### Qu'est-ce qui a été fait

- Imputation de l'IDP (Suisse, Congo, Côte d'Ivoire, Afghanistan) par l'année la plus proche.
- Estimation d'un modèle de survie en temps discret (1995-2024) sur les événements de certification (8cg.1).
    - Variables standardisées pour faciliter l'interprétation.
    - Résultats clés : effet négatif de la distance politique (IDP) et effet positif du partage d'un même modèle de gouvernance.
    - Graphique des coefficients disponible dans `output/coefficients_plot.png`.

