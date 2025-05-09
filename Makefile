# Take from Thorsten Ball's dotfiles: https://github.com/mrnugget/dotfiles
DOTFILE_PATH := $(shell pwd)

$(HOME)/.%: %
	ln -sf $(DOTFILE_PATH)/$^ $@

git: $(HOME)/.gitconfig $(HOME)/.githelpers $(HOME)/.gitignore

zsh: $(HOME)/.zshrc

# Symlink all scripts
$(HOME)/scripts: scripts/
	ln -snf $(DOTFILE_PATH)/$^ $@
	@echo "Making all scripts executable..."
	chmod +x $(DOTFILE_PATH)/scripts/*

scripts-folder: $(HOME)/scripts

# tmux config and cheat sheet config files
tmux: $(HOME)/.tmux.conf $(HOME)/.tmux-cht-languages $(HOME)/.tmux-cht-commands

# Ghostty mkdir and alias
$(HOME)/.config/ghostty/config:
	mkdir -p $(HOME)/.config/ghostty
	ln -sf $(DOTFILE_PATH)/ghostty_config $(HOME)/.config/ghostty/config

ghostty: $(HOME)/.config/ghostty/config

# Zen userChrome.css file
# Find path to default profile folder
ZEN_PROFILE_DIR := $(shell find /home/isaac/.zen -type d -name "chrome" -o -type d -name "*default*" | head -n 1)

$(ZEN_PROFILE_DIR)/chrome/userChrome.css: zenUserChrome 
	mkdir -p $(dir $@)
	ln -sf $(DOTFILE_PATH)/$^ $@

zen: $(ZEN_PROFILE_DIR)/chrome/userChrome.css

all: git zsh scripts-folder ghostty
