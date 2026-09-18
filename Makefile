.PHONY: help compile run serve setup clean all

# ------------------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------------------

.DEFAULT_GOAL := help

WORKFLOW_ID   := hansen-deforestation
WORKFLOW_DIR  := ecoscope-workflows-$(WORKFLOW_ID)-workflow
OUTPUT_DIR    := /tmp/wt-hansen-deforestation/output

# ------------------------------------------------------------------------------
# AESTHETICS & THEME
# ------------------------------------------------------------------------------

VIOLET     := \033[38;5;183m
SKY_BLUE   := \033[38;5;111m
MINT_GREEN := \033[38;5;114m
AQUA       := \033[38;5;123m
PEACH      := \033[38;5;216m
CORAL      := \033[38;5;210m
ROSE       := \033[38;5;218m
SLATE      := \033[38;5;246m
GOLD       := \033[38;5;222m

RESET      := \033[0m
BOLD       := \033[1m

T_TOP     := ╭────────────────────┬──────────────────────────────────────────╮
T_MID     := ├────────────────────┼──────────────────────────────────────────┤
T_BOT     := ╰────────────────────┴──────────────────────────────────────────╯
B_TOP     := ╭───────────────────────────────────────────────────────────────╮
B_BOT     := ╰───────────────────────────────────────────────────────────────╯
SEPARATOR := ───────────────────────────────────────────────────────────────

define print_row
	@printf "$(VIOLET)│$(RESET)  $(SLATE)%-16s$(RESET)  $(VIOLET)│$(RESET)  $(AQUA)%-38s$(RESET)  $(VIOLET)│$(RESET)\n" "$(1)" "$(2)"
endef

define print_head
	@echo ""
	@echo " $(BOLD)$(3)$(1)  $(2)$(RESET)"
	@echo " $(SLATE)$(SEPARATOR)$(RESET)"
endef

# ------------------------------------------------------------------------------
# TARGETS
# ------------------------------------------------------------------------------

help: ## Show this help menu
	@echo ""
	@echo "$(VIOLET)$(T_TOP)$(RESET)"
	@printf "$(VIOLET)│$(RESET)  $(BOLD)$(SKY_BLUE)%-16s$(RESET)  $(VIOLET)│$(RESET)  $(BOLD)$(SKY_BLUE)%-38s$(RESET)  $(VIOLET)│$(RESET)\n" "Target" "Description"
	@echo "$(VIOLET)$(T_MID)$(RESET)"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "$(VIOLET)│$(RESET)  $(MINT_GREEN)%-16s$(RESET)  $(VIOLET)│$(RESET)  $(SLATE)%-38s$(RESET)  $(VIOLET)│$(RESET)\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo "$(VIOLET)$(T_BOT)$(RESET)"
	@echo ""

all: compile run ## Compile then run

compile: ## Compile spec.yaml into the workflow package
	$(call print_head,⚙,Compiling Hansen Deforestation,$(VIOLET))
	@./dev/recompile.sh --install

setup: ## Create output directory
	$(call print_head,⚙,Setting up Environment,$(VIOLET))
	@mkdir -p $(OUTPUT_DIR)
	@echo "  $(MINT_GREEN)✔$(RESET) $(SLATE)Output directory ready:$(RESET) $(OUTPUT_DIR)"

run: setup ## Run the workflow headlessly with param.yaml
	@echo ""
	@echo "$(VIOLET)$(T_TOP)$(RESET)"
	@printf "$(VIOLET)│$(RESET)  $(BOLD)$(SKY_BLUE)%-16s$(RESET)  $(VIOLET)│$(RESET)  $(BOLD)$(SKY_BLUE)%-38s$(RESET)  $(VIOLET)│$(RESET)\n" "Settings" ""
	@echo "$(VIOLET)$(T_MID)$(RESET)"
	$(call print_row,Workflow,$(WORKFLOW_ID))
	$(call print_row,Params,param.yaml)
	$(call print_row,Output,$(OUTPUT_DIR))
	@echo "$(VIOLET)$(T_BOT)$(RESET)"

	$(call print_head,🚀,Execution Log,$(PEACH))

	@cd $(WORKFLOW_DIR) && \
	ECOSCOPE_WORKFLOWS_RESULTS="file://$(OUTPUT_DIR)" \
	pixi run ecoscope-workflows-$(WORKFLOW_ID)-workflow run \
		--config-file ../param.yaml \
		--execution-mode sequential \
		--no-mock-io

	@echo ""
	@echo "$(MINT_GREEN)$(B_TOP)$(RESET)"
	@printf "$(MINT_GREEN)│$(RESET)   $(BOLD)$(MINT_GREEN)✨  Workflow Completed Successfully$(RESET)                         $(MINT_GREEN)│$(RESET)\n"
	@echo "$(MINT_GREEN)$(B_BOT)$(RESET)"

	$(call print_head,📂,Output Directory Contents,$(CORAL))
	@eza -lha --group-directories-first --icons $(OUTPUT_DIR) 2>/dev/null || ls -lh $(OUTPUT_DIR)

	$(call print_head,📃,Result JSON Preview,$(ROSE))
	@if [ -f "$(OUTPUT_DIR)/result.json" ]; then \
		cat $(OUTPUT_DIR)/result.json | python3 -m json.tool; \
	else \
		echo "  $(GOLD)⚠ result.json not found$(RESET)"; \
	fi

	@echo ""

serve: setup ## Start the runner server (API only — no bundled UI)
	$(call print_head,🌐,Starting Hansen Deforestation Runner,$(SKY_BLUE))
	@echo "  $(SLATE)This exposes the workflow REST API. There is no bundled frontend.$(RESET)"
	@echo "  $(SLATE)Useful endpoints (add ?matchspec=$(WORKFLOW_ID) to each):$(RESET)"
	@echo "  $(AQUA)  http://localhost:8080/rjsf?matchspec=$(WORKFLOW_ID)$(RESET)   — form schema"
	@echo "  $(AQUA)  http://localhost:8080/?matchspec=$(WORKFLOW_ID)$(RESET)        — metadata"
	@echo "  $(AQUA)  http://localhost:8080/docs$(RESET)                             — Swagger UI"
	@echo ""
	# NOTE: The Ecoscope platform provides the React frontend that consumes these endpoints.
	# To preview the rjsf form schema, paste the /rjsf response into https://rjsf.io
	@cd $(WORKFLOW_DIR) && \
	pixi run -e runner uvicorn ecoscope_workflows_runner.app:app --host 0.0.0.0 --port 8080 --reload

clean: ## Delete output directory
	$(call print_head,🗑️,Cleaning Output,$(PEACH))
	@rm -rf $(OUTPUT_DIR)
	@echo "  $(ROSE)✔ Deleted:$(RESET) $(SLATE)$(OUTPUT_DIR)$(RESET)"
	@echo ""
