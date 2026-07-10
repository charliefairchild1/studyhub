#!/bin/zsh
# ── Permanent phone terminal over Tailscale ───────────────────────────────
# Gives a STABLE https URL you paste into the Terminal app once, forever.
# One-time prerequisites (see the steps your assistant gave you):
#   1. Install Tailscale on this Mac AND your iPhone; log both into the same account.
#   2. In the Tailscale admin console → Settings → enable HTTPS certificates + MagicDNS.
# After that, just run this script whenever you want the terminal available.

TS=/Applications/Tailscale.app/Contents/MacOS/Tailscale
command -v tailscale >/dev/null 2>&1 && TS=tailscale
command -v ttyd >/dev/null 2>&1 || { echo "Installing ttyd…"; brew install ttyd; }

PORT=7681
PASSFILE="$HOME/.study_term_pass"
[ -f "$PASSFILE" ] || openssl rand -hex 5 > "$PASSFILE"    # stable password, saved once
PASS=$(cat "$PASSFILE")

echo "starting terminal on :$PORT …"
pkill -f "ttyd -p $PORT" 2>/dev/null; sleep 1
ttyd -p "$PORT" -W -c "user:$PASS" zsh -l >/tmp/ttyd.log 2>&1 &
TTYD=$!
sleep 1

# expose it over the tailnet with HTTPS (stable hostname)
"$TS" serve --bg "$PORT" 2>/tmp/tsserve.log
sleep 1
URL=$("$TS" serve status 2>/dev/null | grep -Eo 'https://[^ ]+' | head -1)

echo
echo "=================================================================="
echo "  📱 PERMANENT URL :  ${URL:-'(check: '"$TS"' serve status)'}"
echo "     LOGIN         :  user"
echo "     PASSWORD      :  $PASS   (stable — same every time)"
echo
echo "  Paste that URL into the Terminal app once. It never changes."
echo "  Leave this window open (or run again after a reboot)."
echo "  Stop sharing:  $TS serve --https=443 off   &&  pkill -f 'ttyd -p $PORT'"
echo "=================================================================="
wait $TTYD
