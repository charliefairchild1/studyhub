#!/bin/zsh
# Attach this Mac's Terminal to the SAME tmux session the phone uses ("phone").
# Type on either device and both show the same thing, live.
exec /opt/homebrew/bin/tmux new-session -A -s phone
