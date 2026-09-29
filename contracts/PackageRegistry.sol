// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// ChainSeal: an on-chain registry of software release fingerprints (SHA-256).
/// Only hashes are stored, never the files themselves.
contract PackageRegistry {
    enum Status { Unknown, Valid, Revoked }

    struct Release {
        address publisher;
        string name;
        string version;
        uint64 timestamp;
        Status status;
        string reason;
    }

    mapping(bytes32 => Release) private releases;     // file hash => release
    mapping(bytes32 => address) public packageOwner;  // keccak(name) => first publisher

    event Registered(bytes32 indexed fileHash, address indexed publisher, string name, string version);
    event Revoked(bytes32 indexed fileHash, address indexed publisher, string reason);

    /// First publisher to use a package name owns it; only they can add versions.
    function register(string calldata name, string calldata version, bytes32 fileHash) external {
        require(bytes(name).length > 0 && bytes(version).length > 0, "Name and version required");
        require(releases[fileHash].status == Status.Unknown, "Hash already registered");

        bytes32 key = keccak256(bytes(name));
        address owner = packageOwner[key];
        if (owner == address(0)) {
            packageOwner[key] = msg.sender;
        } else {
            require(owner == msg.sender, "Not the package owner");
        }

        releases[fileHash] = Release(msg.sender, name, version, uint64(block.timestamp), Status.Valid, "");
        emit Registered(fileHash, msg.sender, name, version);
    }

    /// Pull a compromised release. The reason is stored permanently.
    function revoke(bytes32 fileHash, string calldata reason) external {
        Release storage r = releases[fileHash];
        require(r.status == Status.Valid, "Not an active release");
        require(r.publisher == msg.sender, "Not the publisher");
        r.status = Status.Revoked;
        r.reason = reason;
        emit Revoked(fileHash, msg.sender, reason);
    }

    function verify(bytes32 fileHash)
        external view
        returns (Status, address, string memory, string memory, uint64, string memory)
    {
        Release storage r = releases[fileHash];
        return (r.status, r.publisher, r.name, r.version, r.timestamp, r.reason);
    }
}
