#!/bin/bash
# deploy-final.sh

# Prendi la private key SENZA newline
PRIVATE_KEY="8f2a46c1eb83a1fcec604207c4c0e34c2b46b2d045883311509cb592b282dfb1"
# Rimuovi eventuali newline
CLEAN_PRIVATE_KEY=$(printf "%s" "$PRIVATE_KEY")
export PRIVATE_KEY="$CLEAN_PRIVATE_KEY"

echo "🔧 Private key length: $(echo -n $PRIVATE_KEY | wc -c)"

# Deploy
npx hardhat run scripts/deploy-base.cjs --network base
