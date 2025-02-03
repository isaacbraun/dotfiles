# Take from Thorsten Ball's dotfiles: https://github.com/mrnugget/dotfiles
DOTFILE_PATH := $(shell pwd)

$(HOME)/.%: %
	ln -sf $(DOTFILE_PATH)/$^ $@

git: $(HOME)/.gitconfig $(HOME)/.githelpers $(HOME)/.gitignore

zsh: $(HOME)/.zshrc
#  $(HOME)/.zsh.d

$(HOME)/bin/tmux-sessionizer:
	mkdir -p $(HOME)/bin
	ln -sf $(DOTFILE_PATH)/bin/tmux-sessionizer $(HOME)/bin/tmux-sessionizer
	chmod +x $(HOME)/bin/tmux-sessionizer

tmux: $(HOME)/.tmux.conf
tmux-sessionizer: $(HOME)/bin/tmux-sessionizer

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

all: git zsh tmux ghostty zen
