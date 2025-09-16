// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IAllowanceClaimorFactory
 * @notice Interface for the AllowanceClaimorFactory contract
 */
interface IAllowanceClaimorFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates an AllowanceClaimor contract
   * @param _safe The Gnosis Safe contract address
   * @param _token The token contract address
   * @param _tokenOwner The token owner address
   * @param _tokenRecipient The token recipient address
   * @return _allowanceClaimor The AllowanceClaimor contract address
   */
  function createAllowanceClaimor(
    address _safe,
    address _token,
    address _tokenOwner,
    address _tokenRecipient
  ) external returns (address _allowanceClaimor);
}
