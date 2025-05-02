// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {IActionsBuilder} from 'interfaces/actions/IActionsBuilder.sol';

interface ICappedTokenTransfers is ISafeManageable, IActionsBuilder {
  struct TokenTransfer {
    address recipient;
    uint256 amount;
  }

  function TOKEN() external view returns (address);
  function CAP() external view returns (uint256);
  function EPOCH_LENGTH() external view returns (uint256);

  function totalSpent() external view returns (uint256);
  function startingTimestamp() external view returns (uint256);

  function tokenTransfers(uint256 _index) external view returns (address _recipient, uint256 _amount);

  // ~~~ ERRORS ~~~

  error CapExceeded();
  error InvalidIndex();

  // ~~~ ADMIN METHODS ~~~

  function addTokenTransfer(address _recipient, uint256 _amount) external;
  function removeTokenTransfer(uint256 _index) external;
  // ~~~ STATE MANAGEMENT ~~~

  function updateState(bytes memory _data) external;

  function getActions() external view returns (Action[] memory);
}
