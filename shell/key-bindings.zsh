# Key bindings
# ------------
if [[ $- == *i* ]]; then

# CTRL-T - Paste the selected file path(s) into the command line
__fsel() {
  local FZF_HEIGHT=$([[ -n "$FZF_TMUX" && -n "$TMUX_PANE" ]] && echo ${FZF_TMUX_HEIGHT:-40%} || echo 100%)
  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail 2> /dev/null
  eval "$cmd" | FZF_DEFAULT_OPTS="--height $FZF_HEIGHT $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@" | while read item; do
      # eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@" | while read item; do
    echo -n "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}

# ALT-T - Paste the selected file path(s) into the command line
__fsel_1() {
    local FZF_HEIGHT=$([[ -n "$FZF_TMUX" && -n "$TMUX_PANE" ]] && echo ${FZF_TMUX_HEIGHT:-40%} || echo 100%)
    local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -maxdepth 1 \\(  -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
          -o -type f -print \
          -o -type d -print \
          -o -type l -print 2> /dev/null | cut -b3-"}"
    setopt localoptions pipefail 2> /dev/null
    eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_HEIGHT} $FZF_DEFAULT_OPTS $FZF_ALT_T_OPTS" $(__fzfcmd) -m "$@" | while read item; do
        echo -n "${(q)item} "
    done
    local ret=$?
    echo
    return $ret
}

__fzf_use_tmux__() {
  [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ]
}

__fzfcmd() {
  __fzf_use_tmux__ &&
    echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}

fzf-file-widget() {
    LBUFFER="${LBUFFER}$(__fsel)"
    local ret=$?
    zle redisplay
    typeset -f zle-line-init >/dev/null && zle zle-line-init
    return $ret
}
zle     -N   fzf-file-widget
bindkey '^T' fzf-file-widget

fzf-file-widget-1() {
  LBUFFER="${LBUFFER}$(__fsel_1)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}
zle     -N   fzf-file-widget-1
bindkey '\et' fzf-file-widget-1

# ALT-C - cd into the selected directory
fzf-cd-widget() {
  local FZF_HEIGHT=$([[ -n "$FZF_TMUX" && -n "$TMUX_PANE" ]] && echo ${FZF_TMUX_HEIGHT:-40%} || echo 100%)
  local cmd="${FZF_ALT_C_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type d -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail 2> /dev/null
  local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_HEIGHT} $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" $(__fzfcmd) +m)"
  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi
  cd "$dir"
  local ret=$?
  zle reset-prompt
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}
zle     -N    fzf-cd-widget
bindkey '\ec' fzf-cd-widget

# ALT-V - cd into the selected directory(maxdepth=1)
fzf-cd-widget-1() {
    local FZF_HEIGHT=$([[ -n "$FZF_TMUX" && -n "$TMUX_PANE" ]] && echo ${FZF_TMUX_HEIGHT:-40%} || echo 100%)
    local cmd="${FZF_ALT_C_COMMAND:-"command find -L . -maxdepth 1 \\( -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
          -o -type d -print 2> /dev/null | cut -b3-"}"
    setopt localoptions pipefail 2> /dev/null
    local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_HEIGHT} $FZF_DEFAULT_OPTS $FZF_ALT_V_OPTS" $(__fzfcmd) +m)"
    if [[ -z "$dir" ]]; then
        zle redisplay
        return 0
    fi
    cd "$dir"
    local ret=$?
    zle reset-prompt
    typeset -f zle-line-init >/dev/null && zle zle-line-init
    return $ret
}
zle     -N    fzf-cd-widget-1
bindkey '\ev' fzf-cd-widget-1

# CTRL-R - Paste the selected command from history into the command line
fzf-history-widget() {
  local FZF_HEIGHT=$([[ -n "$FZF_TMUX" && -n "$TMUX_PANE" ]] && echo ${FZF_TMUX_HEIGHT:-40%} || echo 100%)
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail 2> /dev/null
  selected=( $(fc -l 1 |
                   FZF_DEFAULT_OPTS="--height ${FZF_HEIGHT} $FZF_DEFAULT_OPTS --tac -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}
zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget

fzf-autojump-widget() {
    local FZF_HEIGHT=$([[ -n "$FZF_TMUX" && -n "$TMUX_PANE" ]] && echo ${FZF_TMUX_HEIGHT:-40%} || echo 100%)
    setopt localoptions pipefail 2> /dev/null
    local dir=$({ dirs -pl; autojump -s | sed -n '/^_______/!p; /^_______/q'  | cut -d$'\t' -f2; } | FZF_DEFAULT_OPTS="--height ${FZF_HEIGHT} $FZF_DEFAULT_OPTS $FZF_ALT_J_OPTS" $(__fzfcmd) +m)
    echo "$dir"
    if [[ -z "$dir" || ! -e "$dir" ]]; then
        zle redisplay
        return 0
    fi
    cd "$dir"
    local ret=$?
    zle reset-prompt
    typeset -f zle-line-init >/dev/null && zle zle-line-init
    return $ret
}

zle     -N   fzf-autojump-widget
bindkey '\ej' fzf-autojump-widget

fzf-autojump-widget-1() {
    local FZF_HEIGHT=$([[ -n "$FZF_TMUX" && -n "$TMUX_PANE" ]] && echo ${FZF_TMUX_HEIGHT:-40%} || echo 100%)
    LBUFFER="${LBUFFER}$({dirs -pl; autojump -s | sed -n '/^_______/!p; /^_______/q'  | cut -d$'\t' -f2; } | FZF_DEFAULT_OPTS="--height ${FZF_HEIGHT} $FZF_DEFAULT_OPTS $FZF_ALT_J_OPTS" $(__fzfcmd) +m | sed "s#^#'#;s#\$#'#")"
    zle redisplay
}
zle     -N   fzf-autojump-widget-1
bindkey '\eJ' fzf-autojump-widget-1

tmux-capture-pane-widget() {
    local FZF_HEIGHT=$([[ -n "$FZF_TMUX" && -n "$TMUX_PANE" ]] && echo ${FZF_TMUX_HEIGHT:-40%} || echo 100%)
    LBUFFER="${LBUFFER}$(tmux capture-pane -pS - | perl -00 -pe 1 | FZF_DEFAULT_OPTS="--height ${FZF_HEIGHT} $FZF_DEFAULT_OPTS $FZF_ALT_O_OPTS" $(__fzfcmd) +m --tac | sed "s#^➜ *##;s#^#'#;s#\$#'#")"
    zle redisplay
}
zle     -N   tmux-capture-pane-widget
bindkey '\eo' tmux-capture-pane-widget
fi
