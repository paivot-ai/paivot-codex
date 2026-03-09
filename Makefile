.DEFAULT_GOAL := help

SHELL := /bin/bash
VERSION     := $(shell cat VERSION)

CODEX_HOME ?= $(HOME)/.codex
PAIVOT_TOOLS_DIR := $(CODEX_HOME)/tools/paivot
PAIVOT_SKILLS := anchor architect architect_challenger ba_challenger business_analyst c4 designer designer_challenger developer intake nd orchestrator pm_acceptor retro sr_pm vault_capture vault_evolve vault_knowledge vault_settings vault_status vault_triage vlt

.PHONY: help
help: ## Print this help
	@echo "Paivot Codex Skills"
	@echo
	@echo "Usage:"
	@echo "  make <target>"
	@echo
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "Env:"
	@echo "  CODEX_HOME=$(CODEX_HOME)"

.PHONY: check-prereqs
check-prereqs: ## Verify nd and vlt are installed
	@echo "Checking prerequisites..."
	@command -v nd >/dev/null 2>&1 || { echo "ERROR: nd is not installed. See https://github.com/RamXX/nd"; exit 1; }
	@command -v vlt >/dev/null 2>&1 || { echo "ERROR: vlt is not installed. See https://github.com/RamXX/vlt"; exit 1; }
	@echo "  nd:  $$(nd --version 2>/dev/null || echo 'installed')"
	@echo "  vlt: $$(vlt --version 2>/dev/null || echo 'installed')"
	@echo "Prerequisites OK."

.PHONY: install-global
install-global: check-prereqs ## Install Paivot skills + global AGENTS.md into CODEX_HOME (default: ~/.codex)
	@bash -euo pipefail -c '\
	  echo "Installing Paivot methodology into: $(CODEX_HOME)"; \
	  mkdir -p "$(CODEX_HOME)/skills" "$(PAIVOT_TOOLS_DIR)"; \
	  \
	  if [ -d "$(CODEX_HOME)/skills/skills" ]; then \
	    mkdir -p "$(CODEX_HOME)/_archive"; \
	    ts="$$(date +%Y%m%d-%H%M%S)"; \
	    mv "$(CODEX_HOME)/skills/skills" "$(CODEX_HOME)/_archive/skills-dup-$${ts}"; \
	    echo "Archived duplicate skills folder to $(CODEX_HOME)/_archive/skills-dup-$${ts}"; \
	  fi; \
	  \
	  copy_dir() { \
	    local src="$$1" dst="$$2"; \
	    mkdir -p "$$dst"; \
	    if command -v rsync >/dev/null 2>&1; then \
	      rsync -a --delete "$$src/" "$$dst/"; \
	    else \
	      rm -rf "$$dst"/*; \
	      cp -R "$$src"/. "$$dst/"; \
	    fi; \
	  }; \
	  \
	  for s in $(PAIVOT_SKILLS); do \
	    copy_dir ".agents/skills/$${s}" "$(CODEX_HOME)/skills/$${s}"; \
	  done; \
	  \
	  install -m 0644 "AGENTS.global.md" "$(CODEX_HOME)/AGENTS.md"; \
	  install -m 0755 "scripts/verify-delivery.sh" "$(PAIVOT_TOOLS_DIR)/verify-delivery.sh"; \
	  install -m 0755 "scripts/notify-dispatcher.sh" "$(PAIVOT_TOOLS_DIR)/notify-dispatcher.sh"; \
	  \
	  echo "Installed:"; \
	  echo "  Skills:     $(CODEX_HOME)/skills/{$(PAIVOT_SKILLS)}"; \
	  echo "  AGENTS:     $(CODEX_HOME)/AGENTS.md"; \
	  echo "  Tools:      $(PAIVOT_TOOLS_DIR)/"; \
	'

.PHONY: verify
verify: ## Run delivery proof preflight for a story (usage: make verify STORY=PROJ-a1b2)
	@if [ -z "$(STORY)" ]; then echo "Usage: make verify STORY=<story-id>"; exit 1; fi
	@bash scripts/verify-delivery.sh "$(STORY)"

.PHONY: bump
bump: ## Bump version: make bump v=1.37.0 (updates VERSION file)
ifndef v
	$(error Usage: make bump v=X.Y.Z)
endif
	@echo "$(v)" > VERSION
	@echo "Version bumped to $(v)"

.PHONY: clean
clean: ## Remove __pycache__ and other generated files
	rm -rf __pycache__
