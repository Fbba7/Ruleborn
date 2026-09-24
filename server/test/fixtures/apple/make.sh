#!/usr/bin/env bash
# A stand-in for Apple's certificate chain, for the server's tests only:
# a root, an intermediate, an EC leaf that signs StoreKit-style JWS and an
# RSA leaf that signs Game Center identity payloads. The keys are test keys
# and sign nothing real. Re-run to regenerate; the tests read the PEMs.
set -euo pipefail
cd "$(dirname "$0")"
days=36500
ext() { printf '%s\n' "basicConstraints=critical,CA:$1" "keyUsage=critical,$2" > "$3"; }
ext TRUE keyCertSign,cRLSign ca.ext
ext FALSE digitalSignature leaf.ext

openssl ecparam -name prime256v1 -genkey -noout -out root.key
openssl req -x509 -new -key root.key -sha256 -days $days -subj "/CN=Test Root CA" \
  -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" -out root.pem

openssl ecparam -name prime256v1 -genkey -noout -out intermediate.key
openssl req -new -key intermediate.key -subj "/CN=Test Intermediate CA" -out intermediate.csr
openssl x509 -req -in intermediate.csr -CA root.pem -CAkey root.key -CAcreateserial -sha256 -days $days \
  -extfile ca.ext -out intermediate.pem

openssl ecparam -name prime256v1 -genkey -noout -out storekit.key
openssl req -new -key storekit.key -subj "/CN=Test StoreKit Signing" -out storekit.csr
openssl x509 -req -in storekit.csr -CA intermediate.pem -CAkey intermediate.key -CAcreateserial -sha256 \
  -days $days -extfile leaf.ext -out storekit.pem

openssl genrsa -out gamecenter.key 2048
openssl req -new -key gamecenter.key -subj "/CN=Test Game Center Signing" -out gamecenter.csr
openssl x509 -req -in gamecenter.csr -CA intermediate.pem -CAkey intermediate.key -CAcreateserial -sha256 \
  -days $days -extfile leaf.ext -out gamecenter.pem

# A stranger's root, for the refusals.
openssl ecparam -name prime256v1 -genkey -noout -out stranger.key
openssl req -x509 -new -key stranger.key -sha256 -days $days -subj "/CN=Stranger Root" \
  -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" -out stranger.pem

rm -f ./*.csr ./*.ext ./*.srl
