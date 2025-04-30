// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {IActionsBuilder} from 'interfaces/actions/IActionsBuilder.sol';

interface ICappedTokenTransfers is ISafeManageable, IActionsBuilder {
  struct TokenTransfer {
    address token;
    address recipient;
    uint256 amount;
  }

  function tokenCap(address _token) external view returns (uint256 _transferCap);
  function capSpent(address _token) external view returns (uint256 _transferCapSpent);
  function lastEpochTimestamp(address _token) external view returns (uint256 _lastEpochTimestamp);
  function tokenEpochLength(address _token) external view returns (uint256 _epochLength);
  function stateUpdated() external view returns (bool);

  function tokenTransfers(uint256 _index) external view returns (address _token, address _recipient, uint256 _amount);

  // ~~~ ERRORS ~~~

  error LengthMismatch();
  error ExceededCap();
  error UnallowedToken();
  error StateNotUpdated();
  error StateAlreadyUpdated();

  // ~~~ ADMIN METHODS ~~~

  function addCappedToken(address _token, uint256 _cap, uint256 _epochLength) external;

  function addTokenTransfers(
    address[] memory _tokens,
    address[] memory _recipients,
    uint256[] memory _amounts
  ) external;

  // ~~~ STATE MANAGEMENT ~~~

  function updateState(address[] memory _tokens, uint256[] memory _spentAmounts) external;

  function getActions() external view returns (Action[] memory);
}
