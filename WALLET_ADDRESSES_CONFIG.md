# 🏦 WALLET ADDRESSES CONFIGURATION

## 📍 **UPDATED WALLET CONFIGURATION (November 1, 2025)**

### 🎯 **DEPLOY SCRIPT ADDRESSES**

#### 🔧 **Administrative Roles**
- **DEPLOYER/OWNER**: `0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8`
  - Has complete administrative control
  - Can modify contract configurations
  - Can execute withdraw functions
  - Retains DEFAULT_ADMIN_ROLE on NFT/FT contracts

#### 💰 **Fee Distribution Addresses**

1. **CREATOR WALLET**: `0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8`
   - Receives **2.5%** of all mint payments
   - Developer/Creator address
   - Same as deployer address

2. **CHARITY WALLET**: `0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A`
   - Receives **2.5%** of all mint payments  
   - **Caritas International** official wallet
   - **Coinbase Alias**: `caritasinternational.cb.id`

### 🎭 **CONTRACT ROLES & PERMISSIONS**

#### 🎨 **NFT Contract (OceanMangaNFT)**
- **DEFAULT_ADMIN_ROLE**: `0x8495...d3b8` (deployer)
- **MINTER_ROLE**: Orchestrator contract (auto-granted)

#### 🪙 **FT Contract (LunaComicsFT)**  
- **DEFAULT_ADMIN_ROLE**: `0x8495...d3b8` (deployer)
- **MINTER_ROLE**: Orchestrator contract (auto-granted)

#### 🎯 **Orchestrator Contract**
- **Owner**: `0x8495...d3b8` (deployer)
- **Creator**: `0x8495...d3b8` (deployer) 
- **CharityFund**: `0xf84e...Ab2A` (Caritas International)

### 💎 **PAYMENT FLOW**

When a user mints an NFT for **1 ETH**:

1. **45%** (0.45 ETH) → FT Contract minting
2. **55%** (0.55 ETH) → Distributed as follows:
   - **2.5%** (0.025 ETH) → Creator: `0x8495...d3b8`
   - **2.5%** (0.025 ETH) → Caritas: `0xf84e...Ab2A`
   - **50%** (0.50 ETH) → Remains in orchestrator

### 🔐 **SECURITY SUMMARY**

✅ **Deployer Control**:
- Full administrative access to all contracts
- Can modify orchestrator settings
- Can withdraw remaining funds
- Receives creator fees

✅ **Caritas Integration**:
- Direct donation to official Caritas wallet
- Transparent charity fee distribution
- Automatic 2.5% allocation per mint

✅ **Minting Permissions**:
- Only orchestrator can mint NFTs/FTs
- Orchestrator has required MINTER_ROLE on both contracts
- No unauthorized minting possible

### 🚀 **READY FOR DEPLOYMENT**

The configuration ensures:
- **Ethical fee distribution** (Creator 2.5% + Caritas 2.5%)
- **Complete administrative control** for deployer
- **Transparent charity donations** to Caritas International
- **Secure role-based permissions** on all contracts

---
*Configuration verified: November 1, 2025*
*Charity Wallet: Caritas International (caritasinternational.cb.id)*