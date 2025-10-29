// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IAllowanceClaimorFactory
 * @notice Interface for the AllowanceClaimorFactory contract
 */
interface IAllowanceClaimorFactory {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a new AllowanceClaimor contract is created
   * @param _allowanceClaimor The address of the created AllowanceClaimor contract
   * @param _token The token contract address
   * @param _tokenOwner The token owner address
   * @param _tokenRecipient The token recipient address
   */
  event AllowanceClaimorCreated(
    address indexed _allowanceClaimor, address indexed _token, address indexed _tokenOwner, address _tokenRecipient
  );

  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates an AllowanceClaimor contract
   * @param _token The token contract address
   * @param _tokenOwner The token owner address
   * @param _tokenRecipient The token recipient address
   * @return _allowanceClaimor The AllowanceClaimor contract address
   */
  function createAllowanceClaimor(
    address _token,
    address _tokenOwner,
    address _tokenRecipient
  ) external returns (address _allowanceClaimor);
}
