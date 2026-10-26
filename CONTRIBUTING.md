# Contribuer à CroaKit

Merci de contribuer aux outils du collectif ⌘+F.

## Ajouter votre application au catalogue

L’ajout se fait sur **[cmdf.io → Proposer mon app](https://cmdf.io/fr/apps#proposer)**, pas par une pull request dans CroaKit.

1. Coller le lien App Store de votre application.
2. Renseigner votre nom et votre adresse e-mail pour le suivi de la proposition.
3. Ajouter, si vous le souhaitez, une présentation, des liens et des captures.
4. Envoyer la proposition. L’équipe du collectif la valide avant publication.

Une fois approuvée, votre app est incluse dans le catalogue cmdf.io et apparaît dans les apps qui l’affichent avec CroaKit lors de leur prochaine actualisation. Le cache du service peut retarder sa visibilité. Ne pas ajouter de liste d’apps en dur dans le package.

## Signaler un problème ou proposer une amélioration

Ouvrir une [issue](https://github.com/cmdfio/CroaKit/issues) avec le comportement attendu, les étapes de reproduction, les versions de Xcode et du système, et une capture si utile. Éviter de publier des données personnelles ou des secrets.

Pour une évolution importante de l’API SwiftUI, décrire l’usage envisagé avant de démarrer une refonte.

## Proposer du code

1. Créer une branche à partir de `main`.
2. Conserver la compatibilité iOS 18 / macOS 15 et Swift 6.
3. Conserver la police système par défaut et respecter le thème choisi, Dynamic Type, VoiceOver et Réduire les animations.
4. Tester les changements de logique et les contrats réseau ; utiliser des réponses simulées pour les tests automatisés.
5. Ouvrir une pull request qui explique le changement et sa vérification.

Depuis la racine du package :

```sh
xcodebuild -scheme CroaKit -destination 'platform=macOS' test
```

Pour vérifier iOS, ouvrir la démo dans `Examples/CroaKitDemo/`. Les illustrations et le shader Metal nécessitent la compilation des ressources par Xcode ; `swift build` seul ne la remplace pas.

Le catalogue n’exige ni clé d’API ni compte. Préserver la validation côté cmdf.io et le caractère facultatif des requêtes réseau : le pied de page seul n’en déclenche aucune.

## Licence et illustrations

Les contributions au code sont proposées sous [licence MIT](LICENSE). La grenouille reste réservée au collectif, selon [ARTWORK-LICENSE.md](ARTWORK-LICENSE.md). Ne pas introduire d’illustrations ou de contenus tiers sans disposer des droits nécessaires.

Les personnes qui contribuent sont visibles dans [CONTRIBUTORS.md](CONTRIBUTORS.md) et l’historique GitHub.
