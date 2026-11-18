SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

MODULE_DIRS := . $(wildcard modules/*)
EXAMPLE_DIRS := $(wildcard examples/*)
PERMISSIONS_DOC := docs/permissions.md

.PHONY: check
check: fmt-check lint docs-check validate test workflow-lint

.PHONY: fmt
fmt:
	terraform fmt -recursive

.PHONY: fmt-check
fmt-check:
	terraform fmt -recursive -check -diff

.PHONY: lint
lint: node-deps
	tflint --init
	tflint --recursive --config $(CURDIR)/.tflint.hcl
	npx --no-install tsc --noEmit

.PHONY: node-deps
node-deps:
	npm ci --no-audit --no-fund --silent

.PHONY: docs
docs: node-deps
	node scripts/render-permissions.ts --write $(PERMISSIONS_DOC)
	terraform-docs .
	for dir in $(wildcard modules/*); do terraform-docs -c .terraform-docs-modules.yml $$dir; done

.PHONY: docs-check
docs-check: node-deps
	node scripts/render-permissions.ts --check $(PERMISSIONS_DOC)
	terraform-docs --output-check .
	for dir in $(wildcard modules/*); do terraform-docs --output-check -c .terraform-docs-modules.yml $$dir; done

.PHONY: validate
validate:
	for dir in $(MODULE_DIRS) $(EXAMPLE_DIRS); do \
	  echo "validate $$dir"; \
	  terraform -chdir=$$dir init -backend=false -input=false -no-color > /dev/null; \
	  terraform -chdir=$$dir validate -no-color; \
	done

.PHONY: test
test:
	terraform init -backend=false -input=false -no-color > /dev/null
	terraform test -no-color

.PHONY: workflow-lint
workflow-lint:
	actionlint
	zizmor --offline --min-severity medium .github/workflows

.PHONY: clean
clean:
	find . -name .terraform -type d -prune -exec rm -rf {} +
	find . -name .terraform.lock.hcl -delete

.PHONY: help
help:
	@printf '%s\n' \
	  'check          fmt-check lint docs-check validate test workflow-lint' \
	  'fmt            terraform fmt in place' \
	  'lint           tflint on every module and example' \
	  'docs           regenerate docs/permissions.md from permissions/ and the READMEs with terraform-docs' \
	  'docs-check     fail when docs/permissions.md or a README is stale' \
	  'validate       terraform validate every module and example' \
	  'test           terraform test with mock azurerm and azuread providers (Terraform 1.7 or later)' \
	  'workflow-lint  actionlint and zizmor' \
	  'clean          remove every .terraform directory'
