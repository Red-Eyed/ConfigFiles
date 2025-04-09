if status is-interactive
    # Commands to run in interactive sessions can go here
end

function setup_ssh_agent
    for line in (keychain --eval id_rsa)
        eval $line
    end
end

setup_ssh_agent
