// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SafeManageable} from 'contracts/SafeManageable.sol';

import {ICappedTokenTransfers} from 'interfaces/actions/ICappedTokenTransfers.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract CappedTokenTransfers is SafeManageable, ICappedTokenTransfers {
  // Token configuration
  address public immutable token;
  uint256 public immutable tokenCap;
  uint256 public immutable tokenEpochLength;

  // State tracking
  uint256 public capSpent;
  uint256 public lastEpochTimestamp;
  bool public stateUpdated;
  TokenTransfer[] public tokenTransfers;

  constructor(address _safe, address _token, uint256 _cap, uint256 _epochLength) SafeManageable(_safe) {
    token = _token;
    tokenCap = _cap;
    tokenEpochLength = _epochLength;
    lastEpochTimestamp = block.timestamp;
    stateUpdated = true;
  }

  // ~~~ ADMIN METHODS ~~~

  function addTokenTransfers(address[] memory _recipients, uint256[] memory _amounts) external isSafeOwner {
    if (_recipients.length != _amounts.length) {
      revert LengthMismatch();
    }

    for (uint256 i = 0; i < _recipients.length; i++) {
      _addTokenTransfer(_recipients[i], _amounts[i]);
    }

    // Mark state as needing update
    stateUpdated = false;
  }

  // ~~~ ACTIONS METHODS ~~~

  function getActions() external view returns (Action[] memory) {
    // Get total amount to be spent
    uint256 _totalAmount = _calculateTotalAmount();

    // Validate cap
    if (capSpent + _totalAmount > tokenCap) {
      revert ExceededCap();
    }

    // Create actions array: one for updateState + one for each transfer
    uint256 _numActions = tokenTransfers.length + 1;
    Action[] memory _actions = new Action[](_numActions);

    // First action: update state
    _actions[0] = Action({
      target: address(this),
      data: abi.encodeWithSelector(ICappedTokenTransfers.updateState.selector, abi.encode(_totalAmount)),
      value: 0
    });

    // Remaining actions: token transfers
    for (uint256 i = 0; i < tokenTransfers.length; i++) {
      TokenTransfer memory transfer = tokenTransfers[i];
      _actions[i + 1] = Action({
        target: token,
        data: abi.encodeWithSelector(IERC20.transfer.selector, transfer.recipient, transfer.amount),
        value: 0
      });
    }

    return _actions;
  }

  function updateState(bytes memory _data) external isSafe {
    // Validate state
    if (stateUpdated) revert StateAlreadyUpdated();

    // Decode the data
    uint256 _spentAmount = abi.decode(_data, (uint256));

    uint256 _currentTimestamp = block.timestamp;

    // Reset cap if epoch has passed
    if (_currentTimestamp >= lastEpochTimestamp + tokenEpochLength) {
      capSpent = 0;
      lastEpochTimestamp = _currentTimestamp;
    }

    // Update cap spent
    capSpent += _spentAmount;

    // Clean up
    delete tokenTransfers;
    stateUpdated = true;
  }

  // ~~~ INTERNAL METHODS ~~~

  function _addTokenTransfer(address _recipient, uint256 _amount) internal {
    tokenTransfers.push(TokenTransfer({recipient: _recipient, amount: _amount}));
  }

  function _calculateTotalAmount() internal view returns (uint256) {
    uint256 _total = 0;
    for (uint256 i = 0; i < tokenTransfers.length; i++) {
      _total += tokenTransfers[i].amount;
    }
    return _total;
  }
}
