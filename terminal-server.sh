#!/bin/zsh
# ── Terminal on your phone ────────────────────────────────────────────────
# Starts a web terminal to THIS Mac and exposes it through a private tunnel,
# so you can open it on your phone and run `claude`, edit code, etc.
# Requires: ttyd + cloudflared  (the script installs them via brew if missing).
# Stop it anytime with Ctrl-C.  ⚠ The printed URL grants shell access — keep private.

command -v ttyd >/dev/null 2>&1        || { echo "Installing ttyd…";        brew install ttyd; }
command -v cloudflared >/dev/null 2>&1 || { echo "Installing cloudflared…"; brew install cloudflared; }

PORT=7681
PASS="${TERM_PASS:-$(openssl rand -hex 5)}"
LOG=/tmp/term-tunnel.log; : > "$LOG"

echo "starting terminal server on :$PORT …"
ttyd -p "$PORT" -W -c "user:$PASS" zsh -l >/tmp/ttyd.log 2>&1 &
TTYD=$!
cloudflared tunnel --url "http://localhost:$PORT" >"$LOG" 2>&1 &
CF=$!
trap 'kill $TTYD $CF 2>/dev/null; echo; echo "terminal stopped."' EXIT INT TERM

URL=""
for i in {1..25}; do
  URL=$(grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG" | head -1)
  [ -n "$URL" ] && break; sleep 1
done

echo
echo "=================================================================="
echo "  📱 PHONE URL :  ${URL:-'(still starting — check /tmp/term-tunnel.log)'}"
echo "     LOGIN     :  user"
echo "     PASSWORD  :  $PASS"
echo
echo "  → paste the URL into the Terminal tile in your Study app,"
echo "    log in, then type:  claude"
echo
echo "  ⚠ This is a shell into this Mac. Keep the URL + password private."
echo "    Press Ctrl-C to stop the server."
echo "=================================================================="
wait
