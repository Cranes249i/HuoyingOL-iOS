#!/usr/bin/env bash
# Generates a throwaway self-signed certificate (.p12) and a dummy development
# provisioning profile. ADT needs both to assemble an IPA; the resulting IPA is
# NOT installable as-is and must be re-signed with a real Apple certificate.
set -euo pipefail

OUT_DIR="${1:-cert}"
P12_PASSWORD="${P12_PASSWORD:-huoying}"
TEAM_ID="${TEAM_ID:-HUOYING0L1}"            # fake 10-char team id
APP_ID="${APP_ID:-local.huoying.airgame}"

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

if [[ -f ios-dev.p12 && -f HuoyingOL.mobileprovision ]]; then
  echo "signing material already present in $OUT_DIR"
  exit 0
fi

openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
  -keyout key.pem -out cert.pem \
  -subj "/UID=${TEAM_ID}/CN=iPhone Developer: HuoyingOL (${TEAM_ID})/OU=${TEAM_ID}/O=HuoyingOL/C=CN" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=codeSigning" >/dev/null 2>&1

openssl pkcs12 -export -inkey key.pem -in cert.pem -name "HuoyingOL dev" \
  -out ios-dev.p12 -passout "pass:${P12_PASSWORD}"

CERT_B64=$(openssl x509 -in cert.pem -outform DER | openssl base64 -A)
RAW=$(openssl rand -hex 16 | tr a-f A-F)
UUID="${RAW:0:8}-${RAW:8:4}-${RAW:12:4}-${RAW:16:4}-${RAW:20:12}"

cat > profile.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AppIDName</key>
	<string>HuoyingOL</string>
	<key>ApplicationIdentifierPrefix</key>
	<array>
		<string>${TEAM_ID}</string>
	</array>
	<key>CreationDate</key>
	<date>2026-01-01T00:00:00Z</date>
	<key>Platform</key>
	<array>
		<string>iOS</string>
		<string>xrOS</string>
		<string>visionOS</string>
	</array>
	<key>IsXcodeManaged</key>
	<false/>
	<key>DeveloperCertificates</key>
	<array>
		<data>${CERT_B64}</data>
	</array>
	<key>Entitlements</key>
	<dict>
		<key>application-identifier</key>
		<string>${TEAM_ID}.${APP_ID}</string>
		<key>com.apple.developer.team-identifier</key>
		<string>${TEAM_ID}</string>
		<key>get-task-allow</key>
		<true/>
		<key>keychain-access-groups</key>
		<array>
			<string>${TEAM_ID}.*</string>
		</array>
	</dict>
	<key>ExpirationDate</key>
	<date>2036-01-01T00:00:00Z</date>
	<key>Name</key>
	<string>HuoyingOL Development</string>
	<key>ProvisionedDevices</key>
	<array>
		<string>00008030-000000000000000A</string>
	</array>
	<key>TeamIdentifier</key>
	<array>
		<string>${TEAM_ID}</string>
	</array>
	<key>TeamName</key>
	<string>HuoyingOL</string>
	<key>TimeToLive</key>
	<integer>3650</integer>
	<key>UUID</key>
	<string>${UUID}</string>
	<key>Version</key>
	<integer>1</integer>
</dict>
</plist>
EOF

openssl cms -sign -in profile.plist -signer cert.pem -inkey key.pem \
  -outform DER -nodetach -binary -nosmimecap -md sha256 \
  -out HuoyingOL.mobileprovision

ls -l ios-dev.p12 HuoyingOL.mobileprovision
echo "signing material generated in $OUT_DIR"
