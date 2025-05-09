# dotfiles
These are my personal configuration files. They are a continual work in progress and recently reset to be heavily based on [Thorsten Ball's dotfiles](https://github.com/mrnugget/dotfiles/).

## Usage
All files are edited within the repo, then symlinks are created to them using the Makefile.

- Run one symlink/setup. ZSH for example: `make zsh`
- Run all symlinks/setup: `make all`

## To Do
- Ensure [ripgrep](https://github.com/BurntSushi/ripgrep) is installed. It is needed for telescope to function properly.
- Should rg be aliased instead of grep??
- Set up .tmux-sessionizer config files for specific directories
- runs folder
- learn more bash

## Tools Configured 
- FZF: look into how this works
- ZSH
- Ghostty
- Zoxide
- Tmux
- Alacritty: only for Windows. File needs to be copied.
