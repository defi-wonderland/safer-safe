// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {SafeManageable} from 'src/contracts/SafeManageable.sol';

import {ActionHub} from 'src/contracts/action-hubs/ActionHub.sol';
import {CappedTokenTransfers} from 'src/contracts/actions-builders/CappedTokenTransfers.sol';

contract CappedTokenTransfersHub is ActionHub, ICappedTokenTransfersHub, SafeManageable {
  /// @inheritdoc ICappedTokenTransfersHub
  address public immutable RECIPIENT;

  /// @inheritdoc ICappedTokenTransfersHub
  uint256 public immutable EPOCH_LENGTH;

  /// @inheritdoc ICappedTokenTransfersHub
  uint256 public immutable STARTING_TIMESTAMP;

  /// @inheritdoc ICappedTokenTransfersHub
  uint256 public currentEpoch;

  /// @inheritdoc ICappedTokenTransfersHub
  mapping(address _token => uint256 _cap) public cap;

  /// @inheritdoc ICappedTokenTransfersHub
  mapping(address _token => uint256 _totalSpent) public totalSpent;

  /**
   * @notice Constructor that sets up the actionHub
   * @param _factory The factory that deployed the actionHub
   * @param _safe The safe to use
   * @param _recipient The recipient of the tokens
   * @param _tokens The tokens to cap
   * @param _caps The caps for the tokens
   * @param _epochLength The length of the epoch
   */
  constructor(
    address _factory,
    address _safe,
    address _recipient,
    address[] memory _tokens,
    uint256[] memory _caps,
    uint256 _epochLength
  ) SafeManageable(_safe) {
    FACTORY = _factory;
    RECIPIENT = _recipient;
    EPOCH_LENGTH = _epochLength;
    STARTING_TIMESTAMP = block.timestamp;

    if (_epochLength == 0) revert EpochLengthCannotBeZero();

    for (uint256 i = 0; i < _tokens.length; i++) {
      cap[_tokens[i]] = _caps[i];
    }
  }

  /// @inheritdoc ICappedTokenTransfersHub
  function createNewActionBuilder(
    address _token,
    uint256 _amount
  ) external isSafeOwner returns (address _actionBuilder) {
    if (cap[_token] == 0) revert TokenNotRegisteredInHub();
    bytes memory _initCode = abi.encodePacked(
      type(CappedTokenTransfers).creationCode, abi.encode(address(this), _token, _amount, RECIPIENT, address(this))
    );

    bytes32 _salt = keccak256(abi.encode(_token, _amount, RECIPIENT));

    _actionBuilder = _createNewActionBuilder(_initCode, _salt);
  }

  /// @inheritdoc ICappedTokenTransfersHub
  function updateState(address _token, uint256 _amount) external isSafe {
    uint256 _currentEpoch = (block.timestamp - STARTING_TIMESTAMP) / EPOCH_LENGTH;

    // If we're in a new epoch, reset the spending
    if (_currentEpoch > currentEpoch) {
      delete totalSpent[_token];
      currentEpoch = _currentEpoch;
    }

    totalSpent[_token] += _amount;

    if (totalSpent[_token] > cap[_token]) {
      revert CapExceeded();
    }
  }
}
