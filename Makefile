PREFIX ?= $(HOME)/.local
CONFIG_DIR ?= $(HOME)/.config/dbx-smith

BIN_DIR = $(PREFIX)/bin
SRC_DIR = $(CONFIG_DIR)

SCRIPTS = bin/dbx-smith-spin bin/dbx-smith-rm bin/dbx-smith-uninstall
CORE = src/dbx-smith.sh

.PHONY: all install uninstall

all:
	@echo "Run 'make install' to install the DbxSmith Productivity Suite."
	@echo "Defaults: PREFIX=$(PREFIX), CONFIG_DIR=$(CONFIG_DIR)"

install:
	@echo "Installing binaries to $(BIN_DIR)..."
	install -d $(BIN_DIR)
	install -m 755 $(SCRIPTS) $(BIN_DIR)/
	
	@echo "Installing runtime core to $(SRC_DIR)..."
	install -d $(SRC_DIR)/aliases.d
	install -d $(SRC_DIR)/registry
	install -m 644 $(CORE) $(SRC_DIR)/
	
	@echo ""
	@echo "=========================================================="
	@echo "Installation complete!"
	@echo "Please add the following line to your ~/.bashrc or ~/.zshrc:"
	@echo "  source $(SRC_DIR)/dbx-smith.sh"
	@echo "=========================================================="

uninstall:
	@echo "Removing executables..."
	rm -f $(BIN_DIR)/dbx-smith-spin
	rm -f $(BIN_DIR)/dbx-smith-rm
	rm -f $(BIN_DIR)/dbx-smith-uninstall
	
	@echo "Removing config directory..."
	rm -rf $(SRC_DIR)
	
	@echo "Uninstall complete."
	@echo "Please remove the 'source' line from your shell rc file."
