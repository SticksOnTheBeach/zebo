# Zebo

Un petit nuage rose qui vit dans la notch du Mac. Il suit la souris des yeux, parle quand on clique dessus… et tombe dans les pommes si on insiste trop.

Prérequis : macOS 14 ou plus récent, Xcode 16 ou plus récent (Swift 6).

## Commandes

```sh
make run      # compile, assemble Zebo.app et le lance
make test     # tests unitaires
make lint     # vérifie le style
make format   # formate le code
```

`make test` compile dans `~/Library/Caches/zebo-build` : si le dépôt est dans un dossier synchronisé par iCloud (comme `~/Documents`), iCloud ajoute des attributs Finder aux bundles compilés et la signature du bundle de tests échoue.

## Architecture

Le paquet est découpé en trois modules, chacun ne dépendant que des précédents :

| Module | Rôle | Dépend de |
| --- | --- | --- |
| `ZeboCore` | Logique pure et état observable : règles des clics, trajectoire de chute, répliques, modèle de la notch. Ni SwiftUI ni AppKit. | — |
| `ZeboUI` | Vues SwiftUI : le personnage, la notch, la bulle de dialogue, la chute. | `ZeboCore` |
| `Zebo` | L'app : fenêtres AppKit, suivi de la souris, détection de l'écran à encoche. | `ZeboCore`, `ZeboUI` |

```
Sources/
├── ZeboCore/
│   ├── Behavior/   ZeboBehavior (réactions aux clics), PokeTracker (règles)
│   ├── Notch/      NotchModel (géométrie et état de la notch), ZeboPlacement
│   ├── Physics/    Flight (trajectoire de la chute)
│   └── Speech/     ZeboSpeech (machine à écrire), SpeechLineSource (répliques)
├── ZeboUI/
│   ├── Character/  ZeboCharacter (dessin), AnimatedZebo (vie), ZeboMood, Shapes/
│   ├── Notch/      NotchView, NotchShape
│   ├── Speech/     SpeechBubbleView, CloudBubbleShape, CappedWidth
│   ├── Fall/       FallingZeboView
│   └── ZeboPalette
└── Zebo/
    ├── App/        ZeboApp, AppDelegate
    ├── Windows/    NotchController, OverlayPanel
    ├── Input/      MouseMonitor
    └── Extensions/ NSScreen+Notch
Tests/
└── ZeboCoreTests/
```

Quelques choix :

- **Les règles sont pures.** `PokeTracker` et `Flight` reçoivent la date et le générateur aléatoire en paramètres, ce qui les rend testables.
- **Les dépendances passent par des protocoles.** `ZeboBehavior` ne connaît que `ZeboSpeaking` et `ZeboPlacement`, pas les classes concrètes ; les tests utilisent de faux objets.
- **Les répliques sont interchangeables.** `ZeboSpeech` reçoit un `SpeechLineSource` : pour brancher une IA, il suffit d'écrire une nouvelle source.
- **Les animations restent dans les vues.** Les modèles changent l'état, les vues décident comment l'animer (`.animation(_:value:)`).
- **Une humeur à la fois.** `ZeboMood` (calme, pensif, sonné) remplace des booléens qui pouvaient se contredire.

## Conventions

- Code (types, fonctions, variables) en anglais ; commentaires, messages de commit et tests en français.
- Style vérifié par [swift-format](https://github.com/swiftlang/swift-format) (`.swift-format` : 4 espaces, 120 colonnes). Lancer `make format` avant de committer.
- Un fichier par type. Les formes SwiftUI se terminent par `Shape`.
- Petits commits, un par étape logique, au format [Conventional Commits](https://www.conventionalcommits.org/fr/) avec un scope : `feat(behavior): …`, `tweak(fall): …`, `refactor(speech): …`.
- Tests avec [Swift Testing](https://developer.apple.com/documentation/testing), une suite par type, chaque test décrit en une phrase.
