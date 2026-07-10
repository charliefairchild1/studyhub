#!/bin/zsh
# ── Permanent phone terminal over Tailscale (userspace, no sudo) ──────────
# Publishes a live terminal at a STABLE https URL you paste into the Terminal
# app once, forever:  https://study-mac.<your-tailnet>.ts.net
# Prereqs (already done once): tailscale CLI installed, logged in on Mac + phone,
# and HTTPS Certificates enabled in the Tailscale admin console.
# Just run this after a reboot (or add it to login items) to bring it back.

SOCK=/tmp/tailscaled.sock
PORT=7681
ts(){ /opt/homebrew/bin/tailscale --socket=$SOCK "$@"; }

# 1. userspace tailscaled (no root/kernel-extension needed)
if ! pgrep -f "tailscaled --tun=userspace" >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/tailscale"
  nohup /opt/homebrew/bin/tailscaled --tun=userspace-networking --socket=$SOCK \
        --statedir="$HOME/.config/tailscale" >/tmp/tailscaled.log 2>&1 &
  sleep 3
fi
ts up --hostname=study-mac >/dev/null 2>&1 || true   # already authenticated → no-op

# 3. the terminal itself — NO basic-auth (browsers don't send it over the ws
#    upgrade → "User code denied connection" → reconnect loop). Tailscale's
#    tailnet-only serve is the access control. Persistent tmux session "phone".
pgrep -f "ttyd -p $PORT" >/dev/null 2>&1 || \
  nohup /opt/homebrew/bin/ttyd -p $PORT -W /opt/homebrew/bin/tmux new-session -A -s phone >/tmp/ttyd.log 2>&1 &
sleep 1

# 4. publish it over the tailnet with HTTPS
ts serve --bg $PORT >/tmp/serve.log 2>&1
sleep 2
URL=$(ts serve status 2>/dev/null | grep -Eo 'https://[^ ]+' | head -1)

echo
echo "=================================================================="
echo "  📱 PERMANENT URL :  ${URL:-https://study-mac.<tailnet>.ts.net}"
echo "     LOGIN         :  none — Tailscale tailnet-only access"
echo
echo "  Paste the URL into the Terminal app once — it never changes."
echo "  Stop:  tailscale --socket=$SOCK serve --https=443 off ; pkill -f 'ttyd -p $PORT'"
echo "=================================================================="
