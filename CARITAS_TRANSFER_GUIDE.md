# 🏛️ Trasferimento Controllo SolidarySponsorVault a Caritas Internationalis

## 📋 Panoramica

Questo documento descrive come trasferire il controllo del contratto `SolidarySponsorVault` (deployato all'indirizzo `0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3` su Polygon) a Caritas Internationalis.

## 🔍 Stato Attuale

- **Contratto**: `SolidarySponsorVault`
- **Indirizzo**: `0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3`
- **Network**: Polygon (Chain ID: 137)
- **Owner Attuale**: `0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8`
- **Ruoli Attuali**: ADMIN_ROLE + SPONSOR_ROLE

## 🎯 Obiettivo

Trasferire i ruoli di controllo (`DEFAULT_ADMIN_ROLE` e `SPONSOR_ROLE`) del contratto SolidarySponsorVault all'indirizzo wallet di Caritas Internationalis.

## 📁 File Creati

### 1. Script di Trasferimento
- **File**: `scripts/transfer-to-caritas.cjs`
- **Funzione**: Trasferisce i ruoli AccessControl a Caritas
- **Sicurezza**: Verifica tutti i passaggi prima di revocare i propri permessi

### 2. Script di Verifica
- **File**: `scripts/verify-caritas-control.cjs`
- **Funzione**: Verifica lo stato dei ruoli post-trasferimento
- **Utilità**: Controllo di sicurezza dopo il trasferimento

### 3. Contratto Donation Manager (Opzionale)
- **File**: `contracts/LHISA3/solidary_roles/CaritasDonationManager.sol`
- **Funzione**: Gestisce donazioni MATIC verso Caritas con logging automatico
- **Caratteristiche**: Statistiche donazioni, messaggi, sicurezza ReentrancyGuard

## 🚀 Procedura di Trasferimento

### Step 1: Ottenere l'Indirizzo di Caritas
Prima di procedere, è necessario ottenere l'indirizzo wallet ufficiale di Caritas Internationalis.

### Step 2: Verifica Stato Attuale
```bash
# Verifica i ruoli attuali
npx hardhat run scripts/analyze-sponsor-vault.cjs --network polygon
```

### Step 3: Trasferimento Sicuro
```bash
# Trasferimento mantenendo i propri ruoli (RACCOMANDATO)
CARITAS_ADDRESS=0x[INDIRIZZO_CARITAS] npx hardhat run scripts/transfer-to-caritas.cjs --network polygon

# Trasferimento con revoca completa dei propri ruoli (ATTENZIONE!)
CARITAS_ADDRESS=0x[INDIRIZZO_CARITAS] REVOKE_OWN_ROLES=true npx hardhat run scripts/transfer-to-caritas.cjs --network polygon
```

### Step 4: Verifica Post-Trasferimento
```bash
# Verifica che Caritas abbia ricevuto i ruoli
CARITAS_ADDRESS=0x[INDIRIZZO_CARITAS] npx hardhat run scripts/verify-caritas-control.cjs --network polygon
```

## ⚠️ Considerazioni di Sicurezza

### Approccio Raccomandato: Dual Control
1. **Mantieni i tuoi ruoli**: Non revocare immediatamente i propri ruoli ADMIN/SPONSOR
2. **Verifica funzionamento**: Testa che Caritas possa utilizzare il contratto
3. **Revoca graduale**: Solo dopo conferma, revoca i propri ruoli

### Backup Plan
- Se qualcosa va storto, con i ruoli ADMIN mantenuti puoi sempre:
  - Revocare i ruoli a Caritas
  - Assegnare ruoli a un nuovo indirizzo
  - Correggere errori di configurazione

## 🔧 Funzionalità del SolidarySponsorVault

### Funzioni Disponibili per Caritas:
```solidity
// Logging delle sponsorizzazioni
function mintSponsorToken(address to, string memory sponsorshipNote) external onlyRole(SPONSOR_ROLE)

// Gestione ruoli (solo ADMIN)
function grantRole(bytes32 role, address account) external onlyRole(getRoleAdmin(role))
function revokeRole(bytes32 role, address account) external onlyRole(getRoleAdmin(role))
```

## 💡 Opzione Aggiuntiva: CaritasDonationManager

Se Caritas desidera raccogliere donazioni in MATIC, è possibile deployare il contratto `CaritasDonationManager` che:

1. **Raccoglie donazioni** in MATIC
2. **Trasferisce automaticamente** i fondi al wallet di Caritas
3. **Registra la sponsorizzazione** nel SolidarySponsorVault
4. **Mantiene statistiche** complete delle donazioni

### Deploy del DonationManager:
```bash
# Dopo aver ottenuto l'indirizzo di Caritas
npx hardhat run scripts/deploy-caritas-donation-manager.js --network polygon
```

## 📊 Monitoraggio e Statistiche

### Verifica Transazioni:
- Tutte le operazioni sono tracciate on-chain
- Hash delle transazioni vengono loggati negli script
- Eventi emessi per ogni cambio di ruolo

### PolygonScan:
- Visualizza le transazioni su: https://polygonscan.com/address/0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3
- Monitora gli eventi del contratto
- Verifica i chiamanti delle funzioni

## 🎉 Completamento

Una volta trasferito il controllo:
1. ✅ Caritas avrà pieno controllo del SponsorVault
2. ✅ Potrà gestire le sponsorizzazioni e i ruoli
3. ✅ Avrà tracciabilità completa delle operazioni
4. ✅ Possibilità di raccogliere donazioni (con DonationManager opzionale)

## 📞 Contatti e Supporto

Per qualsiasi questione tecnica o legale riguardante il trasferimento:
- **Sviluppatore**: Marcello Stanca
- **Località**: Florence, Italy
- **Contratti**: Tutti sotto licenza MIT

---

**© Copyright Marcello Stanca Lawyer - ITALY Florence**