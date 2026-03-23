# Set up Homebrew shell environment for Apple Silicon Macs
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
