# ChainSeal: Blockchain Software Supply Chain Attestation

EC8204 Blockchain and Cyber Security, University of Ruhuna.
Submission name: `GP_XX_ChainSeal_Supply_Chain_Attestation.ppt` (replace XX with your group number). Confirm the deadline date with the coordinator, because "31/09" does not exist.

## 1. The idea
Attackers poison the software supply chain (SolarWinds, malicious npm/PyPI packages, trojanised installers). ChainSeal lets a publisher register the SHA-256 fingerprint of each release on a blockchain. Anyone can drop a downloaded file into the dashboard and see whether it matches a published release. Only hashes go on-chain; files never leave the user's machine.

| Threat | Defence in ChainSeal |
|---|---|
| Tampered installer | Any changed byte changes the hash, so verification fails (red stamp) |
| Attacker publishes a fake version of a known package | First publisher owns the package name; others are rejected (`Not the package owner`) |
| Release found to be compromised | Publisher revokes it with a permanent reason |
| Publisher or admin rewrites history | Blockchain is append-only; events and timestamps are immutable |
| Attacker revokes someone else's release | Only the original publisher can revoke |

Limits (say these in your presentation): it proves a file is the one that was published, not that it is safe, and a stolen publisher key is still a risk. Future work: multi-signature publishers, key rotation, a CLI verifier for CI pipelines, Sepolia testnet deployment.

## 2. Architecture
```
Browser dashboard (HTML + ethers.js)  <--JSON-RPC-->  Hardhat local chain
   SHA-256 computed in browser                           PackageRegistry.sol
```

## 3. Setup (once)
1. Install Node.js 18+ (nodejs.org) and Python 3.
2. Unzip the project, open a terminal in the `chainseal` folder.
3. `npm install`
4. `npm test` and confirm 4 tests pass.

## 4. Run (3 terminals, in the project folder)
1. Terminal 1: `npm run node` (keep it running; it prints 20 test accounts).
2. Terminal 2: `npm run deploy` (deploys the contract and writes `dashboard/config.js`), then `npm run dash`.
3. Open http://localhost:8000 in your browser. The header should show a green dot and the block number.

If you restart the node, run `npm run deploy` again and refresh the page.

## 5. Make demo files
```
echo "MyApp release 1.0" > demo/myapp_v1.txt
cp demo/myapp_v1.txt demo/myapp_tampered.txt
echo "malicious payload" >> demo/myapp_tampered.txt
echo "MyApp release 2.0" > demo/myapp_v2.txt
```

## 6. Demo script (3 minutes)
| Time | Action | Say |
|---|---|---|
| 0:00 | Slide: problem | "Software updates are trusted blindly. SolarWinds hit 18,000 organisations this way." |
| 0:30 | Publish `myapp_v1.txt` as MyApp 1.0 (Act as Publisher) | "The publisher registers only the fingerprint on-chain." |
| 1:00 | Verify `myapp_v1.txt`: green VERIFIED stamp | "The user checks their download and gets publisher, version and date." |
| 1:20 | Verify `myapp_tampered.txt`: red stamp | "One extra line changes the hash, so the fake is caught." |
| 1:40 | Switch to Attacker, publish `myapp_v2.txt` as MyApp 2.0: red toast | "An attacker cannot hijack an existing package name." |
| 2:05 | Switch to Publisher, revoke v1.0, then re-verify: amber REVOKED | "A compromised release is pulled with a permanent reason." |
| 2:30 | Slide: threat model, limits, future work | "Immutable, transparent, no trusted central server." |

## 7. Slide outline (6 slides)
1. Title and team. 2. Problem (supply chain attacks). 3. Solution and architecture diagram. 4. Smart contract: register, revoke, verify, ownership rule. 5. Live demo (or recorded backup). 6. Threat model table, limitations, future work.
Record a screen capture of the demo as a backup.

## 8. Troubleshooting
- Red dot, "node offline": start `npm run node`.
- "Cannot read CONFIG": run `npm run deploy` after starting the node.
- Verdict wrong after restart: node restarted, so redeploy and re-register.
- Hash step fails: open via http://localhost:8000, not by double-clicking the file (the browser hashing API needs localhost).
- Fonts or ethers.js missing: the page needs internet once for the CDN scripts.
