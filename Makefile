# Commandes courantes du projet. `make help` pour la liste.

# Le dépôt vit dans ~/Documents, synchronisé par iCloud : iCloud ajoute des attributs Finder
# aux bundles compilés (tests, ressources), ce qui fait échouer leur signature.
# On compile donc hors d'iCloud (run.sh utilise le même dossier).
BUILD_DIR ?= $(HOME)/Library/Caches/zebo-build
export BUILD_DIR
SOURCES := Sources Tests Package.swift

.PHONY: help build test run package format lint

help: ## Affiche cette aide
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-8s %s\n", $$1, $$2}'

build: ## Compile le projet
	swift build --scratch-path $(BUILD_DIR)

test: ## Lance les tests unitaires
	swift test --scratch-path $(BUILD_DIR)

run: ## Compile, assemble Zebo.app et le lance
	./run.sh

package: ## Prépare build/Zebo-<version>.zip, à joindre à une release
	./package.sh

format: ## Formate tout le code
	swift format --in-place --recursive $(SOURCES)

lint: ## Vérifie le style sans rien modifier
	swift format lint --strict --recursive $(SOURCES)
