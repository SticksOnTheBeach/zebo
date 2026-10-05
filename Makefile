# Commandes courantes du projet. `make help` pour la liste.

# Le dépôt vit dans ~/Documents, synchronisé par iCloud : iCloud ajoute des attributs Finder
# aux bundles compilés, ce qui fait échouer la signature du bundle de tests.
# On compile donc les tests hors d'iCloud.
TEST_BUILD_DIR ?= $(HOME)/Library/Caches/zebo-build
SOURCES := Sources Tests Package.swift

.PHONY: help build test run format lint

help: ## Affiche cette aide
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-8s %s\n", $$1, $$2}'

build: ## Compile le projet
	swift build

test: ## Lance les tests unitaires
	swift test --scratch-path $(TEST_BUILD_DIR)

run: ## Compile, assemble Zebo.app et le lance
	./run.sh

format: ## Formate tout le code
	swift format --in-place --recursive $(SOURCES)

lint: ## Vérifie le style sans rien modifier
	swift format lint --strict --recursive $(SOURCES)
