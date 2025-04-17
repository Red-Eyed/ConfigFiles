if status is-interactive
    # Commands to run in interactive sessions can go here
end

## ls aliases
if type -q exa
    # Use exa as a better ls replacement
    alias ls='exa --group-directories-first --color=always'
    alias ll='exa -l --group-directories-first --color=always'
    alias la='exa -la --group-directories-first --color=always'
    alias lt='exa -lT --level=2 --group-directories-first --color=always'
    alias l.='exa -la --group-directories-first --color=always | grep "^\."'
end

# rm aliases
if type -q trashy
    # Safe replacements for dangerous commands
    alias rm='trashy'
    alias rmdir='trashy'
    alias trash='trashy'
end

function setup_ssh_agent
    # Check if keychain is installed and in PATH
    if not type -q keychain
        echo "setup_ssh_agent: 'keychain' not found. Please install it to manage your SSH agent."
        return 1
    end

    # Call keychain to manage the ssh-agent and output eval commands
    # `--eval` makes keychain print Bash-style exports
    # `id_rsa` is the key you want to load (change or add more as needed)
    for line in (keychain --eval id_rsa)

        # Match only lines that look like: SSH_AUTH_SOCK=...; export SSH_AUTH_SOCK;
        # We skip anything like 'echo' or unrelated shell statements
        if string match -rq '^(SSH_.*=)' $line

            # Strip everything after the first semicolon to get: SSH_VAR=value
            set -l cleaned (string replace -r ';.*' '' -- $line)

            # Split on '=' to get [SSH_VAR, value]
            set -l kv (string split '=' $cleaned)

            # Export as Fish-style environment variable
            # Equivalent to: set -gx SSH_AUTH_SOCK /tmp/ssh-xxxxxx/agent.1234
            set -gx $kv[1] $kv[2]
        end
    end
end

# setup_ssh_agent
