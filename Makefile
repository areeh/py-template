PYTHON_VERSION := $(shell cat .python-version | cut -c -3)
PYTHON_BIN = python$(PYTHON_VERSION)
MIN_PIP_VERSION = "16"
SRC = pytemplate/

default: check-poetry

.PHONY: check-pip
check-pip:
# Warn if pip major version is too low, as poetry breaks with early pip versions
	@$(PYTHON_BIN) -c 'import pip; min_pip_version=int($(MIN_PIP_VERSION)); pip_version=int(pip.__version__.split(".")[0]); assert pip_version >= min_pip_version, f"pip major version {pip_version} was lower than the minimum {min_pip_version}"'
	@echo pip version ok!

check-poetry: check-pip
ifeq (, $(shell which poetry))
	$(error "`poetry` not found. install via `curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | $(PYTHON_BIN)`")
endif
	poetry install
	@echo "poetry is good to go! 🚀"

	@echo checking for Python version $(PYTHON_VERSION)...
	@$(PYTHON_BIN) -c 'import sys; assert "{0.major}.{0.minor}".format(sys.version_info) == "$(PYTHON_VERSION)", "Expected python version $(PYTHON_VERSION), got {0.major}.{0.minor}".format(sys.version_info)'

.PHONY: isort
isort:
	poetry run isort -rc .

.PHONY: black
black:
	poetry run black .

.PHONY: test-static
test-static:
	poetry run mypy $(SRC)
	poetry run flake8
	poetry run isort -rc . --check-only
	poetry run black . --check



test-unit:
	poetry run python -m pytest tests/unit -s

test-accept:
	poetry run python -m pytest tests -s

ci: test-static test-unit

test-publish:
	poetry publish -r testpypi


test: test-static test-accept

.PHONY: clean
clean:
	rm -rf output || true
	rm -rf .venv || true
	direnv reload
