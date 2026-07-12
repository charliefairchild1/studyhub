#!/bin/zsh
# Supervisor run by the launchd agent (com.study.terminal) at every login.
# Ensures userspace tailscaled + the tailnet HTTPS serve are up, then runs ttyd
# in the foreground so launchd can keep it alive.
SOCK=/tmp/tailscaled.sock
PORT=7681
TS=/opt/homebrew/bin/tailscale
TSD=/opt/homebrew/bin/tailscaled
TTYD=/opt/homebrew/bin/ttyd
ts(){ $TS --socket=$SOCK "$@"; }

# 1. userspace tailscaled (no root)
if ! pgrep -f "tailscaled --tun=userspace" >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/tailscale"
  nohup $TSD --tun=userspace-networking --socket=$SOCK --statedir="$HOME/.config/tailscale" >/tmp/tailscaled.log 2>&1 &
  sleep 5
fi
ts up --hostname=study-mac >/dev/null 2>&1 || true

# 2. publish over the tailnet with HTTPS (idempotent; persists in the daemon)
ts serve --bg $PORT >/tmp/serve.log 2>&1 || true

# 3. stable password
PASSFILE="$HOME/.study_term_pass"
[ -f "$PASSFILE" ] || /usr/bin/openssl rand -hex 5 > "$PASSFILE"
PASS=$(cat "$PASSFILE")

# 4. run the terminal attached to a persistent tmux session, so disconnecting
#    (app backgrounded, network blip) resumes the SAME session on reconnect —
#    your claude session keeps running. Foreground so launchd supervises it.
# caffeinate wraps ttyd: the Mac is held awake (no idle/system/disk sleep) for
# exactly as long as the terminal server runs — which is always, since launchd
# keeps it alive. No sudo needed. -i idle, -s system(on AC), -m disk.
exec /usr/bin/caffeinate -i -s -m $TTYD -p $PORT -W /opt/homebrew/bin/tmux new-session -A -s phone
