# ChainSeal

**Blockchain-based software supply chain attestation.**

ChainSeal lets a software publisher register the SHA-256 fingerprint of each release on a blockchain. Anyone can then drop a downloaded file into the dashboard and instantly see whether it matches an official, unrevoked release. Only hashes go on-chain; your files never leave your machine.

---

## Table of contents

- [Why ChainSeal](#why-chainseal)
- [Features](#features)
- [How it works](#how-it-works)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Using the dashboard](#using-the-dashboard)
- [Checking that everything works](#checking-that-everything-works)
- [Smart contract overview](#smart-contract-overview)
- [Security model](#security-model)
- [Project structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Why ChainSeal

Software updates are trusted almost blindly. Attacks such as SolarWinds, malicious npm/PyPI packages and trojanised installers all exploit the same gap: users have no independent way to confirm that a file is exactly what the publisher released.

Hashing a file is easy. The hard part is **who holds the list of good hashes**. In a normal database, an attacker or rogue admin can change a file and its recorded hash together, and the check still passes. On a blockchain, records are append-only, the rules are enforced by the network, and anyone can verify independently.

## Features

- **Register releases**: publishers store a release's SHA-256 hash, package name and version on-chain.
- **Instant verification**: drop any file into the dashboard and get a clear verdict (verified, unknown, or revoked) with publisher, version and timestamp.
- **Package ownership**: the first publisher to use a package name owns it; nobody else can add versions to it.
- **Revocation**: publishers can pull a compromised release, with a permanent, public reason.
- **Privacy-preserving**: files are hashed locally in the browser. Nothing is uploaded.
- **Tamper-evident history**: events and timestamps are immutable.
- **No backend server**: the dashboard talks straight to the blockchain over JSON-RPC.

## How it works

1. A publisher builds a release and computes its SHA-256 hash.
2. The publisher calls `register` on the `PackageRegistry` contract with the package name, version and hash.
3. A user downloads the file and drops it into the ChainSeal dashboard.
4. The browser computes the file's SHA-256 hash and queries the contract.
5. The dashboard shows one of three results:

| Result | Meaning |
|---|---|
| **VERIFIED** (green) | The hash matches a published, unrevoked release. |
| **NOT FOUND / TAMPERED** (red) | The hash matches no published release. Any changed byte produces a different hash. |
| **REVOKED** (amber) | The release was published but later pulled by its publisher, with a reason. |

## Architecture

```
┌──────────────────────────────┐   JSON-RPC   ┌──────────────────────────────┐
│  Browser dashboard           │ ───────────► │  Hardhat local chain         │
│  HTML + JS + ethers.js       │ ◄─────────── │  PackageRegistry.sol         │
│  SHA-256 computed in-browser │              │                              │
└──────────────────────────────┘              └──────────────────────────────┘
```

| Component | Technology |
|---|---|
| Smart contract | Solidity |
| Development chain and tests | Hardhat |
| Web3 client | ethers.js |
| Dashboard | Plain HTML/CSS/JS, served locally |
| Hashing | Web Crypto API (SHA-256) |

## Getting started

### Prerequisites

- [Node.js](https://nodejs.org) 18 or newer
- A modern browser (Chrome, Edge, Firefox)
- An internet connection the first time you open the dashboard (front-end libraries load from a CDN)

### Install

```bash
git clone https://github.com/nemal2/chainseal.git
cd chainseal
npm install
```

### Run the tests

```bash
npm test
```

All 4 tests should pass.

### Start ChainSeal

You need three terminals, all opened in the project folder.

**Terminal 1: start the local blockchain** (keep it running)

```bash
npm run node
```

This starts a Hardhat node and prints 20 funded test accounts.

**Terminal 2: deploy the contract**

```bash
npm run deploy
```

This deploys `PackageRegistry` and writes the contract address to `dashboard/config.js`.

**Terminal 3: serve the dashboard**

```bash
npm run dash
```

Then open **http://localhost:8000** in your browser. The header should show a green dot and the current block number.

> If you restart the node, run `npm run deploy` again and refresh the page. A fresh chain starts empty, so previous registrations are gone.

## Using the dashboard

**Publish a release**

1. Select an account under *Act as* (each test account acts as a different identity).
2. Choose the file, enter the package name and version, and click publish.
3. The file is hashed in your browser and only the hash is written on-chain.

**Verify a file**

1. Drop the downloaded file onto the verify area.
2. The dashboard shows the verdict along with publisher, version and date.

**Revoke a release**

1. Switch to the account that published it.
2. Choose the release, enter a reason and revoke. The reason is stored permanently.

## Checking that everything works

Run through this short checklist to confirm your setup is healthy.

**1. Tests pass**

```bash
npm test
```

**2. Dashboard is connected**

The header shows a green dot and a block number that increases as you send transactions.

**3. Create sample files**

```bash
echo "MyApp release 1.0" > myapp_v1.txt
cp myapp_v1.txt myapp_tampered.txt
echo "extra line" >> myapp_tampered.txt
echo "MyApp release 2.0" > myapp_v2.txt
```

(On Windows PowerShell, use `Set-Content` and `Add-Content` in place of `echo` and `>>`, or create the files in any text editor.)

**4. Expected behaviour**

| Step | Expected result |
|---|---|
| Publish `myapp_v1.txt` as `MyApp` `1.0` from account A | Transaction succeeds |
| Verify `myapp_v1.txt` | Green **VERIFIED**, shows publisher and version |
| Verify `myapp_tampered.txt` | Red result, since the hash is unknown |
| Publish `myapp_v2.txt` as `MyApp` `2.0` from account B | Rejected with `Not the package owner` |
| Revoke `MyApp 1.0` from account A with a reason | Transaction succeeds |
| Verify `myapp_v1.txt` again | Amber **REVOKED**, shows the reason |

If all six behave as described, the contract, the dashboard and the ownership and revocation rules are working correctly.

## Smart contract overview

`PackageRegistry.sol` exposes three core operations:

| Function | Who can call | What it does |
|---|---|---|
| `register` | Anyone (first caller for a package name becomes its owner) | Records a release hash, package name, version and timestamp. Reverts with `Not the package owner` if the package belongs to someone else. |
| `revoke` | Only the original publisher of the release | Marks the release as revoked and stores the reason permanently. |
| `verify` | Anyone (read-only, free) | Returns whether a hash is registered, and its publisher, version, timestamp and revocation status. |

Every state change emits an event, giving an auditable on-chain history.

## Security model

| Threat | Defence |
|---|---|
| Tampered installer | Any changed byte changes the hash, so verification fails. |
| Attacker publishes a fake version of a known package | The first publisher owns the package name; others are rejected. |
| Release later found to be compromised | The publisher revokes it with a permanent reason. |
| Publisher or admin rewrites history | The blockchain is append-only; events and timestamps are immutable. |
| Attacker revokes someone else's release | Only the original publisher can revoke. |

### Limitations

- ChainSeal proves a file is **the one that was published**, not that it is **safe**. A publisher can still register malicious software.
- A stolen publisher key is still a risk, since there is currently no key rotation or multi-signature control.
- The default setup uses a local Hardhat chain for development. A public network is required for real decentralisation.
- The Hardhat test accounts and their private keys are publicly known. **Never use them on a real network.**

## Project structure

```
chainseal/
├── contracts/        # Solidity smart contract (PackageRegistry.sol)
├── test/             # Hardhat tests
├── scripts/          # Deployment script (writes dashboard/config.js)
├── dashboard/        # Browser front end (HTML + ethers.js)
├── hardhat.config.js
└── package.json
```

## Troubleshooting

| Problem | Fix |
|---|---|
| Red dot, "node offline" | Start the chain with `npm run node`. |
| `Cannot read CONFIG` | Run `npm run deploy` after the node is running, then refresh. |
| Verdicts wrong after restarting the node | The chain was reset. Run `npm run deploy` again and re-register your releases. |
| Hashing fails | Open the dashboard through `http://localhost:8000`, not by double-clicking the HTML file. The browser's hashing API needs a secure context. |
| Page looks unstyled or ethers.js missing | The front end loads scripts and fonts from a CDN; connect to the internet once. |
| `npm run dash` fails on Windows | Use `npx http-server dashboard -p 8000 -c-1` instead. |

## Roadmap

- [ ] Multi-signature publishers
- [ ] Publisher key rotation
- [ ] Command-line verifier for CI/CD pipelines
- [ ] Deployment to the Sepolia public testnet
- [ ] Support for signed release manifests and multiple artefacts per version

## Contributing

Contributions are welcome.

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/my-change`
3. Make your changes and run `npm test`.
4. Commit and push, then open a pull request.

## License

Released under the [MIT License](LICENSE). Add a `LICENSE` file to the repository root (GitHub can generate one for you via *Add file → Create new file → LICENSE*).