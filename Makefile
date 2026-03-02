.DEFAULT_GOAL := help

SHELL := /bin/bash

CODEX_HOME ?= $(HOME)/.codex
PAIVOT_TOOLS_DIR := $(CODEX_HOME)/tools/paivot
PAIVOT_SKILLS := anchor architect business_analyst designer developer orchestrator pm_acceptor retro sr_pm

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

.PHONY: install-global
install-global: ## Install Paivot skills + global AGENTS.md into CODEX_HOME (default: ~/.codex)
	@bash -euo pipefail -c '\
	  echo "Installing Paivot methodology into: $(CODEX_HOME)"; \
	  mkdir -p "$(CODEX_HOME)/skills" "$(PAIVOT_TOOLS_DIR)"; \
	  \
	  # If a previous install created a nested skills folder, archive it (non-destructive). \
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
	  install -m 0755 "verify-delivery.py" "$(PAIVOT_TOOLS_DIR)/verify-delivery.py"; \
	  install -m 0755 "verify-delivery.sh" "$(PAIVOT_TOOLS_DIR)/verify-delivery.sh"; \
	  \
	  echo "Installed:"; \
	  echo "  Skills:     $(CODEX_HOME)/skills/{$(PAIVOT_SKILLS)}"; \
	  echo "  AGENTS:     $(CODEX_HOME)/AGENTS.md"; \
	  echo "  Tools:      $(PAIVOT_TOOLS_DIR)/verify-delivery.{py,sh}"; \
	'
