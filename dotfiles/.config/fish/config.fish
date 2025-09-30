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


fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
