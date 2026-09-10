.DEFAULT_GOAL := default

CD	:= cd
REQUIRED_LEAN_VERSION	:= 4.32.0
REQUIRED_TOOLCHAIN	:= leanprover/lean4:v$(REQUIRED_LEAN_VERSION)

TOOLCHAIN		:= $(strip $(shell cat lean-toolchain 2>/dev/null))
ifneq ($(TOOLCHAIN),$(REQUIRED_TOOLCHAIN))
$(error lean-toolchain specifies '$(TOOLCHAIN)' but expected '$(REQUIRED_TOOLCHAIN)')
endif

LEAN_PREFIX := $(shell lean --print-prefix 2>/dev/null)
ifeq ($(LEAN_PREFIX),)
$(error Lean not found. Ensure Lean 4 is installed and available on your PATH.)
endif

LEAN_VERSION		:= $(shell lean --version 2>/dev/null | sed -n 's/.*version \([0-9.]*\).*/\1/p')
ifneq ($(LEAN_VERSION),$(REQUIRED_LEAN_VERSION))
$(error Active Lean version is '$(LEAN_VERSION)', but $(REQUIRED_LEAN_VERSION) is required.)
endif

LAKE	:= LD_LIBRARY_PATH="$(LEAN_PREFIX)/lib" lake --keep-toolchain
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
