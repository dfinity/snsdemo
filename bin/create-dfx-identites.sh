#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

for I in {1..4}; do
  echo "Creating icp-cli identity 'ident-$I' from ../identities/identity-$I.pem"
  icp identity delete "ident-$I" 2>/dev/null || true
  icp identity import "ident-$I" --from-pem "../identities/identity-$I.pem" --storage plaintext
  PRINCIPAL_ID="$(icp identity principal --identity "ident-$I")"
  ACCOUNT_ID="$(icp identity account-id --identity "ident-$I")"
  echo "PrincipalId: $PRINCIPAL_ID"
  echo "AccountId: $ACCOUNT_ID"

  echo ""
done

icp identity default ident-1
