# Changements

## 1.2.0

- Paramètre `theme` commun à la signature, à la galerie et aux fiches d’apps.
- Enum `CroaTheme` : `.system`, `.pond`, `.paper` et `.custom(...)`.
- Fonds transparents, unis ou en dégradé ; couleurs d’accent et de texte personnalisables.
- Enum `CroaFont` : système, arrondie, serif, monospace ou police personnalisée avec Dynamic Type.
- Sélecteur de thèmes dans la démo et exemples d’intégration dans le README.
- Les appels existants conservent le thème système par défaut.

## 1.1.0

- Galerie SwiftUI des apps du collectif avec `CroaKit.communityApps()`.
- Connexion au catalogue public cmdf.io, recherche, catégories, filtres et fiches d’apps.
- Lien direct pour proposer une application via cmdf.io.
- Client réseau utilisable séparément et tests sans dépendance au service en production.
- Licence MIT du code, conditions d’usage distinctes pour la grenouille, guide et liste des contributions.

## 1.0.0

- Signature SwiftUI avec nom de l’app, prénom, version et build.
- Grenouille vectorielle animée par Metal, clin d’œil au tap et saut par appui long.
- Illustrations et shader inclus dans le package SPM, sans dépendance externe.
