# Solidity Compiler Code Size Reporting Issue

**Author:** Marcello Stanca (avvocato)
**Date:** 2025-10-29

## Issue Summary

When compiling modular contracts with Solidity (version 0.8.29), the compiler issues a warning about contract code size exceeding the Spurious Dragon limit (24,576 bytes), even after logic has been externalized into libraries or separate contracts. The warning persists:

```
Warning: Contract code size is 29438 bytes and exceeds 24576 bytes (a limit introduced in Spurious Dragon). This contract may not be deployable on Mainnet. Consider enabling the optimizer (with a low "runs" value!), turning off revert strings, or using libraries.
```

## Context

- **Project:** SolidarySystemHub (modular orchestrator contract)
- **Refactoring:** Most calculation and orchestration logic was moved to external libraries (`SolidaryHealthUtils`, `SolidaryModuleOrchestrationUtils`) and separate contracts.
- **Expectation:** The main contract bytecode size should decrease, as heavy logic is now external.
- **Observation:** The compiler warning reports the same code size as before refactoring, even though the orchestrator contract is now lighter.

## Analysis

- Solidity's code size warning appears to include the bytecode of linked libraries and externalized modules, not just the main contract.
- This can mislead developers into thinking their contract is still too large for mainnet deploy, even after proper modularization.
- The actual deployable bytecode for the orchestrator contract is reduced, but the warning does not reflect this.

## Steps to Reproduce

1. Create a contract with heavy logic and compile (observe code size warning).
2. Move logic to libraries and/or external contracts.
3. Compile again: warning persists with same code size reported.

## Expected Behavior

- The compiler should report the code size of the deployable contract only, excluding external libraries and contracts.
- Warnings should update after modularization, reflecting the true deployable size.

## Actual Behavior

- Warning persists with the same code size, even after logic is moved out.
- Developers may be misled about deployability and optimization.

## Recommendation

- Update the compiler to report only the deployable contract's bytecode size.
- Optionally, provide a breakdown: contract size, linked library size, total size.
- Clarify documentation and warning messages to avoid confusion.

## Example

- `SolidarySystemHub.sol` orchestrator contract, after refactoring:
  - Actual contract file size: ~21 KB
  - Reported code size: ~29 KB (unchanged)
  - Libraries: `SolidaryHealthUtils.sol`, `SolidaryModuleOrchestrationUtils.sol`

## Contact

Marcello Stanca, Florence, Italy
GitHub: avvstancamarcello

---
*This issue was prepared by GitHub Copilot on behalf of Marcello Stanca.*
