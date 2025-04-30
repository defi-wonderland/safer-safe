// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SafeManageable} from 'contracts/SafeManageable.sol';

import {ICappedTokenTransfers} from 'interfaces/actions/ICappedTokenTransfers.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract CappedTokenTransfers is SafeManageable, ICappedTokenTransfers {
  // Token cap configuration
  mapping(address => uint256) public tokenCap;
  mapping(address => uint256) public capSpent;
  mapping(address => uint256) public lastEpochTimestamp;
  mapping(address => uint256) public tokenEpochLength;

  // State tracking
  bool public stateUpdated;
  TokenTransfer[] public tokenTransfers;

  constructor(address _safe) SafeManageable(_safe) {
    stateUpdated = true;
  }

  // ~~~ ADMIN METHODS ~~~

  function addCappedToken(address _token, uint256 _cap, uint256 _epochLength) external isSafe {
    tokenCap[_token] = _cap;
    tokenEpochLength[_token] = _epochLength;
    lastEpochTimestamp[_token] = block.timestamp;
  }

  function addTokenTransfers(
    address[] memory _tokens,
    address[] memory _recipients,
    uint256[] memory _amounts
  ) external isSafeOwner {
    if (_tokens.length != _recipients.length || _tokens.length != _amounts.length) {
      revert LengthMismatch();
    }

    for (uint256 i = 0; i < _tokens.length; i++) {
      _addTokenTransfer(_tokens[i], _recipients[i], _amounts[i]);
    }

    // Mark state as needing update
    stateUpdated = false;
  }

  // ~~~ ACTIONS METHODS ~~~

  function getActions() external view returns (Action[] memory) {
    // Get unique tokens and their spent amounts
    (address[] memory uniqueTokens, uint256[] memory spentAmounts) = _getUniqueTokensAndAmounts();

    // Check caps for each token
    for (uint256 i = 0; i < uniqueTokens.length; i++) {
      address token = uniqueTokens[i];
      uint256 amount = spentAmounts[i];

      // Validate token and cap
      if (tokenCap[token] == 0) revert UnallowedToken();
      if (capSpent[token] + amount > tokenCap[token]) revert ExceededCap();
    }

    // Create actions array: one for updateState + one for each transfer
    uint256 numActions = tokenTransfers.length + 1;
    Action[] memory actions = new Action[](numActions);

    // First action: update state
    actions[0] = Action({
      target: address(this),
      data: abi.encodeWithSelector(ICappedTokenTransfers.updateState.selector, uniqueTokens, spentAmounts),
      value: 0
    });

    // Remaining actions: token transfers
    for (uint256 i = 0; i < tokenTransfers.length; i++) {
      TokenTransfer memory transfer = tokenTransfers[i];
      actions[i + 1] = Action({
        target: transfer.token,
        data: abi.encodeWithSelector(IERC20.transfer.selector, transfer.recipient, transfer.amount),
        value: 0
      });
    }

    return actions;
  }

  function updateState(address[] memory _tokens, uint256[] memory _spentAmounts) external isSafe {
    // Validate state and inputs
    if (stateUpdated) revert StateAlreadyUpdated();
    if (_tokens.length != _spentAmounts.length) revert LengthMismatch();

    // Process each token
    for (uint256 i = 0; i < _tokens.length; i++) {
      address token = _tokens[i];
      uint256 amount = _spentAmounts[i];
      uint256 epochLength = tokenEpochLength[token];
      uint256 lastTimestamp = lastEpochTimestamp[token];
      uint256 currentTimestamp = block.timestamp;

      // Reset cap if epoch has passed
      if (currentTimestamp >= lastTimestamp + epochLength) {
        capSpent[token] = 0;
        lastEpochTimestamp[token] = currentTimestamp;
      }

      // Update cap spent
      capSpent[token] += amount;
    }

    // Clean up
    delete tokenTransfers;
    stateUpdated = true;
  }

  // ~~~ INTERNAL METHODS ~~~

  function _addTokenTransfer(address _token, address _recipient, uint256 _amount) internal {
    tokenTransfers.push(TokenTransfer({token: _token, recipient: _recipient, amount: _amount}));
  }

  function _getUniqueTokensAndAmounts() internal view returns (address[] memory, uint256[] memory) {
    // First pass: count unique tokens and calculate amounts
    uint256 uniqueCount = 0;
    uint256[] memory tempAmounts = new uint256[](tokenTransfers.length);
    address[] memory tempTokens = new address[](tokenTransfers.length);

    for (uint256 i = 0; i < tokenTransfers.length; i++) {
      address token = tokenTransfers[i].token;
      bool isNew = true;

      // Check if we've seen this token before
      for (uint256 j = 0; j < uniqueCount; j++) {
        if (tempTokens[j] == token) {
          tempAmounts[j] += tokenTransfers[i].amount;
          isNew = false;
          break;
        }
      }

      // If it's a new token, add it to our temp arrays
      if (isNew) {
        tempTokens[uniqueCount] = token;
        tempAmounts[uniqueCount] = tokenTransfers[i].amount;
        uniqueCount++;
      }
    }

    // Create final arrays with exact size
    address[] memory uniqueTokens = new address[](uniqueCount);
    uint256[] memory spentAmounts = new uint256[](uniqueCount);

    // Copy data to final arrays
    for (uint256 i = 0; i < uniqueCount; i++) {
      uniqueTokens[i] = tempTokens[i];
      spentAmounts[i] = tempAmounts[i];
    }

    return (uniqueTokens, spentAmounts);
  }
}
