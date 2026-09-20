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

## Troubleshooting

### Tinycast cannot find Node when connecting Codex (macOS)

If Tinycast reports `codex: line 48: exec: node: not found` even though Codex works in the terminal, its launch environment may be missing the Node directory that `mise activate zsh` adds to the terminal's `PATH`.

The pnpm Codex launcher at `~/Library/pnpm/bin/codex` checks for a `node` executable beside itself. Link the existing mise-managed Node there:

```sh
ln -s "$HOME/.local/share/mise/installs/node/latest/bin/node" "$HOME/Library/pnpm/bin/node"
```

This symlink has already been added on this Mac; it is a manual fix, not part of `mise bootstrap`. The target follows mise's `latest` alias, which must continue to point to an installed Node version.

Verify with a minimal desktop-app-style `PATH`, then retry connecting Codex in Tinycast:

```sh
env PATH=/usr/bin:/bin:/usr/sbin:/sbin "$HOME/Library/pnpm/bin/codex" --version
env PATH=/usr/bin:/bin:/usr/sbin:/sbin "$HOME/Library/pnpm/bin/codex" login status
```

To undo the fix, remove only the symlink: `unlink "$HOME/Library/pnpm/bin/node"`.

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
- Install the [`gh-notify-desktop`](https://github.com/benelan/gh-notify-desktop) extension and verify it works: `gh extension install benelan/gh-notify-desktop`
- Configure environment variables:
  - Copy `scripts/.env.template` to `scripts/.env`
  - Set `GH_TOKEN` and any required vars inside `scripts/.env`
- Ensure scripts are linked and executable: `mise run scripts`
- Add a crontab entry to run the script periodically, for example every minute:
  - `*/2 * * * * $HOME/scripts/gh-notify-desktop.sh >> $HOME/Library/Logs/gh-notify-desktop.cron.log 2>&1`
- The script sources `~/scripts/.env` and sets a safe `PATH` before calling `gh notify-desktop`.
