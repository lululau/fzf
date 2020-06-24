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

  __fzf_use_tmux__() {
    [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ] && [[ $TMUX_VERSION_MAJOR -ge 2 ]]
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

  # CTRL-R - Paste the selected command from history into the command line
  fzf-history-widget() {
    local FZF_HEIGHT=$([[ -n "$FZF_TMUX" && -n "$TMUX_PANE" ]] && echo ${FZF_TMUX_HEIGHT:-40%} || echo 100%)
    local selected num
    setopt localoptions noglobsubst noposixbuiltins pipefail 2> /dev/null
    selected=$(histdb --sep $'\t' |
                 FZF_DEFAULT_OPTS="--height ${FZF_HEIGHT} $FZF_DEFAULT_OPTS --tac -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort,alt-enter:execute(echo)+accept $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd))
    local ret=$?
    if [ -n "$selected" ]; then
      if [ "$selected[1]" = $'\n' ]; then
        cmd=$(echo -E "${selected:1}" | ruby -ne 'print "cd %s" % $_.split("\t", 4)[2].gsub(" ", "\\ ")')
      else
        cmd=$(echo -E "$selected" | ruby -ne 'print $_.split("\t", 4)[-1]' )
      fi
      LBUFFER=$cmd
    fi
    zle redisplay
    typeset -f zle-line-init >/dev/null && zle zle-line-init
    return $ret
  }
  zle     -N   fzf-history-widget
  bindkey '^R' fzf-history-widget
fi
