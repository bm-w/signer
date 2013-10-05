prefix ?= .
PREFIX ?= $(prefix)

BIN_DIR = $(PREFIX)/bin
SRC_DIR := ./src

COFFEE_BIN := node_modules/coffee-script/bin/coffee

# ------

.PHONY: build

build: $(BIN_DIR)/hasher

install:
	npm --prefix $(PREFIX) install

# ------

$(BIN_DIR)/:
	mkdir -p $(BIN_DIR)

$(BIN_DIR)/hasher: $(SRC_DIR)/hasher.coffee $(BIN_DIR)/
	echo "#!/usr/bin/env node\n" > $(BIN_DIR)/hasher
	$(COFFEE_BIN) -cbp $(SRC_DIR)/hasher.coffee >> $(BIN_DIR)/hasher
	chmod +x $(BIN_DIR)/hasher