# finess_etalab

Travaux autour des extractions Finess de data.gouv.fr

## Contexte

Proposer des programmes R (non sous forme de package pour le moment) permettant d'intégrer simplement et sans trop se poser de questions les fichiers finess de data.gouv.fr.

Les fichiers pris en charge actuellement sont :

- [Entités juridiques (501)](https://www.data.gouv.fr/fr/datasets/finess-extraction-des-entites-juridiques/#_)
- [Entités géographiques géolocalisées (507)](https://www.data.gouv.fr/fr/datasets/finess-extraction-du-fichier-des-etablissements/)

## Structure du projet

- [télécharger](https://github.com/GuillaumePressiat/finess_etalab/blob/master/pgm/telechargement.R) les fichiers d'extractions les plus récents sur le site depuis le site data.gouv.fr
- un [programme](https://github.com/GuillaumePressiat/finess_etalab/blob/master/pgm/extraire_formats_2.R) permet d'extraire les formats du fichier pdf décrivant les données (notice), cela évite des manipulations manuelles même si ensuite j'ai vérifié manuellement la justesse du résultat
- à partir de ces formats normés (501 pour les entités juridiques, 507 pour les établissements gélocalisés), le programme [importer.R](https://github.com/GuillaumePressiat/finess_etalab/blob/master/pgm/importer.R) intègre les fichiers et les réexporte sous forme de rds et csv
- un [programme](https://github.com/GuillaumePressiat/finess_etalab/blob/master/pgm/ajout_coordonnees_wgs84.R) permet d'homogénéiser les projections de géolocalisation en convertissant les différentes projections en WGS 84


## Présentation du projet

Un R "bloc notes" est disponible [ici](https://guillaumepressiat.github.io/finess_etalab/rmd/import_etalab.html). 

