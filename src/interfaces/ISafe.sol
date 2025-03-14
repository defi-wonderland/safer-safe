// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

interface ISafe {
  function execTransaction(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address payable refundReceiver,
    bytes memory signatures
  ) external payable returns (bool success);

  function getTransactionHash(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address refundReceiver,
    uint256 _nonce
  ) external view returns (bytes32 txHash);

  function nonce() external view returns (uint256);

  function getOwners() external view returns (address[] memory);

  function isOwner(address owner) external view returns (bool);

  function approvedHashes(address _owner, bytes32 _hash) external view returns (bool);
}
