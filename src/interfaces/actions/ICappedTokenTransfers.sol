// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {IActionsBuilder} from 'interfaces/actions/IActionsBuilder.sol';

interface ICappedTokenTransfers is ISafeManageable, IActionsBuilder {
  struct TokenTransfer {
    address recipient;
    uint256 amount;
  }

  function tokenCap() external view returns (uint256);
  function capSpent() external view returns (uint256);
  function lastEpochTimestamp() external view returns (uint256);
  function tokenEpochLength() external view returns (uint256);
  function stateUpdated() external view returns (bool);
  function token() external view returns (address);

  function tokenTransfers(uint256 _index) external view returns (address _recipient, uint256 _amount);

  // ~~~ ERRORS ~~~

  error LengthMismatch();
  error ExceededCap();
  error UnallowedToken();
  error StateNotUpdated();
  error StateAlreadyUpdated();

  // ~~~ ADMIN METHODS ~~~

  function addTokenTransfers(address[] memory _recipients, uint256[] memory _amounts) external;

  // ~~~ STATE MANAGEMENT ~~~

  function updateState(bytes memory _data) external;

  function getActions() external view returns (Action[] memory);
}
