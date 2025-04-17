// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {SafeManageable} from 'contracts/SafeManageable.sol';

import {ICappedTokenTransfers} from 'interfaces/actions/ICappedTokenTransfers.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract CappedTokenTransfers is SafeManageable, ICappedTokenTransfers {
  mapping(address _token => uint256 _transferCap) public tokenCap;
  mapping(address _token => uint256 _transferCapSpent) public capSpent;
  mapping(address _token => uint256 _transferCooldown) public tokenCooldown;

  TokenTransfer[] public tokenTransfers;

  constructor(address _safe) SafeManageable(_safe) {}

  // ~~~ ADMIN METHODS ~~~

  function addCappedToken(address _token, uint256 _cap) external isMsig {
    tokenCap[_token] = _cap;
  }

  function addTokenTransfer(address _token, address _recipient, uint256 _amount) external isAuthorized {
    _addTokenTransfer(_token, _recipient, _amount);
  }

  function addTokenTransfers(
    address[] memory _tokens,
    address[] memory _recipients,
    uint256[] memory _amounts
  ) external isAuthorized {
    if (_tokens.length != _recipients.length || _tokens.length != _amounts.length) {
      revert LengthMismatch();
    }
    for (uint256 i = 0; i < _tokens.length; i++) {
      _addTokenTransfer(_tokens[i], _recipients[i], _amounts[i]);
    }
  }

  // ~~~ ACTIONS METHODS ~~~

  function getActions() external returns (Action[] memory) {
    Action[] memory actions = new Action[](tokenTransfers.length);

    for (uint256 i = 0; i < tokenTransfers.length; i++) {
      TokenTransfer memory tokenTransfer = tokenTransfers[i];
      actions[i] = Action({
        target: tokenTransfer.token,
        data: abi.encodeWithSelector(IERC20.transfer.selector, tokenTransfer.recipient, tokenTransfer.amount),
        value: 0
      });
      capSpent[tokenTransfer.token] += tokenTransfer.amount;
    }

    for (uint256 i = 0; i < tokenTransfers.length; i++) {
      address _token = tokenTransfers[i].token;
      uint256 capSpentForToken = capSpent[_token];
      if (capSpentForToken == 0) {
        // NOTE: already processed this token
        continue;
      }
      uint256 cap = tokenCap[_token];

      // NOTE: safety checks
      if (cap == 0) {
        revert UnallowedToken();
      }
      if (capSpentForToken > cap) {
        revert ExceededCap();
      }
      if (block.timestamp < tokenCooldown[_token]) {
        revert TokenCooldown();
      }

      // NOTE: update cooldown
      tokenCooldown[_token] = block.timestamp + 1 days;

      // NOTE: reset cap spent (cap is per token per tx, with 1 day cooldown)
      delete capSpent[_token];
    }

    // NOTE: cleanup token transfers (as they're already queued)
    delete tokenTransfers;

    return actions;
  }

  // ~~~ INTERNAL METHODS ~~~

  function _addTokenTransfer(address _token, address _recipient, uint256 _amount) internal {
    tokenTransfers.push(TokenTransfer({token: _token, recipient: _recipient, amount: _amount}));
  }
}
