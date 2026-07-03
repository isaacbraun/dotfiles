# dotfiles
These are my personal configuration files. They are a continual work in progress.

Currently setup to use Mise's bootstrap setup.

Previously heavily based on [Thorsten Ball's dotfiles](https://github.com/mrnugget/dotfiles/), and many zsh/git configurations still are.

## Usage
All files are edited within the repo, then symlinks are created to them using mise bootstrap.

### Installation

> [!IMPORTANT]
> Git must be installed and configured with SSH keys.

```sh
curl -fsSL https://mise.run | sh
git clone git@github.com:isaacbraun/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
mise trust
mise bootstrap
```

### Useful checks:

```sh
mise bootstrap --dry-run
mise dotfiles status
```

### Manual tasks:

```sh
mise run scripts
mise run obsidian
```

## Tools Configured 

TODO: update this list to be accurate and have more context.

- Mise
- FZF: look into how this works
- ZSH
- Ghostty
- Zoxide
- eza
- Tmux
- Zed
- Alacritty: only for Windows. File needs to be copied.
- [Delta](https://github.com/dandavison/delta) - diff viewer
- [Apfel](https://apfel.franzai.com): only macOS

## GitHub Desktop Notifications (cron) - macOS Only Currently
- Install the `gh-notify-desktop` extension and verify it works: `gh extension install benelan/gh-notify-desktop`
- Configure environment variables:
  - Copy `scripts/.env.template` to `scripts/.env`
  - Set `GH_TOKEN` and any required vars inside `scripts/.env`
- Ensure scripts are linked and executable: `mise run scripts`
- Add a crontab entry to run the script periodically, for example every minute:
  - `*/2 * * * * $HOME/scripts/gh-notify-desktop.sh >> $HOME/Library/Logs/gh-notify-desktop.cron.log 2>&1`
- The script sources `~/scripts/.env` and sets a safe `PATH` before calling `gh notify-desktop`.
