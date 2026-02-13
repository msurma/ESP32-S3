PYTHON := python3.13
VENV := .venv
BIN := $(VENV)/bin

.PHONY: install shell sh clean gen-key

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

gen-key:
	@$(BIN)/python3 -c "import secrets,base64;print(base64.b64encode(secrets.token_bytes(32)).decode())"

clean:
	rm -rf $(VENV)
