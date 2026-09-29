const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PackageRegistry", () => {
  let reg, pub, evil;
  const H = ethers.id("app-v1"), H2 = ethers.id("app-v2");
  beforeEach(async () => {
    [pub, evil] = await ethers.getSigners();
    reg = await ethers.deployContract("PackageRegistry");
  });
  it("registers and verifies a release", async () => {
    await reg.register("MyApp", "1.0", H);
    const r = await reg.verify(H);
    expect(r[0]).to.equal(1n);
    expect(r[1]).to.equal(pub.address);
  });
  it("reports unknown hashes as Unknown", async () => {
    expect((await reg.verify(H))[0]).to.equal(0n);
  });
  it("blocks an attacker from publishing under someone else's package", async () => {
    await reg.register("MyApp", "1.0", H);
    await expect(reg.connect(evil).register("MyApp", "2.0", H2)).to.be.revertedWith("Not the package owner");
  });
  it("lets only the publisher revoke, and stores the reason", async () => {
    await reg.register("MyApp", "1.0", H);
    await expect(reg.connect(evil).revoke(H, "x")).to.be.revertedWith("Not the publisher");
    await reg.revoke(H, "Signing key leaked");
    const r = await reg.verify(H);
    expect(r[0]).to.equal(2n);
    expect(r[5]).to.equal("Signing key leaked");
  });
});
