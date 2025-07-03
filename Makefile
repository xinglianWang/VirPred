# Define the R environment and commands
R_CMD := Rscript
INSTALL_CMD := R CMD INSTALL
SCRIPTS_DIR := $(CURDIR)/Inst/scripts
TARGET_DIR := $(shell conda info --base 2>/dev/null)/bin
export PATH := $(TARGET_DIR):$(PATH)

# Define the target for installing dependencies
install-dependencies:
	$(R_CMD) -e "source('install_packages.R')"

# Define the target for installing VirPred package
install: install-dependencies
	$(INSTALL_CMD) $(CURDIR)
	# Copy the script to the user's local bin directory and name it "VirPred"
	cp $(SCRIPTS_DIR)/run_VirPred.R $(TARGET_DIR)/VirPred
	# Ensure the script is executable
	chmod +x $(TARGET_DIR)/VirPred

	# Check if the target directory is in PATH, and add it if not
	@echo "Checking if $(TARGET_DIR) is in PATH..."
	@grep -q "$(TARGET_DIR)" ~/.bashrc || echo 'export PATH="$(TARGET_DIR):$$PATH"' >> ~/.bashrc
	@echo "Path to .local/bin has been added to ~/.bashrc."

	# If using zsh, also update ~/.zshrc
	@grep -q "$(TARGET_DIR)" ~/.zshrc || echo 'export PATH="$(TARGET_DIR):$$PATH"' >> ~/.zshrc
	@echo "Path to .local/bin has been added to ~/.zshrc."

	# Prompt user to source the shell config file to update PATH
	@echo "To update your PATH, please run: source ~/.bashrc or source ~/.zshrc (depending on your shell)."

# Clean target (optional, to remove any temporary or unnecessary files)
clean:
	rm -rf $(CURDIR)/VirPred

build:
	R CMD build .
