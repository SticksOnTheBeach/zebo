import Foundation

/// Les fichiers de départ d'un nouveau projet : de quoi lancer un « Hello » tout de suite.
public enum ProjectTemplate {
    /// Chemin relatif → contenu.
    public static func files(for kind: ProjectKind, name: String) -> [String: String] {
        var files = specificFiles(for: kind, name: name)
        files["README.md"] = "# \(name)\n\nProjet \(kind.name) créé avec Zebo ☁️\n"
        files[".gitignore"] = gitignore(for: kind)
        return files
    }

    /// Le nom réduit à des lettres, chiffres et tirets, en minuscules (paquets Rust, modules Go…).
    static func slug(_ name: String) -> String {
        let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        let parts = folded.split { !$0.isLetter && !$0.isNumber }
        return parts.isEmpty ? "projet" : parts.joined(separator: "-")
    }

    /// Le nom en un seul mot qui commence par une majuscule (cibles Swift, projets C#).
    static func identifier(_ name: String) -> String {
        let words = slug(name).split(separator: "-").map { $0.prefix(1).uppercased() + $0.dropFirst() }
        let joined = words.joined()
        return joined.first?.isLetter == true ? joined : "Projet" + joined
    }

    private static func specificFiles(for kind: ProjectKind, name: String) -> [String: String] {
        switch kind {
        case .web:
            [
                "index.html": """
                <!doctype html>
                <html lang="fr">
                  <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <title>\(name)</title>
                    <link rel="stylesheet" href="style.css">
                  </head>
                  <body>
                    <h1>\(name)</h1>
                    <script src="script.js"></script>
                  </body>
                </html>

                """,
                "style.css": "body {\n  font-family: system-ui, sans-serif;\n  margin: 2rem;\n}\n",
                "script.js": "console.log(\"Hello depuis \(name) !\");\n",
            ]
        case .c:
            [
                "main.c":
                    "#include <stdio.h>\n\nint main(void) {\n    printf(\"Hello depuis \(name) !\\n\");\n    return 0;\n}\n"
            ]
        case .cpp:
            [
                "main.cpp":
                    "#include <iostream>\n\nint main() {\n    std::cout << \"Hello depuis \(name) !\" << std::endl;\n    return 0;\n}\n",
                "CMakeLists.txt":
                    "cmake_minimum_required(VERSION 3.20)\nproject(\(identifier(name)) CXX)\n\nset(CMAKE_CXX_STANDARD 20)\nadd_executable(\(identifier(name)) main.cpp)\n",
            ]
        case .python:
            [
                "main.py":
                    "def main() -> None:\n    print(\"Hello depuis \(name) !\")\n\n\nif __name__ == \"__main__\":\n    main()\n"
            ]
        case .rust:
            [
                "Cargo.toml": "[package]\nname = \"\(slug(name))\"\nversion = \"0.1.0\"\nedition = \"2021\"\n",
                "src/main.rs": "fn main() {\n    println!(\"Hello depuis \(name) !\");\n}\n",
            ]
        case .java:
            [
                "src/Main.java":
                    "public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello depuis \(name) !\");\n    }\n}\n"
            ]
        case .swift:
            [
                "Package.swift": """
                // swift-tools-version: 6.0
                import PackageDescription

                let package = Package(
                    name: "\(identifier(name))",
                    targets: [.executableTarget(name: "\(identifier(name))")]
                )

                """,
                "Sources/\(identifier(name))/main.swift": "print(\"Hello depuis \(name) !\")\n",
            ]
        case .kotlin:
            ["src/Main.kt": "fun main() {\n    println(\"Hello depuis \(name) !\")\n}\n"]
        case .go:
            [
                "go.mod": "module \(slug(name))\n\ngo 1.22\n",
                "main.go":
                    "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello depuis \(name) !\")\n}\n",
            ]
        case .csharp:
            [
                "Program.cs": "Console.WriteLine(\"Hello depuis \(name) !\");\n",
                "\(identifier(name)).csproj": """
                <Project Sdk="Microsoft.NET.Sdk">
                  <PropertyGroup>
                    <OutputType>Exe</OutputType>
                    <TargetFramework>net8.0</TargetFramework>
                    <ImplicitUsings>enable</ImplicitUsings>
                  </PropertyGroup>
                </Project>

                """,
            ]
        }
    }

    private static func gitignore(for kind: ProjectKind) -> String {
        let common = ".DS_Store\n"
        let specific =
            switch kind {
            case .web: "node_modules/\ndist/\n"
            case .c, .cpp: "build/\n*.o\n"
            case .python: "__pycache__/\n.venv/\n"
            case .rust: "target/\n"
            case .java, .kotlin: "out/\n*.class\n"
            case .swift: ".build/\n.swiftpm/\n"
            case .go: "bin/\n"
            case .csharp: "bin/\nobj/\n"
            }
        return common + specific
    }
}
