BIN_DIR = ./bin
SRC_DIR := ./src

COFFEE_BIN := ./node_modules/coffee-script/bin/coffee

prefix ?= .
PREFIX ?= $(prefix)

# ------

.PHONY: build

build: deps npm-build
npm-build: $(BIN_DIR)/hasher

deps:
	npm install

install: build
ifneq ($(PREFIX), .)
	mkdir -p "$(PREFIX)"/bin
	cp -r  $(BIN_DIR) "$(PREFIX)"/
	mkdir -p "$(PREFIX)"/node_modules
	cp -r ./node_modules/optimist "$(PREFIX)"/node_modules/
	cp -r ./node_modules/async "$(PREFIX)"/node_modules/
	cp -r ./node_modules/asn1 "$(PREFIX)"/node_modules/
endif

# ------

$(BIN_DIR)/:
	mkdir -p $(BIN_DIR)

$(BIN_DIR)/hasher: $(SRC_DIR)/hasher.coffee $(BIN_DIR)/
	echo "#!/usr/bin/env node\n" > $(BIN_DIR)/hasher
	$(COFFEE_BIN) -cbp $(SRC_DIR)/hasher.coffee >> $(BIN_DIR)/hasher
	chmod +x $(BIN_DIR)/hasher