// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../../interfaces/IActions.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract CappedTokenTransfers is IActions {
  mapping(address => uint256) public tokenCap;
  mapping(address => uint256) public capSpent;
  mapping(address => uint256) public tokenCooldown;

  struct TokenTransfer {
    address token;
    address recipient;
    uint256 amount;
  }

  TokenTransfer[] public tokenTransfers;

  error LengthMismatch();
  error ExceededCap();
  error TokenCooldown();
  error UnallowedToken();

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

  function _addTokenTransfer(address _token, address _recipient, uint256 _amount) internal {
    tokenTransfers.push(TokenTransfer({token: _token, recipient: _recipient, amount: _amount}));
  }

  function getActions() external returns (Action[] memory) {
    Action[] memory actions = new Action[](tokenTransfers.length);

    for (uint256 i = 0; i < tokenTransfers.length; i++) {
      actions[i] = Action({
        target: tokenTransfers[i].token,
        data: abi.encodeWithSelector(IERC20.transfer.selector, tokenTransfers[i].recipient, tokenTransfers[i].amount),
        value: 0
      });
      capSpent[tokenTransfers[i].token] += tokenTransfers[i].amount;
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

    // NOTE: cleanup token transfers
    delete tokenTransfers;

    return actions;
  }

  modifier isMsig() {
    // TODO: check if sender is msig
    // NOTE: this method has a 1 week lockup
    _;
  }

  modifier isAuthorized() {
    // TODO: check if sender is msig signer
    // TODO: abstract to be reused across all actions
    _;
  }
}
