# Changelog

Every version of Zebo, newest first. Versions follow [Semantic Versioning](https://semver.org); until 1.0, a minor version can change anything. Each one has its tag and its [GitHub release](https://github.com/SticksOnTheBeach/zebo/releases).

## 0.7.0 — Initiatives and permissions (2026-10-07)

- **New project card.** Asking Zebo for a project opens a card in the notch: the name he suggests, to keep or rewrite, and your editors to pick from. Return creates, Escape cancels.
- **Initiatives.** Zebo can propose one extra action on his own, like opening the Terminal in the project he just created. It drops from under the notch with **N Refuser** and **Y Accepter**: click, or hold the key while an outline draws itself around the button.
- **Autorisations** in the settings: let Zebo open your editors, open your projects or offer new ones without asking, and shortcuts to the macOS privacy settings so it stops asking for folder access.
- `make package` builds a release `Zebo.app` and zips it for a release.

## 0.6.0 — Talk with Zebo (2026-10-06)

- **IA tab** in the notch: a conversation with Zebo himself, powered by the AI you picked. He tutoies you, calls you by your first name and answers in a few sentences.
- **Zebo acts on your Mac** from the chat: open an editor, open a project (editor, Finder, Terminal), create a project. The AI picks from a closed list of actions, never a command.
- An Edit menu, so ⌘V pastes the API key, and a paste button next to the field.

## 0.5.0 — Settings and your choice of AI (2026-10-06)

- **Settings window** (⌘, or from the notch), with a System Settings-like sidebar reusing the setup screens.
- **Your choice of AI**: Claude, ChatGPT, Gemini or Mistral, one API key each in the Keychain, and the model editable.
- Notch tabs in a column on the right; a project unfolds into an "Ouvrir avec" row (editors, Finder, Terminal).
- Zebo keeps a Dock icon while any of his windows is open.

## 0.4.0 — Projects (2026-10-06)

- **Projets tab** in the notch and a **new project window** born from the notch: kind (Web, C, C++, Python, Rust…), name, workspace, editor.
- Zebo finds the workspace for that kind in your projects folder, with Claude when you give it a key (only folder names and file counts are sent), or on his own.
- Projects are created with starter files and a Git repository, then opened in your editor.

## 0.3.0 — Alcove style (2026-10-06)

- Frosted-glass setup window with aurora colors and sparkles, and a big welcome.
- The closed notch grows slightly when hovered, and opens on click.
- Setup finale: Zebo flies to the center of the screen, winks with a golden sparkle, and flips back into the notch.

## 0.2.0 — Setup (2026-10-05)

- First launch: "Configurer Zebo" detaches the notch into a setup window, with animated steps.
- Your first name, your favorite language (with real logos), your code editors (found on the Mac automatically).
- Notch widgets that take turns: time, date, today's commits, your language.

## 0.1.0 — Zebo in the notch (2026-10-05)

- A pink cloud in the notch that follows the mouse with his eyes, blinks and sways.
- Click him and he talks, looking thoughtful; click too much and he faints, gets catapulted out of the notch and pops back.
- He sleeps in his bed with a nightcap when the notch is closed, next to the time.
