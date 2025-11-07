Incident report: Naming and deployment issues
===============================================

Date: 2025-11-01
Repository: LHISA3-ignition
Branch: copilot/vscode1761715614524
Author: automated assistant (created per user request)

Summary of incident
-------------------
- Several deployment attempts were executed during the session to fix a critical security issue (DEFAULT_ADMIN_ROLE usage). Most functional and security goals were met: custom roles only, zero DEFAULT_ADMIN_ROLE, impact tracker and FT deployed.
- During the finalization, the NFT contract was deployed with a non-ideal token symbol `OMNFTS` which the user correctly flagged as meaningless for branding.
- Attempts to correct the naming triggered additional redeploys and manual changes. There were repeated failures related to gas estimation, incorrect initialization signatures for some deploy paths, and an initial deployment that produced an implementation contract that was not initialized via proxy.

Direct consequences (user-reported)
-----------------------------------
- Financial: user spent ETH in multiple deployment attempts. User estimates > €100 in combined costs (user-reported). The assistant recognizes the financial harm and user frustration.
- Trust: repeated mistakes caused loss of confidence in the assistant's handling of live deployments.

Root causes observed
--------------------
1. Inconsistent deployment patterns: both upgradeable (UUPS) and non-upgradeable flows were attempted. One deployed contract was an implementation (not proxy) leaving it uninitialized.
2. Script/contract mismatches: some scripts called `initialize` with a different parameter signature than the actual solidity contract's initialize function (mismatch in param order/number).
3. Insufficient pre-deploy checks: no single pre-deploy checklist enforced to verify gas estimate, initialize signature presence, and balance before spending funds.
4. Branding oversight: token symbol chosen automatically without explicit user confirmation.

Immediate actions taken (by the assistant during session)
--------------------------------------------------------
- Verified account balances multiple times and communicated exact ETH values to user.
- Created verification scripts (`scripts/verify-deployed-nft.js`, `scripts/verify-simple-nft.js`) and attempted to attach and inspect deployed contracts.
- Implemented a simple non-upgradeable contract `OceanMangaNFT_Simple.sol` and used it as a safe fallback to finalize the ecosystem with minimal gas.
- Added scripts to deploy an optimized version and an incident report file (this file).
- Updated the workspace TODO list to track remediation tasks.

Planned remediations (next steps)
--------------------------------
- Implement a strict pre-deploy checklist that MUST pass before any script will perform an on-chain action (balance check, gas-estimate vs balance, initialization ABI verification, role-hash non-zero checks).
- Add and run unit/integration tests that verify: `initialize` signature, role assignments, `verifyNoDefaultAdminRole`, and name/symbol values.
- Require explicit human confirmation (user typed GO) before any deployment that will spend ETH.
- Provide a dry-run mode that prints the estimated tx cost and waits for user approval.
- Centralize all deploy scripts behind a validated runner that invokes the checklist and tests.

Commitment and limitations
--------------------------
- Commitment: I will implement the full checklist, tests, and the explicit approval gate before any further deployment, and I will not run any on-chain deployment without your explicit GO after showing the estimated gas/cost.
- Limitation: I cannot "swear" or absolutely guarantee zero future errors — software and networks have failure modes beyond my control (e.g., network congestion, provider differences, subtle contract semantics), but I can and will minimize the risk substantially by adding automated checks, tests, and manual approval steps.

Requested user options
----------------------
1. I will proceed to implement the pre-deploy checklist + tests and share results; then we will schedule a redeploy with symbol `COMICS` only after you confirm.
2. If you prefer no redeploy at all, we retain the current secure contract (`0xA139...`) and accept the symbol mismatch; no further ETH will be spent.

If you select option 1, please confirm and I will:
- implement the checklist and tests (local CI run),
- run checks and present the gas estimate and final balance, and
- ask for your explicit GO to proceed with actual redeploy.

Audit trail
-----------
Files created during session:
- scripts/verify-deployed-nft.js
- scripts/initialize-manual.js
- scripts/deploy-final-secure-proxy.js
- contracts/nft/OceanMangaNFT_Simple.sol
- scripts/deploy-simple-secure.js
- scripts/deploy-comics-optimized.js
- reports/incident_report_naming_and_deployment_errors.md (this file)

Status: report saved to repository for review.

End of report.
