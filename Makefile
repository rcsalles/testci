define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("	%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

PIP := pip install -r
PROJECT_NAME := math_app
PYTHON_VERSION := 3.6.1
VENV_NAME := $(PROJECT_NAME)-$(PYTHON_VERSION)


.DEFAULT: help
.PHONY: default_target help test clean setup create-venv setup-dev setup-os code-convention test run all setup-pre-push-hook

help: ## list all commands
	@echo "Usage: make <command> \n"
	@echo "options:"
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

# Environment setup
.create-venv: ## create virtual environment using pyenv
	pyenv install -s $(PYTHON_VERSION)
	pyenv uninstall -f $(VENV_NAME)
	pyenv virtualenv $(PYTHON_VERSION) $(VENV_NAME)
	pyenv local $(VENV_NAME)

.pip:
	pip install pip --upgrade

deps-dev: .pip  ## install all requirements prod.txt + dev.txt
	$(PIP) requirements/dev.txt

deps-prod: .pip ## install requirements for production
	$(PIP) requirements/prod.txt

setup-dev: .create-venv deps-dev setup-pre-push-hook ## create virtual environments and install requirements prod.txt + dev.txt

all: setup-dev default_target  ## run setup-dev + tests + code-covention

default_target: clean test code-convention

.clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

.clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

.clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr reports/
	rm -fr .pytest_cache/

clean: .clean-build .clean-pyc .clean-test ## remove all build, test, coverage and Python artifacts

code-convention:  ## run flake8 (pyflakes, pycodestyle and mccabe for code complexity)
	flake8 calculator tests

test: ## run all tests and code-coverage
	py.test --cov-report=term-missing  --cov-report=html --cov=.

run: ## run aplication
	flask run

deploy-staging: clean ## deploy to staging
	zappa dev

deploy-production: clean ## deploy to production
	zappa update production


setup-pre-push-hook: setup-pre-push-hook-file
	grep -q 'make test-and-convention' .git/hooks/pre-push || \
		printf '\n%s\n\n' 'make test-and-convention' >> .git/hooks/pre-push

setup-pre-push-hook-file:
	test -f .git/hooks/pre-push || echo '#!/bin/sh' >.git/hooks/pre-push
	test -x .git/hooks/pre-push || chmod +x .git/hooks/pre-push
