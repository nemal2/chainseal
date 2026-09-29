const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const reg = await hre.ethers.deployContract("PackageRegistry");
  await reg.waitForDeployment();
  const address = await reg.getAddress();
  const { abi } = await hre.artifacts.readArtifact("PackageRegistry");
  // The dashboard reads the contract address + ABI from this file.
  fs.writeFileSync(
    path.join(__dirname, "..", "dashboard", "config.js"),
    "window.CONFIG = " + JSON.stringify({ address, abi }) + ";"
  );
  console.log("PackageRegistry deployed to", address);
}
main().catch((e) => { console.error(e); process.exit(1); });
