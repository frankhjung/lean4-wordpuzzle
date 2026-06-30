.DEFAULT_GOAL := default

CD	:= cd
LEAN_PREFIX := $(shell lean --print-prefix 2>/dev/null)
ifeq ($(LEAN_PREFIX),)
$(error Lean not found. Ensure Lean 4 is installed and available on your PATH.)
endif
LAKE	:= LD_LIBRARY_PATH="$(LEAN_PREFIX)/lib" lake
RM	:= rm -rf

.PHONY: all default build test lint doc clean update help exe

default: build lint test ## Default goal: build, test and lint the project

all: build lint test doc exe ## Build, test document and run the project

help: ## Show this help message
	@echo ""
	@echo "Default goal: ${.DEFAULT_GOAL}"
	@awk 'BEGIN { \
	FS = ":.*##"; \
	printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} \
	/^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' \
	$(MAKEFILE_LIST)

build: ## Build the project using Lake
	@$(LAKE) build

test: ## Run the tests using Lake
	@$(LAKE) check-test
	@$(LAKE) test

exe: ## Run the `wordpuzzle` executable with a sample name
	@$(LAKE) exe wordpuzzle -s 6 -m c -l cadevrsoi

lint: ## Run the linter
	@$(LAKE) check-lint
	@$(LAKE) lint --lint-only Wordpuzzle

doc: ## Generate documentation using Lake
	@$(CD) docbuild && \
	$(LAKE) build Wordpuzzle:docs

viewdoc: ## View generated documentation locally
	@exo-open --launch WebBrowser docbuild/.lake/build/doc/index.html

clean: ## Clean the build artifacts
	@$(LAKE) clean
	@$(CD) docbuild && $(LAKE) clean

update: ## Update the dependencies using Lake
	@$(LAKE) update
	@$(CD) docbuild && \
	$(LAKE) update doc-gen4
