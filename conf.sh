#!/bin/bash

set -e

CONFIG_PATH="./config"
DATA_PATH="$CONFIG_PATH/data"
ZIP_NAME="OpenVPN-TCP-Linux.zip"
ZIP_FILE="$DATA_PATH/OpenVPN-TCP-Linux.zip"
CREDS_FILE="$CONFIG_PATH/credentials.conf"
files=(
  "TorGuard.USA-LAS-VEGAS.ovpn"
  "TorGuard.USA-LOS.ANGELES.ovpn"
  "TorGuard.USA-SAN-FRANCISCO.ovpn"
  "TorGuard.USA-SEATTLE.ovpn"
)
FINAL_CONF="$CONFIG_PATH/vpn.conf"

if [ -d "$CONFIG_PATH" ]; then
  echo "[CLEAN] previous install"
  rm -rf "$CONFIG_PATH"/
fi

echo "[CREATE] folders"
mkdir -p "$DATA_PATH"

echo "[DOWNLOAD] data"
wget "https://torguard.net/downloads/$ZIP_NAME" -P "$DATA_PATH"

echo "[EXTRACT] data"
unzip -j -u -q "$ZIP_FILE" -d "$DATA_PATH"

echo "[REMOVE] archive"
rm "$ZIP_FILE"

echo "[UPDATE] data permissions"
chmod 0777 "$DATA_PATH/update-resolv-conf"

echo "[CREATE] credentials"
exec < /dev/tty
echo "  Enter Username:"; read username
echo "  Enter Password:"; read password
exec <&-
touch "$CREDS_FILE"
printf "$username\n$password\n" > "$CREDS_FILE"

echo "[UPDATE] credentials permissions"
chmod go-rwx "$CREDS_FILE"

echo "[Update] values in ovpn files"
find "$DATA_PATH" -type f -name "*.ovpn" \
  -exec sed -i 's|auth-user-pass|auth-user-pass credentials.conf|' {} + \
  -exec sed -i 's|/etc/openvpn/||' {} + \
  -exec sed -i 's|proto tcp|proto udp|' {} +

echo "[MOVE] files"
mv "$DATA_PATH/ca.crt" "$CONFIG_PATH/"
mv "$DATA_PATH/update-resolv-conf" "$CONFIG_PATH/"

echo "[COMBINE] Remotes from specified files"
filesStr=""
for i in "${!files[@]}"; do
  file="${files[$i]}"
  matches=$(grep "remote " "$DATA_PATH/$file")
  if [[ "$i" == "0" ]]; then
    filesStr="${filesStr}""${matches}"
  else
    filesStr="${filesStr}"$'\n'"${matches}"
  fi
done

echo "[CREATE] VPN config file"
parsed=""
matchNum=1
while IFS= read -r line; do
  if [[ "$line" =~ ^remote.* ]]; then
    if [[ "$matchNum" == "2" ]]; then
      parsed="${parsed}${filesStr}"$'\n'
    fi
    matchNum=$((matchNum + 1))
  else
    parsed="${parsed}${line}"$'\n'
  fi
done < <(cat "$DATA_PATH/${files[0]}")
echo "$parsed" > "$FINAL_CONF"
