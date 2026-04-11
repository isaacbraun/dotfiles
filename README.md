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
- runs folder: install all needed tools automatically
- learn more bash

## Tools Configured 
- FZF: look into how this works
- ZSH
- Ghostty
- Zoxide
- eza
- Tmux
- Zed
- Alacritty: only for Windows. File needs to be copied.
- [Apfel](https://apfel.franzai.com): only macOS, requires Tahoe so not set up yet.

## GitHub Desktop Notifications (cron) - macOS Only Currently
- Install the `gh-notify-desktop` extension and verify it works: `gh extension install benelan/gh-notify-desktop`
- Configure environment variables:
  - Copy `scripts/.env.template` to `scripts/.env`
  - Set `GH_TOKEN` and any required vars inside `scripts/.env`
- Ensure scripts are linked and executable: `make scripts-folder`
- Add a crontab entry to run the script periodically, for example every minute:
  - `*/2 * * * * $HOME/scripts/gh-notify-desktop.sh >> $HOME/Library/Logs/gh-notify-desktop.cron.log 2>&1`
- The script sources `~/scripts/.env` and sets a safe `PATH` before calling `gh notify-desktop`.
