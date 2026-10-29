# Changements

## 1.4.0

- Carte App Store native (`SKOverlay`) affichée automatiquement à l’ouverture d’une fiche sur iPhone et iPad pour installer l’app sans quitter la présentation.
- Carte refermable, masquée à la fermeture de la fiche et non réaffichée lors d’une actualisation.
- Lien App Store conservé en secours et sur macOS ; seuls les identifiants App Store valides sont transmis à StoreKit.

## 1.3.0

- Lien facultatif **Les apps du collectif** dans le footer, activé avec `showsCommunityLink: true` et masqué par défaut.
- Ouverture de la galerie en feuille avec le thème du footer et l’option `excludingAppStoreID` pour masquer l’app hôte.
- La documentation recommande toujours un vrai lien dédié dans la navigation ou les réglages ; le lien du footer reste un accès complémentaire.
- Réglage dans la démo pour comparer le footer avec et sans le lien.

## 1.2.2

- Texte d’ajout d’app et documentation : l’intégration de CroaKit est requise pour apparaître dans son catalogue.
- Activation manuelle par le collectif, distincte de la publication sur le wall cmdf.io.
- Le filtrage est appliqué par l’API et bénéficie aussi aux versions précédentes du package.

## 1.2.1

- En-tête du catalogue compact : suppression du grand slogan et du paragraphe d’introduction.
- Petite grenouille et mention du collectif intégrées à la ligne du compteur et des catégories.
- Espacements réduits pour afficher les premières apps plus haut, sans réduire les zones tactiles des filtres.

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
