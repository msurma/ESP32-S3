PYTHON := python3.13
VENV := .venv
BIN := $(VENV)/bin

.PHONY: install shell sh clean

install: $(BIN)/esphome

$(BIN)/esphome: $(BIN)/pip
	$(BIN)/pip install --upgrade pip
	$(BIN)/pip install esphome

$(BIN)/pip:
	$(PYTHON) -m venv $(VENV)

shell:
	@echo "Entering venv shell — type 'exit' to leave"
	@VIRTUAL_ENV=$(CURDIR)/$(VENV) PATH=$(CURDIR)/$(BIN):$$PATH $$SHELL

sh: shell

clean:
	rm -rf $(VENV)
