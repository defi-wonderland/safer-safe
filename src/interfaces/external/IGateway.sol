// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IGateway
 * @notice Interface for the Gateway contract
 */
interface IGateway {
  /**
   * @notice Quote the message fee
   * @param _chainId The chain id
   * @param _message The message to quote
   * @param _gasLimit The gas limit
   * @return _fee The fee
   */
  function quoteMessage(
    uint32 _chainId,
    bytes calldata _message,
    uint256 _gasLimit
  ) external view returns (uint256 _fee);
}
