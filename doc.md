 Salut Hubert,

Tu trouveras ci-joint le feuille Excel que j’ai préparé pour colliger les données. Je joins une deuxième feuille Excel pour le modèle de gouvernance des flux de données. Au lieu de l’intégrer dans ce qui équivaut à notre edgelist, je pense que l’idéal est de se créer un document séparé pour les attributes de nos nodes (acteurs). J’aimerais simplement que tu indiques pour chaque année, le nom d’un pays et s’il maintient un modèle de gouvernance ouvert (aucune restriction, safe harbor = 0 et data localization = 0), safe harbor (comp_safeharbor = 1), et localization (comp_local = 1). Tu peux aussi indiquer 0, 1, 2 si tu préfères, mais indique quelque part quel chiffre est associé à quelle variable. 

Tu trouveras ci-dessous les liens pour aller chercher l’information pour les variables indépendantes:
1. UN voting Ideal distance point: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/LEJUQZ 
& 
Le papier qui introduit cette base de données : https://journals.sagepub.com/doi/full/10.1177/0022002715595700 
2. COW country code: https://correlatesofwar.org/cow-country-codes/ 
3. Services imports and exports https://www.wto.org/english/res_e/statis_e/trade_datasets_e.htm 
4. List of digital services pour extraire les services numériques de la base de données de l’OMC: https://onlinelibrary.wiley.com/doi/full/10.1111/roie.12735?casa_token=TuSrFfo3omkAAAAA%3Azk5G2yCXjXIO7OZGkK30-Dcr5m8wusjMyciQHiGZCNWzwNgYTalOTblySPdZsDZ2uh0qTZkSXoKk--U 

Et voici un lien vers un papier qui compare les deux principales méthodes que je connais pour analyser de façon longitudinale et inférentielle l’évolution de la structure d’un réseau: https://journals.sagepub.com/doi/abs/10.1177/0049124116672680

Pour rappel, tu peux prendre 1995 (ou la date la plus récente) comme point de départ pour la collecte de données.

Pour modèle de gouvernance, on veut une dummy 1 oui les 2 pays ont le meme modele 0 non les pays n'ont pas le meme modele

Les fichiers dans data/ contiennent seulement les accords entre pays. On veut également avoir les pays qui n'ont pas d'accords entre eux/les pays avec aucun accord pour avoir des observations de contrôle.