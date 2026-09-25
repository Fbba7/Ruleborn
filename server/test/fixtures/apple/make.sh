#!/usr/bin/env bash
# A stand-in for Apple's certificate chain, for the server's tests only:
# a root, an intermediate carrying Apple's intermediate marker, an EC P-256
# leaf carrying the StoreKit marker that signs StoreKit-style JWS and an RSA
# leaf, named for Apple Inc., that signs Game Center identity payloads. Then
# the refusals: an RSA leaf with the StoreKit marker, an EC leaf under the
# same intermediate without it (as a developer's own certificate would be),
# and a stranger's root. The keys are test keys and sign nothing real.
# Re-run to regenerate; the tests read the PEMs.
set -euo pipefail
cd "$(dirname "$0")"
days=36500
# Apple's marker OIDs: its WWDR intermediate and its StoreKit signing leaf.
intermediate_oid=1.2.840.113635.100.6.2.1
storekit_oid=1.2.840.113635.100.6.11.1
ext() { printf '%s\n' "basicConstraints=critical,CA:$1" "keyUsage=critical,$2" "${@:4}" > "$3"; }
ext TRUE keyCertSign,cRLSign ca.ext "$intermediate_oid=ASN1:NULL"
ext FALSE digitalSignature leaf.ext
ext FALSE digitalSignature storekit.ext "$storekit_oid=ASN1:NULL"

openssl ecparam -name prime256v1 -genkey -noout -out root.key
openssl req -x509 -new -key root.key -sha256 -days $days -subj "/CN=Test Root CA" \
  -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" -out root.pem

openssl ecparam -name prime256v1 -genkey -noout -out intermediate.key
openssl req -new -key intermediate.key -subj "/CN=Test Intermediate CA" -out intermediate.csr
openssl x509 -req -in intermediate.csr -CA root.pem -CAkey root.key -CAcreateserial -sha256 -days $days \
  -extfile ca.ext -out intermediate.pem

# leaf NAME KEYFILE SUBJECT EXTFILE: a leaf the intermediate issues.
leaf() {
  openssl req -new -key "$2" -subj "$3" -out "$1.csr"
  openssl x509 -req -in "$1.csr" -CA intermediate.pem -CAkey intermediate.key -CAcreateserial -sha256 \
    -days $days -extfile "$4" -out "$1.pem"
}

openssl ecparam -name prime256v1 -genkey -noout -out storekit.key
leaf storekit storekit.key "/CN=Test StoreKit Signing" storekit.ext

openssl genrsa -out gamecenter.key 2048
leaf gamecenter gamecenter.key "/O=Apple Inc./CN=Test Game Center Signing" leaf.ext

openssl genrsa -out storekit-rsa.key 2048
leaf storekit-rsa storekit-rsa.key "/CN=Test StoreKit RSA" storekit.ext

openssl ecparam -name prime256v1 -genkey -noout -out developer.key
leaf developer developer.key "/CN=Test Developer Certificate" leaf.ext

# A stranger's root, for the refusals.
openssl ecparam -name prime256v1 -genkey -noout -out stranger.key
openssl req -x509 -new -key stranger.key -sha256 -days $days -subj "/CN=Stranger Root" \
  -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" -out stranger.pem

rm -f ./*.csr ./*.ext ./*.srl
