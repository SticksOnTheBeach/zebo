# Zebo

A little pink cloud that lives in your Mac's notch. It sleeps when you leave it alone, wakes up when your mouse comes by, talks when you click on it… and faints if you insist too much.

| Closed notch: Zebo sleeps, widgets on the right | Open notch: Zebo is awake |
| --- | --- |
| ![Closed notch](docs/notch-closed.png) | ![Open notch](docs/notch-open.png) |

The app's interface is in French.

## What Zebo does

- **It gets set up.** On first launch, the open notch offers "Configurer Zebo". Click it and the notch detaches: its shape glides to the center of the screen and turns into a frosted-glass window (inspired by Alcove's onboarding). Zebo introduces itself, then a few animated steps follow:
  1. **Your first name**: what Zebo will call you ("Enchanté, … !").
  2. **Your favorite language**, among a dozen, each with its real logo.
  3. **Your code editors** (one or more): VS Code, Cursor, Xcode, the JetBrains IDEs… Click one and Zebo finds where it is installed on its own (or you point to it), so it can launch it later.
  4. **Its AI** (optional): Claude, ChatGPT, Gemini or Mistral, with that provider's API key, kept in the macOS Keychain, so Zebo can use it to find where your projects belong.
  5. **Its notch**: what the right wing shows (time, date, today's commits, your language) and whether Zebo naps, with a live preview.
  6. **A summary**, then "C'est parti": the window fades away while Zebo alone flies to the center of the screen, winks, and flips his way back into the notch.

  While being set up, Zebo has a Dock icon. To run the setup again: right-click the notch, **Reconfigurer Zebo…**
- **It helps with your projects.** The open notch has its tabs in a column on the right: **Accueil**, **Projets**, **IA**, and **Paramètres** at the bottom. The Projects tab lists the recent projects created with Zebo: click one and it unfolds into an "Ouvrir avec" row (your editors, the usual one first, then the Finder and the Terminal). Its **Nouveau** button: the notch detaches into a window where you pick the kind (Web, C, C++, Python, Rust, Java, Swift, Kotlin, Go, C#), name the project, then Zebo looks for an existing workspace for that kind in your projects folder and asks whether to use it or create a new one. Finally it creates the project (starter files, a Git repository), opens it in the editor you chose, and flips back into the notch.
- **It chats.** The **IA** tab is a conversation with Zebo himself: the AI you picked lends him its powers, but he answers as Zebo (a warm, slightly cheeky little cloud who calls you by your first name), in two or three sentences. The notch grows on this tab and stays open while you type; while he looks for an answer, he looks thoughtful. The last 20 messages are sent with each question; "recommencer" starts over.

  Zebo can also **act on your Mac** from the chat: "ouvre Cursor", "ouvre Mon jeu dans le Terminal", "crée-moi un projet en Rust". The AI answers with a sentence and one action from a closed list (open an editor, open a project with an editor, the Finder or the Terminal, create a project), choosing only among your editors (the ones picked during setup, then the ones installed on the Mac) and your projects; it never runs a command. When something is missing, like which kind of project, Zebo asks first. To create a project, a card springs up in the notch (which opens on the IA tab if needed): the name Zebo suggests, to keep or rewrite, and your editors to pick from, the one he suggests already selected; Return creates, Escape cancels. The project goes to the workspace of its kind, gets its starter files and a Git repository, and opens right away in the editor.

  Zebo also **codes**: "code-moi un site en TypeScript avec Qwik et Tailwind". He works inside a project's folder, one step at a time: list and read its files, write whole files, run commands (npm, git, cargo…) with zsh. Each step's result, a file's content or a command's output and exit code, goes back to the AI, which keeps going until the task is done, then sums it up. While he works, the notch opens wide on a little terminal where his commands and their output scroll by live; **Stop** interrupts him. Writing files is asked once per task and each command every time (in the Y/N window), unless allowed in the settings. He never leaves the project folder, never uses `sudo`, never wipes your disk, and doesn't start endless dev servers: commands run without a keyboard (`CI=1`) and stop after five minutes.

  Zebo can also **take initiatives**: one extra action he proposes on his own, like opening the Terminal in the project he just created. It drops from under the notch in a small notch-wide window with **N Refuser** and **Y Accepter**: click, or hold the key, and an outline draws itself around the button until it is decided (a quick tap does nothing, so typing elsewhere can't accept by accident; Escape refuses). Accepted, he does it; refused, he remembers that too. What he does shows under his answer (running, done, failed), and he remembers it in the conversation.
- **It asks before acting, unless you allow it.** The **Autorisations** settings let Zebo open your editors, open your projects, offer new ones, write code or run commands without the Y/N window (a project still goes through its card, for its name). They also open the macOS privacy settings, to grant folder access once and for all instead of being asked again.
- **It asks an AI where your projects belong.** With an API key, Zebo sends the AI you picked the names of the folders in your projects folder and their file counts per extension, never file contents, and gets back which folders are workspaces for the chosen kind, with a reason. Each provider is called over plain HTTPS with a JSON schema for the answer:

  | AI | API | Default model |
  | --- | --- | --- |
  | Claude (Anthropic) | Messages | `claude-opus-5-5` (low effort, server-side fallback on refusal) |
  | ChatGPT (OpenAI) | Responses | `gpt-6-luna` |
  | Gemini (Google) | `generateContent` | `gemini-3.8-flash` |
  | Mistral | Chat completions | `mistral-small-latest` |

  The model can be changed in the settings. Without a key, or if the call fails, Zebo guesses locally from folder names and file types.
- **It has settings.** **Paramètres** in the notch, **Zebo > Réglages…** (⌘,) or a right-click on the notch opens a settings window, with a sidebar like System Settings: general (first name), language, editors, notch, AI (provider, model, API key saved or deleted on the spot) and advanced (run the setup again, quit). Changes apply right away.
- **It makes an entrance.** At launch, the notch grows and Zebo pops up with a bounce among sparkles, his name slides next to him, he says hi ("Salut Maël, on code ?") and winks with a golden sparkle; then the notch closes and he goes back to bed.
- **It sleeps.** When the notch is closed, it lies in its bed in the left wing, wearing a nightcap, under its blanket; little "z"s float away from its head.
- **It keeps you posted.** The right wing of the closed notch shows the widgets you picked: the time, the date, today's commits, your favorite language. With several of them, they take turns every 5, 10 or 30 seconds. Today's commits are counted with Git in the repositories of your projects folder (guessed, e.g. `~/Documents/Dev`), using your `git config user.email`, every 5 minutes.
- **It wakes up.** When the mouse hovers the closed notch, it grows slightly, like [Alcove](https://tryalcove.com); a click opens it: the bed fades away, Zebo stands up, follows the mouse with its eyes, blinks and sways gently. The notch closes again when the mouse leaves.
- **It talks.** Clicking on it shows a line (with your first name) in a cloud-shaped bubble, typed letter by letter, linked to Zebo by dots that pop in one by one. While talking, it looks thoughtful 🤔 (raised eyebrows, pout, eyes up). A new message can only start after 4 s.
- **It faints.** Three clicks within 1.5 s knock it out: spiral eyes, stars around its head, it wobbles… then it gets catapulted out of the notch, spins across the screen and pops back a few seconds later.

To quit Zebo: right-click the notch, then **Quitter Zebo**. Zebo only has a Dock icon while one of its windows is open.

## Installation

### Download

Each version is on the [Releases page](https://github.com/SticksOnTheBeach/zebo/releases) (see also the [changelog](CHANGELOG.md)): download `Zebo-<version>.zip`, unzip it and move `Zebo.app` to Applications. Zebo isn't notarized by Apple, so the first time, right-click `Zebo.app` and choose **Ouvrir** (or run `xattr -dr com.apple.quarantine /Applications/Zebo.app`). Requires macOS 14 or later.

### From the sources

Requirements: macOS 14 or later, Xcode 16 or later (Swift 6).

```sh
git clone https://github.com/SticksOnTheBeach/zebo.git
cd zebo
make run
```

`make run` builds the project, assembles `build/Zebo.app` and launches it (replacing a running instance). No permission is requested: following the mouse doesn't need any.

On a screen without a notch, Zebo draws a fake notch in the middle of the menu bar.

## Commands

```sh
make run      # build, assemble Zebo.app and launch it
make package  # release build, zipped in build/Zebo-<version>.zip for a GitHub release
make release  # package, then publish the GitHub release of the current version (tools/release)
make tools    # test and type-check the release tool (TypeScript)
make build    # build only
make test     # unit tests
make lint     # check the style without changing anything
make format   # format the code
make help     # list the commands
```

`make build`, `make test` and `make run` build in `~/Library/Caches/zebo-build`: when the repository lives in an iCloud-synced folder (like `~/Documents`), iCloud adds Finder attributes to built bundles and their code signing fails. A plain `swift build` / `swift test` works if the repository is elsewhere.

To start over from scratch (setup and preferences): `defaults delete com.sticksonthebeach.zebo`, or, in a debug build, right-click the notch and pick **Réinitialiser Zebo**.

## Architecture

The package is split into three modules, each depending only on the previous ones:

| Module | Role | Depends on |
| --- | --- | --- |
| `ZeboCore` | Pure logic and observable state: click rules, fall trajectory, lines, notch model, widgets, preferences, editors and commits, setup flow and wizard. No SwiftUI, no AppKit. | — |
| `ZeboUI` | SwiftUI views: the character, the notch and its widgets, the speech bubble, the bed, the fall, the setup. | `ZeboCore` |
| `Zebo` | The app: AppKit entry point, windows, mouse tracking, notched screen detection, Git and editor lookup. | `ZeboCore`, `ZeboUI` |

```
Sources/
├── ZeboCore/
│   ├── AI/          AIProvider, AIClient and one client per AI (Claude, OpenAI, Gemini, Mistral), AIPrompt,
│   │                AIWorkspaceAdvisor + WorkspaceQuestion, SmartWorkspaceAdvisor (the chosen AI, then local),
│   │                HTTPTransport
│   ├── Chat/        ZeboChat (a conversation with Zebo, answered by the chosen AI), ZeboAction (what he can
│   │                do on the Mac), ActionQuestion (JSON answer, from the AI's request to a real action),
│   │                ProjectDraft (the new project card), ZeboInitiatives (proposals, held Y or N),
│   │                ZeboPermission (what Zebo may do without asking), ZeboTerminal (live command output),
│   │                CodingSafety (stay in the project, forbidden commands)
│   ├── Behavior/    ZeboBehavior (reactions to clicks), PokeTracker (rules)
│   ├── Code/        IDE (editor catalog), Language, CommitActivity (today's commits), ProjectsFolder
│   ├── Notch/       NotchModel (notch geometry, tabs), ZeboPlacement, DetachedWindowFlow (notch → window → notch)
│   ├── Physics/     Flight (fall trajectory)
│   ├── Preferences/ ZeboPreferences, ZeboSettings (preferences and their storage)
│   ├── Projects/    ProjectKind, WorkspaceAdvisor (+ local), ProjectTemplate, ProjectScaffolder,
│   │                NewProjectWizard, ProjectsLibrary (+ ProjectOpenTarget)
│   ├── Setup/       SetupFlow, SetupWizard (steps), SetupStore
│   ├── Speech/      ZeboSpeech (typewriter), SpeechLineSource and PersonalizedLines (lines), ZeboSpeaking
│   └── Widgets/     NotchWidget, NotchWidgetRotation (what shows when)
├── ZeboUI/
│   ├── Character/   ZeboCharacter (drawing), AnimatedZebo (life), ZeboMood, Shapes/
│   ├── Components/  ZeboButtonStyle, PageDots, .appearing (staggered appearance), VisualEffectBackground,
│   │                SparkleField, AIProviderBadge
│   ├── Fall/        FallingZeboView
│   ├── Initiatives/ InitiativeView (Zebo's proposal), HoldToConfirmButton (outline drawn while held)
│   ├── Notch/       NotchView, NotchShape, NotchWidgetsView (rotating widgets), NotchClock, NotchTabBar,
│   │                ProjectsTabView, AITabView (the chat), ProjectDraftCard, NotchTerminalView, LaunchSplash
│   ├── Projects/    NewProjectView (window), Steps/ (kind, name, workspace, editor)
│   ├── Resources/   Languages/ (language and project kind logos, SVG)
│   ├── Setup/       SetupView (window), SetupBackground (glass), Steps/ (one view per step), SetupTransitionView and
│   │                NotchToWindowShape (notch → window), SetupFinaleView (wink and flip back), NotchPreview,
│   │                SetupPrompt (notch button)
│   ├── Settings/    SettingsView (sidebar), SettingsSection, SettingsRow, AISettingsPage,
│   │                PermissionsSettingsPage, AdvancedSettingsPage
│   ├── Sleep/       InBed (the bed), SleepingZs (the "z"s)
│   ├── Speech/      SpeechBubbleView, CloudBubbleShape, CappedWidth
│   └── ZeboPalette
└── Zebo/
    ├── AI/          KeychainAPIKeyStore
    ├── App/         ZeboApp (entry point), AppDelegate, MainMenu, AppPresence (Dock icon), DevReset
    ├── Chat/        MacActions (opens editors and projects, creates projects), ProjectFiles (list, read,
    │                write inside a project), CommandRunner (zsh, live output, timeout, stop)
    ├── Code/        WorkspaceApplicationLocator (finds editors), Git, GitCommitCounter (counts commits),
    │                FolderScanner (describes the projects folder), ProjectOpener, ProjectCreator
    ├── Extensions/  NSScreen+Notch
    ├── Input/       MouseMonitor
    └── Windows/     NotchController, OverlayPanel, DetachedWindowController (windows born from the notch),
                     SetupWindowController, ProjectWindowController, SettingsWindowController,
                     InitiativeWindowController (proposals under the notch, Y and N keys)
Tests/
└── ZeboCoreTests/
tools/
└── release/         The release tool, in TypeScript: version from Info.plist, notes from CHANGELOG.md,
                     GitHub release with the zip attached (src/, test/)
```

The app uses three transparent windows above the menu bar: the notch itself, the speech bubble right below it, and a full-screen window shown only while Zebo falls. Setup and new projects add a full-screen window for the animations, then a regular app window; Zebo then becomes a "normal" app (Dock icon, menu bar) and goes back to being discreet when the window closes.

A few design choices:

- **Rules are pure.** `PokeTracker` and `Flight` take the date and the random generator as parameters, which makes them testable.
- **Dependencies go through protocols.** `ZeboBehavior` only knows `ZeboSpeaking` and `ZeboPlacement`, not the concrete classes; tests use fakes. The same goes for `ApplicationLocator`, `CommitCounter`, `WorkspaceAdvisor`, `HTTPTransport` and `APIKeyStore`: the AI clients are tested without any network call.
- **The AI can't invent paths.** Its answer is constrained by a JSON schema, and any path it returns that wasn't in the folders sent to it is dropped.
- **Lines are swappable.** `ZeboSpeech` takes a `SpeechLineSource`: plugging in an AI only means writing a new source.
- **Animations stay in the views.** Models change state, views decide how to animate it (`.animation(_:value:)`).
- **One mood at a time.** `ZeboMood` (calm, thinking, dizzy, sleeping) drives Zebo's expression, with no booleans that could contradict each other.
- **The character is drawn on a 100 × 100 grid.** It adapts to any size, from the closed notch to the open one.
- **Old preferences keep working.** `ZeboPreferences` decodes missing settings with their defaults and migrates older formats (single editor, clock-only notch).

## Tests

Tests cover `ZeboCore` with [Swift Testing](https://developer.apple.com/documentation/testing): click rules, trajectory and ejection, lines, speech (typewriter, silence), behavior from clicks to ejection, notch geometry, widgets and their rotation, preferences (and migration of old ones), editors, today's commits, setup (flow, wizard, storage), workspace detection (local and with every AI, with a fake transport), the chat with Zebo, the actions he takes from it, the new project card and his initiatives (held keys included), the AI and model preferences, project templates and creation, the new project wizard and the projects library.

`ZeboUI` views have no isolated logic: they are checked by eye, by running the app. For a screenshot or a preview without appearance animations: `.environment(\.showsFinalAppearance, true)`.

Time-dependent tests don't wait for a fixed duration: `waitUntil` (in `Tests/ZeboCoreTests/Support/`) checks the condition every 10 ms up to a timeout.

## Conventions

- Code (types, functions, variables), commit messages and this README in English; code comments, tests and the app's interface in French.
- Style checked by [swift-format](https://github.com/swiftlang/swift-format) (`.swift-format`: 4 spaces, 120 columns). Run `make format` before committing.
- One file per type. SwiftUI shapes end with `Shape`.
- Small commits, one per logical step, following [Conventional Commits](https://www.conventionalcommits.org/) with a scope: `feat(behavior): …`, `tweak(fall): …`, `refactor(speech): …`.
- Tests with Swift Testing, one suite per type, each test described in one sentence.
- Releases: bump the version in `Info.plist`, add it to `CHANGELOG.md`, tag `vX.Y.Z` (annotated) and push the tag, then `make release`. The token is `GH_TOKEN`, or the one git already uses for github.com.
- Tooling around the app is in TypeScript (`tools/`), run directly by Node 23.6+ (type stripping), tested with `node:test` and type-checked with `tsc`. The app itself stays in Swift.

## Credits

Language logos come from [Devicon](https://devicon.dev) (MIT license, see `Sources/ZeboUI/Resources/Languages/LICENSE-devicon.txt`). The Swift logo's path data was rewritten to the standard SVG arc syntax so macOS can draw it; the drawing is unchanged. Logos are trademarks of their respective owners.

## What's next

- A shortcuts tab in the notch, to launch the editors picked during setup.
- Starting a project from a template chosen by the AI, or adding an existing project to the library.
- The Accueil tab still says "SOON… In progress…".
- Answers streamed word by word in the IA tab, and Zebo knowing about your projects when you chat.
