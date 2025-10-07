
############## 
# Taken from Thorsten Ball's config: https://github.com/mrnugget/dotfiles/
##############
# BASIC SETUP
##############

typeset -U PATH
autoload colors; colors;
# gruvbox yellow, bold
local dir_info_color="%B%F{#fabd2f}"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='mvim'
fi

##########
# HISTORY
##########

HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt INC_APPEND_HISTORY     # Immediately append to history file.
setopt EXTENDED_HISTORY       # Record timestamp in history.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS       # Dont record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS      # Do not display a line previously found.
setopt HIST_IGNORE_SPACE      # Dont record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS      # Dont write duplicate entries in the history file.
setopt SHARE_HISTORY          # Share history between all sessions.
unsetopt HIST_VERIFY          # Execute commands using history (e.g.: using !$) immediately

#############
# COMPLETION
#############


###############
# KEY BINDINGS
###############

# Vim Keybindings
bindkey -v

# This is a "fix" for zsh in Ghostty:
# Ghostty implements the fixterms specification https://www.leonerd.org.uk/hacks/fixterms/
# and under that `Ctrl-[` doesn't send escape but `ESC [91;5u`.
#
# (tmux and Neovim both handle 91;5u correctly, but raw zsh inside Ghostty doesn't)
#
# Thanks to @rockorager for this!
bindkey "^[[91;5u" vi-cmd-mode

# Open line in Vim by pressing 'v' in Command-Mode
autoload -U edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Push current line to buffer stack, return to PS1
bindkey "^Q" push-input

# Make up/down arrow put the cursor at the end of the line
# instead of using the vi-mode mappings for these keys
bindkey "\eOA" up-line-or-history
bindkey "\eOB" down-line-or-history
bindkey "\eOC" forward-char
bindkey "\eOD" backward-char

# CTRL-R to search through history
bindkey '^R' history-incremental-search-backward
# CTRL-S to search forward in history
bindkey '^S' history-incremental-search-forward
# Accept the presented search result
bindkey '^Y' accept-search

# Use the arrow keys to search forward/backward through the history,
# using the first word of what's typed in as search word
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Use the same keys as bash for history forward/backward: Ctrl+N/Ctrl+P
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward

# Backspace working the way it should
bindkey '^?' backward-delete-char
bindkey '^[[3~' delete-char

# Some emacs keybindings won't hurt nobody
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# Where should I put you?
bindkey -s '^F' "~/scripts/tmux-sessionizer\n"

#########
# Aliases
#########

alias ls='eza --icons --long --git --no-user'

alias history='history 1'
alias hs='history | grep '

# Use rsync with ssh and show progress
alias rsyncssh='rsync -Pr --rsh=ssh'

alias vim="nvim"
alias vi="nvim"
# Open vim in current directory
alias vd="nvim ."
alias venv-a="source .venv/bin/activate"

alias pn="pnpm"

# Edit/Source vim config
alias ez='vi ~/.zshrc'
alias sz='source ~/.zshrc'

# git
alias gs='git status'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git checkout main'
alias gd='git diff'
alias gdc='git diff --cached'
# [c]heck [o]ut
alias co='git checkout'
alias sw='git switch'
# [s]witch and [c]reate branch
alias swc='git switch -c'
# [f]uzzy check[o]ut
fo() {
  git branch --no-color --sort=-committerdate --format='%(refname:short)' | fzf --header 'git checkout' | xargs git checkout
}
# [p]ull request check[o]ut
po() {
  gh pr list --author "@me" | fzf --header 'checkout PR' | awk '{print $(NF-5)}' | xargs git checkout
}
# Use specific esri/personl gh config
ghe() {
  GH_CONFIG_DIR=~/.config/gh-esri gh "$@"
}
ghp() {
  GH_CONFIG_DIR=~/.config/gh-personal gh "$@"
}

function eclone() {
  local repo_path="$1" # e.g., "owner/repo-name"
  local custom_dir="$2" # e.g., "/path/to/directory"
  local target_email="ibraun@esri.com"

  if [ -z "$repo_path" ]; then
    echo "Usage: elcone <owner>/<repository> [custom_directory]"
    return 1
  fi

  echo "Cloning $repo_path..."
  ghe repo clone "$repo_path" "$custom_dir"

  # Extract the repository name from the path for changing directory
  # This handles cases like "owner/repo" and "owner/repo.git"
  local repo_name=$(basename "$repo_path" .git)

  # If a custom directory is provided, use it instead of repo_name
  if [ -n "$custom_dir" ]; then
    repo_name="$custom_dir"
  fi
  # Change to the cloned repository directory
  if [ ! -d "$repo_name" ]; then
    echo "Error: Directory $repo_name not found after cloning."
    return 1
  fi

  echo "Changing directory to $repo_name..."
  cd "$repo_name" || return 1 # Exit if cd fails

  echo "Setting local Git email to $target_email..."
  git config user.email "$target_email"

  echo "Done! Cloned $repo_path and set local email to $target_email."
  echo "You are now in: $(pwd)"
}

# alias eclone='ghe repo clone'
alias pclone='ghp repo clone'

# Function to add/remove git worktrees.
# Usage:
#  gwt add <path> <branch>                     - Add worktree for existing or new branch (creates if missing)
#  gwt add <path> -b <new-branch> [start]      - Add worktree creating new branch (optional start-point)
#  gwt remove [-f|--force] <path>              - Remove worktree (kills tmux session if exists; -f to force)
#  gwt list                                    - List existing worktrees
function gwt() {
  local action="$1"
  shift || true
  case "$action" in
    add)
      # Support forms:
      # gwt add <path> <existing-branch>
      # gwt add <path> -b <new-branch> [start-point]
      local create_branch=""
      local branch=""
      local wt_path=""
      local start_point=""

      wt_path="$1"; shift 1 || true
      if [ -z "$wt_path" ]; then
        echo "Usage: gwt add <path> <branch>"
        echo "       gwt add <path> -b <new-branch> [start-point]"
        return 1
      fi

      if [ "$1" = "-b" ]; then
        create_branch=1
        branch="$2"; shift 2
        start_point="$1"
      else
        branch="$1"; shift 1
      fi

      if [ -z "$branch" ]; then
        echo "Usage: gwt add <path> <branch>"
        echo "       gwt add <path> -b <new-branch> [start-point]"
        return 1
      fi

      if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not inside a git repository."
        return 1
      fi
      if [ -e "$wt_path" ]; then
        echo "Error: path '$wt_path' already exists."
        return 1
      fi

      if [ -n "$create_branch" ]; then
        if [ -n "$start_point" ]; then
          echo "Creating new branch '$branch' from '$start_point' at '$wt_path'"
          git worktree add -b "$branch" "$wt_path" "$start_point" || return $?
        else
          echo "Creating new branch '$branch' from current HEAD at '$wt_path'"
          git worktree add -b "$branch" "$wt_path" || return $?
        fi
      else
        if git show-ref --verify --quiet "refs/heads/$branch"; then
          echo "Adding worktree for existing branch '$branch' at '$wt_path'"
          git worktree add "$wt_path" "$branch" || return $?
        else
          if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
            echo "Creating worktree from remote branch 'origin/$branch' at '$wt_path'"
            git worktree add -b "$branch" "$wt_path" "origin/$branch" || return $?
          else
            echo "Creating new branch '$branch' from current HEAD at '$wt_path'"
            git worktree add -b "$branch" "$wt_path" || return $?
          fi
        fi
      fi
      ;;
    list)
      if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not inside a git repository."
        return 1
      fi
      # Format: path | HEAD ref | branch
      git worktree list --porcelain | awk '
        /^worktree /{wt=$2}
        /^HEAD /{head=$2}
        /^branch /{sub(/^refs\/heads\//, "", $2); branch=$2; printf("%s\t%s\t%s\n", wt, head, branch); wt=head=branch=""}
      '
      ;;
    remove)
      local wt_path="$1"
      if [ -z "$wt_path" ]; then
        echo "Usage: gwt remove [-f] <path>"
        return 1
      fi
      if [ ! -d "$wt_path" ]; then
        echo "Worktree path '$wt_path' does not exist."
        return 1
      fi
      local session
      session=$(basename "$wt_path")
      if command -v tmux >/dev/null 2>&1; then
        if tmux has-session -t "$session" 2>/dev/null; then
          echo "Killing tmux session '$session'"
          tmux kill-session -t "$session"
        fi
      fi
      echo "Removing worktree at '$wt_path'"
      local force_flag
      if [ "$wt_path" = "-f" ] || [ "$wt_path" = "--force" ]; then
        force_flag=1
        wt_path="$2"
      else
        if [ "$2" = "-f" ] || [ "$2" = "--force" ]; then
          force_flag=1
        fi
      fi
      if ! git worktree remove "$wt_path"; then
        if [ -n "$force_flag" ]; then
          echo "Worktree not clean; forcing removal"
          git worktree remove --force "$wt_path" || return $?
        else
          echo "Worktree not clean. Use -f to force removal."
          return 1
        fi
      fi
      ;;
    *)
      echo "Usage:"
      echo "  gwt add <path> <branch>"
      echo "  gwt add <path> -b <new-branch> [start-point]"
      echo "  gwt list"
      echo "  gwt remove [-f|--force] <path>"
      return 1
      ;;
  esac
}

# GH Cli FZF aliases
alias me='ghp fzf issue --assignee @me --state open'

alias up='git push'
alias upf='git push --force'
alias pu='git pull'
alias pur='git pull --rebase'
alias fe='git fetch'
alias re='git rebase'
alias lr='git l -30'
alias cdr='cd $(git rev-parse --show-toplevel)' # cd to git Root
alias hs='git rev-parse --short HEAD'
alias hm='git log --format=%B -n 1 HEAD'
alias pr='ghp pr create'
alias pre='ghe pr create'

# tmux
alias tma='tmux attach -t'
alias tmn='tmux new -s'
alias tmm='tmux new -s main'

# ceedee dot dot dot
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'

# Go
alias got='go test ./...'

alias -g withcolors="| sed '/PASS/s//$(printf "\033[32mPASS\033[0m")/' | sed '/FAIL/s//$(printf "\033[31mFAIL\033[0m")/'"

# PHP/Laravel
alias ar='php artisan'

# OpenCode
alias oc='opencode'

##########
# FUNCTIONS
##########

mkdircd() {
  mkdir -p $1 && cd $1
}

serve() {
  local port=${1:-8000}
  local ip=$(ipconfig getifaddr en0)
  echo "Serving on ${ip}:${port} ..."
  python -m SimpleHTTPServer ${port}
}

beautiful() {
  while
  do
    i=$((i + 1)) && echo -en "\x1b[3$(($i % 7))mo" && sleep .2
  done
}

spinner() {
  while
  do
    for i in "-" "\\" "|" "/"
    do
      echo -n " $i \r\r"
      sleep .1
    done
  done
}

# s3() {
#   local route="s3.thorstenball.com/${1}"
#   aws s3 cp ${1} s3://${route}
#   echo http://${route} | pbcopy
# }

# Open PR on GitHub
# pr() {
#   if type gh &> /dev/null; then
#     gh pr view -w
#   else
#     echo "gh is not installed"
#   fi
# }

#########
# PROMPT
#########

setopt prompt_subst

git_prompt_info() {
  local dirstatus=" OK"
  local dirty="%{$fg_bold[red]%} X%{$reset_color%}"

  if [[ ! -z $(git status --porcelain 2> /dev/null | tail -n1) ]]; then
    dirstatus=$dirty
  fi

  ref=$(git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(git rev-parse --short HEAD 2> /dev/null) || return
  echo " %{$fg_bold[green]%}${ref#refs/heads/}$dirstatus%{$reset_color%}"
}

# This just sets the color to "bold".
local dir_info_color="%B"

local dir_info_color_file="${HOME}/.zsh.d/dir_info_color"
if [ -r ${dir_info_color_file} ]; then
  source ${dir_info_color_file}
fi

local dir_info="%{$dir_info_color%}%(5~|%-1~/.../%2~|%4~)%{$reset_color%}"
local promptnormal="φ %{$reset_color%}"
local promptjobs="%{$fg_bold[red]%}φ %{$reset_color%}"

PROMPT='${dir_info}$(git_prompt_info) ${nix_prompt}%(1j.$promptjobs.$promptnormal)'

simple_prompt() {
  local prompt_color="%B"
  export PROMPT="%{$prompt_color%}$promptnormal"
}

########
# ENV
########

# Reduce delay for key combinations in order to change to vi mode faster
# See: http://www.johnhawthorn.com/2012/09/vi-escape-delays/
# Set it to 10ms
export KEYTIMEOUT=1

export PATH="$HOME/neovim/bin:$PATH"
export PATH="/opt/nvim-linux64/bin:$PATH"

if type nvim &> /dev/null; then
  alias vim="nvim"
  export EDITOR="nvim"
  export PSQL_EDITOR="nvim -c"set filetype=sql""
  export GIT_EDITOR="nvim"
else
  export EDITOR='vim'
  export PSQL_EDITOR='vim -c"set filetype=sql"'
  export GIT_EDITOR='vim'
fi

# fzf
if type fzf &> /dev/null && type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*" --glob "!vendor/*"'
  export FZF_CTRL_T_COMMAND='rg --files --hidden --follow --glob "!.git/*" --glob "!vendor/*"'
  export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# pnpm
export PNPM_HOME="/home/isaac/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/home/isaac/.bun/_bun" ] && source "/home/isaac/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Add .local/bin to path
export PATH="$HOME/.local/bin:$PATH"

# Add Mason bin to path
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

if [[ "$(uname -s)" == "Darwin" ]]; then
  export PATH="/Users/isaac/.config/herd-lite/bin:$PATH"
  export PHP_INI_SCAN_DIR="/Users/isaac/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"

  # Brew
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # Add homewbrew/bin to path
  export PATH="$HOME/homebrew/bin:$PATH"
  # Add Go
  export PATH="/usr/local/go/bin/go/:$PATH"
elif [[ "$(uname -s)" == "Linux" ]]; then
  export PATH="/home/bauen/.config/herd-lite/bin:$PATH"
  export PHP_INI_SCAN_DIR="/home/bauen/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
fi

# Export my personal ~/bin as last one to have highest precedence
export PATH="$HOME/bin:$PATH"

# Zoxide init
eval "$(zoxide init --cmd cd zsh)"

## Mise Activate
eval "$(mise activate zsh)"

if [[ "$(uname -s)" == "Darwin" ]]; then
  export PATH="/Users/isaac/.config/herd-lite/bin:$PATH"
  export PHP_INI_SCAN_DIR="/Users/isaac/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"

  # Brew
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # opencode
  export PATH=/Users/isaac/.opencode/bin:$PATH
elif [[ "$(uname -s)" == "Linux" ]]; then
  export PATH="/home/bauen/.config/herd-lite/bin:$PATH"
  export PHP_INI_SCAN_DIR="/home/bauen/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
fi

# opencode
export PATH=/Users/isa14596/.opencode/bin:$PATH
alias oc="opencode"
