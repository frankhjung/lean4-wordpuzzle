.DEFAULT_GOAL := default

CD	:= cd
LEAN_PREFIX := $(shell lean --print-prefix 2>/dev/null)
ifeq ($(LEAN_PREFIX),)
	echo Lean not found. Please ensure Lean 4 is installed and available in your PATH.
	exit 1
endif
LAKE	:= LD_LIBRARY_PATH="$(LEAN_PREFIX)/lib" lake
RM	:= rm -rf

.PHONY: all default build test lint doc clean update help exe

default: build lint test ## Default goal: build, test and lint the project

all: build test lint doc ## Build, test, lint and generate documentation

help: ## Show this help message
	@echo ""
	@echo "Default goal: ${.DEFAULT_GOAL}"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## Build the project using Lake
	@$(LAKE) build

test: ## Run the tests using Lake
	@$(LAKE) test

exe: ## Run the `wordpuzzle` executable with a sample name
	@$(LAKE) exe wordpuzzle -s 6 -m c -l cadevrsoi

lint: ## Run the linter
	@$(LAKE) lint

doc: ## Generate documentation using Lake
	@$(CD) docbuild && \
	$(LAKE) update doc-gen4 && \
	$(LAKE) build Wordpuzzle:docs

viewdoc: ## View generated documentation locally
	@exo-open --launch WebBrowser docbuild/.lake/build/doc/index.html

update: ## Update the dependencies using Lake
	@$(LAKE) update
	@$(CD) docbuild && \
	$(LAKE) update doc-gen4

clean: ## Clean the build artifacts
	@$(LAKE) clean

cleanall: ## Completely clean the project by removing build artifacts and the build directory
	@$(RM) .lake docbuild/.lake
