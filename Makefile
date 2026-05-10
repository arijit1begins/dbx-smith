PREFIX ?= $(HOME)/.local
XDG_CONFIG_HOME ?= $(HOME)/.config
CONFIG_DIR ?= $(XDG_CONFIG_HOME)/dbx-smith

BIN_DIR = $(PREFIX)/bin
# Code is installed into the config dir for portability (matched with install.sh expectations)
SRC_INSTALL_DIR = $(CONFIG_DIR)/src
MAN_DIR = $(PREFIX)/share/man/man1

SCRIPTS = bin/dbx-smith-spin bin/dbx-smith-rm bin/dbx-smith-uninstall
MAN_PAGES = man/dbx-smith-spin.1 man/dbx-smith-rm.1

.PHONY: all install uninstall

all:
	@echo "Run 'make install' to install the DbxSmith Productivity Suite."
	@echo "Defaults: PREFIX=$(PREFIX), CONFIG_DIR=$(CONFIG_DIR)"

install:
	@echo "Installing binaries to $(BIN_DIR)..."
	install -d $(BIN_DIR)
	install -m 755 $(SCRIPTS) $(BIN_DIR)/
	
	@echo "Installing modular source to $(SRC_INSTALL_DIR)..."
	install -d $(SRC_INSTALL_DIR)/core
	install -d $(SRC_INSTALL_DIR)/strategies
	install -d $(SRC_INSTALL_DIR)/distros
	install -m 644 src/dbx-smith.sh $(SRC_INSTALL_DIR)/
	install -m 644 src/core/*.sh $(SRC_INSTALL_DIR)/core/
	install -m 644 src/strategies/*.sh $(SRC_INSTALL_DIR)/strategies/
	install -m 644 src/distros/*.sh $(SRC_INSTALL_DIR)/distros/
	
	@echo "Ensuring infrastructure directories exist..."
	install -d $(CONFIG_DIR)/aliases.d
	install -d $(CONFIG_DIR)/registry
	
	@echo "Installing man pages to $(MAN_DIR)..."
	install -d $(MAN_DIR)
	install -m 644 $(MAN_PAGES) $(MAN_DIR)/
	
	@echo ""
	@echo "=========================================================="
	@echo "Installation complete!"
	@echo "Please add the following line to your ~/.bashrc or ~/.zshrc:"
	@echo "  source $(SRC_INSTALL_DIR)/dbx-smith.sh"
	@echo "=========================================================="

uninstall:
	@echo "Removing executables..."
	rm -f $(BIN_DIR)/dbx-smith-spin
	rm -f $(BIN_DIR)/dbx-smith-rm
	rm -f $(BIN_DIR)/dbx-smith-uninstall
	
	@echo "Removing man pages..."
	rm -f $(MAN_DIR)/dbx-smith-spin.1
	rm -f $(MAN_DIR)/dbx-smith-rm.1
	
	@echo "Removing source and config directory..."
	rm -rf $(CONFIG_DIR)
	
	@echo "Uninstall complete."
	@echo "Please remove the 'source' line from your shell rc file."
