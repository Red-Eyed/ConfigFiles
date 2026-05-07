# Starts or reuses a persistent ssh-agent across shell sessions.
#
# Uses a fixed socket path per agent process (~/.ssh/ssh-agent-<pid>.sock).
# On each shell init, scans for a live existing agent and reuses it; cleans up
# dead sockets and spawns a new agent only if none are found.
# No-op on macOS — launchd manages the agent and SSH_AUTH_SOCK is pre-set.
[ "$(uname -s)" = "Darwin" ] && return 0

export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent-$$.sock"

for _sock in "$HOME"/.ssh/ssh-agent-*.sock; do
  if SSH_AUTH_SOCK="$_sock" ssh-add -l > /dev/null 2>&1; then
    export SSH_AUTH_SOCK="$_sock"
    break
  fi
  rm -f "$_sock"
done

if ! ssh-add -l > /dev/null 2>&1; then
  ssh-agent -a "$SSH_AUTH_SOCK" > /dev/null
  ssh-add
fi

unset _sock
