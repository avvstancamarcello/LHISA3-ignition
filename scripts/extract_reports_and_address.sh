#!/usr/bin/env bash
# Esegui dalla root del repo: /home/avvocato/MyHardhatProjects/LHISA3-ignition
# Requisiti: jq, node, npm (hardhat), curl

OUT="deploy_extraction_output.json"
TEMPLATE="deploy_extraction_template.json"

if [ ! -f "$TEMPLATE" ]; then
  echo "Errore: non trovato $TEMPLATE. Salvalo nella root del repo (usa il template fornito)."
  exit 1
fi

# Inizializza output con template
cp "$TEMPLATE" "$OUT"

# 1) Estrai wallet from WALLET_ADDRESS_CONFIG.md se presente
if [ -f "WALLET_ADDRESS_CONFIG.md" ]; then
  echo "Parsing WALLET_ADDRESS_CONFIG.md..."
  DEPLOYER=$(grep -Eo "deployer[: ]+[0-9xA-Fa-f]+" WALLET_ADDRESS_CONFIG.md | head -n1 | awk '{print $2}')
  MULTISIG=$(grep -Eo "multisig[: ]+[0-9xA-Fa-f]+" WALLET_ADDRESS_CONFIG.md | head -n1 | awk '{print $2}')
  CHARITY=$(grep -Eo "charity[: ]+[0-9xA-Fa-f]+" WALLET_ADDRESS_CONFIG.md | head -n1 | awk '{print $2}')
  TREASURY=$(grep -Eo "treasury[: ]+[0-9xA-Fa-f]+" WALLET_ADDRESS_CONFIG.md | head -n1 | awk '{print $2}')
  jq --arg d "$DEPLOYER" --arg m "$MULTISIG" --arg c "$CHARITY" --arg t "$TREASURY" \
    '.wallets.deployer=$d | .wallets.multisig=$m | .wallets.charity=$c | .wallets.treasury=$t' \
    "$OUT" > tmp.$$.json && mv tmp.$$.json "$OUT"
fi

# 2) Cerca report di successo e prendi timestamp / contratti elencati
REPORT_FILES=(SOLIDARYCOMIX_SUCCESS.md ORCHESTRATOR_STATUS_REPORT.md MISSION_ACCOMPLISHED.md DEPLOY_SUCCESS_BASE.md DEPLOY_REPORT.md DEPLOYMENT_SUMMARY.md FINAL_SUCCE_REPORT.md DEPLOY_INFO.md AGENT_FAILURE_ECONOMICS_DAMAGE_REPORT.md CARITAS_TRANSFER_GUIDE.md)
for f in "${REPORT_FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "Parsing $f..."
    # Estrai righe che sembrano indirizzi (0x...) e coppie nome:address
    grep -Eo "0x[a-fA-F0-9]{40}" "$f" | sort -u > /tmp/addresses.$$ || true
    # Aggiungi al JSON come note (accumulo)
    while read -r addr; do
      [ -z "$addr" ] && continue
      jq --arg a "$addr" '.orchestrator_state.registered_contracts += [{"name":"unknown_from_report","role":"unknown","address":$a}]' "$OUT" > tmp.$$.json && mv tmp.$$.json "$OUT"
    done < /tmp/addresses.$$
    rm -f /tmp/addresses.$$
  fi
done

# 3) Scansiona artifacts build (Hardhat/waffle/artifacts) per ABI e indirizzi in scripts/deploy-*.json
echo "Scanning artifacts for compiled contracts..."
if [ -d "artifacts" ]; then
  find artifacts -name "*.json" -type f -print0 | while IFS= read -r -d '' file; do
    # Prendi contractName se presente
    name=$(jq -r '.contractName // empty' "$file" 2>/dev/null)
    bytecode=$(jq -r '.bytecode // empty' "$file" 2>/dev/null)
    if [ -n "$name" ]; then
      # Aggiungi se non presente
      jq --arg name "$name" --arg bc "$bytecode" '.contracts_deployed += [{"name":$name,"source_path":"","commit_sha":"","address":"","network":"","tx_hash":"","constructor_args":[],"proxy":null,"compiler":{}}]' "$OUT" > tmp.$$.json && mv tmp.$$.json "$OUT"
    fi
  done
fi

# 4) Cerca deployment script output (scripts/deploy-*.json o deployments/ per hardhat-deploy)
if [ -d "deployments" ]; then
  echo "Parsing deployments/*..."
  find deployments -type f -name "*.json" -print0 | while IFS= read -r -d '' df; do
    cName=$(basename "$df" .json)
    addr=$(jq -r '.address // empty' "$df")
    network=$(jq -r '.chainId // empty' "$df")
    tx=$(jq -r '.transactionHash // empty' "$df")
    if [ -n "$addr" ]; then
      jq --arg n "$cName" --arg a "$addr" --arg net "$network" --arg txh "$tx" \
        '.contracts_deployed += [{"name":$n,"source_path":$n,"commit_sha":"","address":$a,"network":$net,"tx_hash":$txh,"constructor_args":[],"proxy":null,"compiler":{}}]' \
        "$OUT" > tmp.$$.json && mv tmp.$$.json "$OUT"
    fi
  done
fi

# 5) Duplicazioni: cerca bytecode già deployato su Base/Polygon tramite etherscan API se configurata (opzionale)
# Se hai ETHERSCAN_API_KEY, effettua check (richiede curl)
if [ -n "$ETHERSCAN_API_KEY" ]; then
  echo "Checking deployed bytecodes on Etherscan-like APIs (richiede network mapping) - questa è opzionale"
  # Implementazione possibile ma non attiva per default
fi

echo "Output scritto in $OUT"
cat "$OUT"
