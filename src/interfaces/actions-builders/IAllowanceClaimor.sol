// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

/**
 * @title IAllowanceClaimor
 * @notice Interface for the AllowanceClaimor contract
 */
interface IAllowanceClaimor is IActionsBuilder {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the token contract
   * @return _token The token contract address
   */
  function TOKEN() external view returns (IERC20 _token);

  /**
   * @notice Gets the token owner
   * @return _tokenOwner The token owner address
   */
  function TOKEN_OWNER() external view returns (address _tokenOwner);

  /**
   * @notice Gets the token recipient
   * @return _tokenRecipient The token recipient address
   */
  function TOKEN_RECIPIENT() external view returns (address _tokenRecipient);
}
