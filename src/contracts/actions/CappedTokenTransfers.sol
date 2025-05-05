// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SafeManageable} from 'contracts/SafeManageable.sol';

import {ICappedTokenTransfers} from 'interfaces/actions/ICappedTokenTransfers.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract CappedTokenTransfers is SafeManageable, ICappedTokenTransfers {
  // Token configuration
  address public immutable TOKEN;
  uint256 public immutable CAP;
  uint256 public immutable EPOCH_LENGTH;

  // State tracking
  uint256 public totalSpent;
  uint256 public startingTimestamp;

  TokenTransfer[] public tokenTransfers;

  constructor(address _safe, address _token, uint256 _cap, uint256 _epochLength) SafeManageable(_safe) {
    TOKEN = _token;
    CAP = _cap;
    EPOCH_LENGTH = _epochLength;
    startingTimestamp = block.timestamp;
  }

  // ~~~ ADMIN METHODS ~~~

  function addTokenTransfer(address _recipient, uint256 _amount) external isSafeOwner {
    if (_amount == 0) revert InvalidAmount();
    tokenTransfers.push(TokenTransfer({recipient: _recipient, amount: _amount}));
  }

  function removeTokenTransfer(uint256 _index) external isSafeOwner {
    if (_index >= tokenTransfers.length) revert InvalidIndex();

    delete tokenTransfers[_index];
  }

  // ~~~ ACTIONS METHODS ~~~

  function getActions() external view returns (Action[] memory) {
    // Count valid transfers
    uint256 _validCount = 0;
    uint256 _totalAmount = 0;
    for (uint256 i = 0; i < tokenTransfers.length; i++) {
      if (tokenTransfers[i].amount != 0) {
        _validCount++;
        _totalAmount += tokenTransfers[i].amount;
      }
    }

    // Create actions array: one for updateState + one for each valid transfer
    uint256 _numActions = _validCount + 1;
    Action[] memory _actions = new Action[](_numActions);

    // First action: update state
    _actions[0] = Action({
      target: address(this),
      data: abi.encodeWithSelector(ICappedTokenTransfers.updateState.selector, abi.encode(_totalAmount)),
      value: 0
    });

    // Remaining actions: valid token transfers
    uint256 _actionIndex = 1;
    for (uint256 i = 0; i < tokenTransfers.length; i++) {
      if (tokenTransfers[i].amount != 0) {
        _actions[_actionIndex] = Action({
          target: TOKEN,
          data: abi.encodeWithSelector(IERC20.transfer.selector, tokenTransfers[i].recipient, tokenTransfers[i].amount),
          value: 0
        });
        _actionIndex++;
      }
    }

    return _actions;
  }

  function updateState(bytes memory _data) external isSafe {
    uint256 _timeElapsed = block.timestamp - startingTimestamp;
    // we always want to round up any fraction
    uint256 _totalAllowed = (_timeElapsed * CAP + EPOCH_LENGTH - 1) / EPOCH_LENGTH;

    uint256 _amount = abi.decode(_data, (uint256));
    uint256 _totalSpent = totalSpent + _amount;

    if (_totalSpent > _totalAllowed) {
      revert CapExceeded();
    }

    totalSpent = _totalSpent;

    // Clean up
    delete tokenTransfers;
  }
}
