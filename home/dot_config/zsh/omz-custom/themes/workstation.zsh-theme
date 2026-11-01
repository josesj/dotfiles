# Two-line Catppuccin prompt with detailed asynchronous Git state and contextual metadata.
zmodload zsh/datetime
zmodload zsh/parameter

# Over SSH the palette must match the local terminal, not the remote desktop:
# ask the terminal for its background colour (OSC 11, answered by Kitty and
# Ghostty) and pick the flavour by luminance. The result is exported so Vim
# can follow it too. Terminals that do not answer time out after 0.3 s.
function workstation_ssh_flavour() {
  [[ -n $SSH_CONNECTION && -t 0 && -t 1 ]] || return 1
  local reply char
  print -n $'\e]11;?\a' >/dev/tty
  # Byte by byte: read -t only bounds the wait for the first character, and
  # the reply may end in BEL or in ST (ESC \).
  while IFS= read -rs -k 1 -t 0.3 char </dev/tty; do
    reply+=$char
    [[ $char == $'\a' || $reply == *$'\e\\' ]] && break
  done
  [[ $reply =~ 'rgb:([[:xdigit:]]{2})[[:xdigit:]]*/([[:xdigit:]]{2})[[:xdigit:]]*/([[:xdigit:]]{2})' ]] ||
    return 1
  local -i red=16#$match[1] green=16#$match[2] blue=16#$match[3]
  (( red * 299 + green * 587 + blue * 114 > 128000 )) && REPLY=latte || REPLY=mocha
}

# Otherwise follow the desktop's current mode at shell startup: Latte for
# light, Mocha for dark. GNOME reports it in the color-scheme gsettings key
# (prefer-dark, prefer-light or default, which is light); macOS only defines
# AppleInterfaceStyle while dark mode is active, so its absence means light.
typeset workstation_color_scheme='Mocha'
if workstation_ssh_flavour; then
  export WORKSTATION_FLAVOUR=$REPLY
  workstation_color_scheme=${(C)REPLY}
elif (( $+commands[gsettings] )); then
  [[ $(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null) == *prefer-dark* ]] \
    && workstation_color_scheme='Mocha' || workstation_color_scheme='Latte'
elif [[ $OSTYPE == darwin* ]]; then
  defaults read -g AppleInterfaceStyle &>/dev/null || workstation_color_scheme='Latte'
fi
if [[ $workstation_color_scheme == *Latte* || $workstation_color_scheme == *Light* ]]; then
  typeset -g WORKSTATION_TEXT='#4c4f69' WORKSTATION_OVERLAY='#8c8fa1'
  typeset -g WORKSTATION_RED='#d20f39' WORKSTATION_ORANGE='#fe640b'
  typeset -g WORKSTATION_YELLOW='#df8e1d' WORKSTATION_GREEN='#40a02b'
  typeset -g WORKSTATION_BLUE='#1e66f5' WORKSTATION_CYAN='#179299'
  typeset -g WORKSTATION_PURPLE='#8839ef'
else
  typeset -g WORKSTATION_TEXT='#cdd6f4' WORKSTATION_OVERLAY='#6c7086'
  typeset -g WORKSTATION_RED='#f38ba8' WORKSTATION_ORANGE='#fab387'
  typeset -g WORKSTATION_YELLOW='#f9e2af' WORKSTATION_GREEN='#a6e3a1'
  typeset -g WORKSTATION_BLUE='#89b4fa' WORKSTATION_CYAN='#94e2d5'
  typeset -g WORKSTATION_PURPLE='#cba6f7'
fi
unset workstation_color_scheme

typeset -g WORKSTATION_COMMAND_STARTED=''
typeset -gi WORKSTATION_LAST_STATUS=0
typeset -gi WORKSTATION_COMMAND_DURATION_MS=0
typeset -gi WORKSTATION_JOB_COUNT=0

function workstation_prompt_context() {
  if (( EUID == 0 )); then
    print -nr -- "%F{$WORKSTATION_RED}root@${HOST%%.*}%f "
  elif [[ -n $SSH_CONNECTION ]]; then
    print -nr -- "%F{$WORKSTATION_YELLOW}%n@%m%f "
  fi
}

function workstation_preexec() {
  WORKSTATION_COMMAND_STARTED=$EPOCHREALTIME
}

function workstation_precmd() {
  WORKSTATION_LAST_STATUS=$?
  WORKSTATION_JOB_COUNT=${#jobstates}
  WORKSTATION_COMMAND_DURATION_MS=0
  if [[ -n $WORKSTATION_COMMAND_STARTED ]]; then
    WORKSTATION_COMMAND_DURATION_MS=$(( (EPOCHREALTIME - WORKSTATION_COMMAND_STARTED) * 1000 ))
    WORKSTATION_COMMAND_STARTED=''
  fi
}

function workstation_format_duration() {
  local -i total_seconds=$(( (WORKSTATION_COMMAND_DURATION_MS + 500) / 1000 ))
  if (( total_seconds >= 3600 )); then
    printf '%dh%02dm%02ds' $(( total_seconds / 3600 )) \
      $(( total_seconds / 60 % 60 )) $(( total_seconds % 60 ))
  elif (( total_seconds >= 60 )); then
    printf '%dm%02ds' $(( total_seconds / 60 )) $(( total_seconds % 60 ))
  else
    printf '%ds' "$total_seconds"
  fi
}

function workstation_right_prompt() {
  local -a segments
  (( WORKSTATION_LAST_STATUS != 0 )) &&
    segments+=("%F{$WORKSTATION_RED}%1{✘%} $WORKSTATION_LAST_STATUS%f")
  (( WORKSTATION_COMMAND_DURATION_MS >= 2000 )) &&
    segments+=("%F{$WORKSTATION_YELLOW}%1{◷%} $(workstation_format_duration)%f")
  [[ -n $VIRTUAL_ENV ]] &&
    segments+=("%F{$WORKSTATION_PURPLE}py:${VIRTUAL_ENV:t}%f")
  (( WORKSTATION_JOB_COUNT > 0 )) &&
    segments+=("%F{$WORKSTATION_CYAN}jobs:$WORKSTATION_JOB_COUNT%f")
  segments+=("%F{$WORKSTATION_BLUE}%D{%H:%M}%f")
  print -nr -- "${(j:  :)segments}"
}

function workstation_prompt_symbol() {
  if (( WORKSTATION_LAST_STATUS == 0 )); then
    print -nr -- "%F{$WORKSTATION_GREEN}%1{❯%}%f"
  else
    print -nr -- "%F{$WORKSTATION_RED}%1{❯%}%f"
  fi
}

PROMPT='$(workstation_prompt_context)%F{$WORKSTATION_CYAN}%~%f $(git_prompt_info)$(git_prompt_status)'
PROMPT+=$'\n$(workstation_prompt_symbol) '
RPROMPT='$(workstation_right_prompt)'

# Capture status before Oh My Zsh's other precmd hooks can replace it.
autoload -Uz add-zsh-hook
add-zsh-hook preexec workstation_preexec
add-zsh-hook precmd workstation_precmd
preexec_functions=(workstation_preexec ${preexec_functions:#workstation_preexec})
precmd_functions=(workstation_precmd ${precmd_functions:#workstation_precmd})

ZSH_THEME_GIT_PROMPT_PREFIX="%F{$WORKSTATION_BLUE}git:(%F{$WORKSTATION_PURPLE}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f "
ZSH_THEME_GIT_PROMPT_DIRTY="%F{$WORKSTATION_BLUE})"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{$WORKSTATION_BLUE}) %F{$WORKSTATION_GREEN}%1{✓%}"

ZSH_THEME_GIT_PROMPT_ADDED="%F{$WORKSTATION_GREEN} +%f"
ZSH_THEME_GIT_PROMPT_MODIFIED="%F{$WORKSTATION_YELLOW} ~%f"
ZSH_THEME_GIT_PROMPT_RENAMED="%F{$WORKSTATION_CYAN} %1{»%}%f"
ZSH_THEME_GIT_PROMPT_DELETED="%F{$WORKSTATION_RED} -%f"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%F{$WORKSTATION_CYAN} ?%f"
ZSH_THEME_GIT_PROMPT_STASHED="%F{$WORKSTATION_PURPLE} %1{≡%}%f"
ZSH_THEME_GIT_PROMPT_UNMERGED="%F{$WORKSTATION_RED} !%f"
ZSH_THEME_GIT_PROMPT_AHEAD="%F{$WORKSTATION_GREEN} %1{↑%}%f"
ZSH_THEME_GIT_PROMPT_BEHIND="%F{$WORKSTATION_YELLOW} %1{↓%}%f"
ZSH_THEME_GIT_PROMPT_DIVERGED="%F{$WORKSTATION_RED} %1{↕%}%f"
