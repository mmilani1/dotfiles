function whats-running-on-port -d "Returns the PID running on a given PORT"
    if test (count $argv) = 0
        lsof -iTCP -sTCP:LISTEN -n -P
    else if test (count $argv) = 1
        lsof -iTCP:$argv -sTCP:LISTEN -n -P
    end
end