BIN_DIR = ./bin
SRC_DIR := ./src

COFFEE_BIN := ./node_modules/coffee-script/bin/coffee

prefix ?= .
PREFIX ?= $(prefix)

# ------

.PHONY: build install clean npm-build npm-install

build: npm-install npm-build

install: build
ifneq ($(PREFIX), .)
	mkdir -p "$(PREFIX)"/bin
	cp -r  $(BIN_DIR) "$(PREFIX)"/
	mkdir -p "$(PREFIX)"/node_modules
	cp -r ./node_modules/optimist "$(PREFIX)"/node_modules/
	cp -r ./node_modules/async "$(PREFIX)"/node_modules/
endif

# ------

npm-build: $(BIN_DIR)/signer

npm-install:
	npm install

# ------

$(BIN_DIR)/:
	mkdir -p $(BIN_DIR)

$(BIN_DIR)/signer: $(SRC_DIR)/signer.coffee $(BIN_DIR)/
	echo "#!/usr/bin/env node\n" > $(BIN_DIR)/signer
	$(COFFEE_BIN) -cbp $(SRC_DIR)/signer.coffee >> $(BIN_DIR)/signer
	chmod +x $(BIN_DIR)/signer

# ------

clean:
	rm -rf $(BIN_DIR) ./node_modules