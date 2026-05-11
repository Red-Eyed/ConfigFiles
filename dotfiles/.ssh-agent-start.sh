# Starts or reuses a persistent ssh-agent across shell sessions.
#
# Uses a fixed socket path per agent process (~/.ssh-agents/<pid>.sock).
# On each shell init, scans for a live existing agent and reuses it; cleans up
# dead sockets and spawns a new agent only if none are found.
# No-op on macOS — launchd manages the agent and SSH_AUTH_SOCK is pre-set.
[ "$(uname -s)" = "Darwin" ] && return 0

_pid=$$
mkdir -p "$HOME/.ssh-agents"
export SSH_AUTH_SOCK="$HOME/.ssh-agents/$_pid.sock"

for _sock in $(find "$HOME/.ssh-agents" -maxdepth 1 -name '*.sock' 2>/dev/null); do
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

unset _sock _pid
