// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {EnumerableSetLib} from 'solady/utils/EnumerableSetLib.sol';
import {SafeManageable} from 'src/contracts/SafeManageable.sol';
import {ActionHub} from 'src/contracts/action-hubs/ActionHub.sol';
import {CappedTokenTransfers} from 'src/contracts/actions-builders/CappedTokenTransfers.sol';

/**
 * @title CappedTokenTransfersHub
 * @notice Contract that creates and manages capped token transfers
 * @dev Tracks spent amounts per token per epoch and resets when a new epoch starts.
 */
contract CappedTokenTransfersHub is ActionHub, ICappedTokenTransfersHub, SafeManageable {
  using EnumerableSetLib for EnumerableSetLib.AddressSet;

  /// @inheritdoc ICappedTokenTransfersHub
  address public immutable RECIPIENT;

  /// @inheritdoc ICappedTokenTransfersHub
  uint256 public immutable EPOCH_LENGTH;

  /// @inheritdoc ICappedTokenTransfersHub
  uint256 public lastEpoch;

  /// @inheritdoc ICappedTokenTransfersHub
  mapping(address _token => uint256 _cap) public cap;

  /// @inheritdoc ICappedTokenTransfersHub
  mapping(address _token => uint256 _totalSpent) public totalSpent;

  /// @notice The tokens to cap
  EnumerableSetLib.AddressSet private __tokens;

  /**
   * @notice Constructor that sets up the actionHub
   * @param _safe The SAFE authorized to manage the hub.
   * @param _recipient Address that receives transfers.
   * @param _tokens The tokens to cap
   * @param _caps The caps for the tokens
   * @param _epochLength Duration of each epoch in seconds. Per token caps reset when the epoch changes. Can't be zero.
   */
  constructor(
    address _safe,
    address _recipient,
    address[] memory _tokens,
    uint256[] memory _caps,
    uint256 _epochLength
  ) SafeManageable(_safe) ActionHub(msg.sender) {
    RECIPIENT = _recipient;
    EPOCH_LENGTH = _epochLength;
    lastEpoch = block.timestamp;

    if (_tokens.length != _caps.length) revert TokensAndCapsLengthMismatch();
    if (_epochLength == 0) revert EpochLengthCannotBeZero();

    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_caps[i] == 0) revert CapCannotBeZero();
      if (!__tokens.add(_tokens[i])) {
        revert TokenAlreadyRegisteredInHub(_tokens[i]);
      }
      cap[_tokens[i]] = _caps[i];
    }
  }

  /// @inheritdoc ICappedTokenTransfersHub
  function createNewActionsBuilder(
    address _token,
    uint256 _amount
  ) external isSafeOwner returns (address _actionsBuilder) {
    if (!__tokens.contains(_token)) revert TokenNotRegisteredInHub();

    _actionsBuilder = address(new CappedTokenTransfers(_token, _amount, RECIPIENT));

    _saveNewActionsBuilder(_actionsBuilder);

    emit CappedTokenTransfersCreated(_actionsBuilder, _token, _amount);
  }

  /// @inheritdoc ICappedTokenTransfersHub
  function updateState(address _token, uint256 _amount) external isSafe {
    // Calculate how many seconds have passed since the last saved epoch
    uint256 _secondsSinceLastEpoch = block.timestamp - lastEpoch;
    // Calculate the remainder of the seconds since the actual last epoch (given that many epochs may have passed without updating the state)
    uint256 _remainder = _secondsSinceLastEpoch % EPOCH_LENGTH;
    // Substract the remainder from the current timestamp to get the actual last epoch
    uint256 _currentEpoch = block.timestamp - _remainder;

    // If we're in a new epoch, reset the spending
    if (_currentEpoch > lastEpoch) {
      delete totalSpent[_token];
      lastEpoch = _currentEpoch;
    }

    totalSpent[_token] += _amount;

    if (totalSpent[_token] > cap[_token]) {
      revert CapExceeded();
    }

    emit StateUpdated(_token, _amount, lastEpoch);
  }

  /// @inheritdoc ICappedTokenTransfersHub
  function tokens() external view returns (address[] memory _tokens) {
    _tokens = __tokens.values();
  }

  /// @inheritdoc ICappedTokenTransfersHub
  function capLeft(address _token) external view returns (uint256 _capLeft) {
    uint256 _secondsSinceLastEpoch = block.timestamp - lastEpoch;
    uint256 _remainder = _secondsSinceLastEpoch % EPOCH_LENGTH;
    uint256 _currentEpoch = block.timestamp - _remainder;

    uint256 _tokenCap = cap[_token];

    // If we're in a new epoch, return the full cap
    if (_currentEpoch > lastEpoch) {
      _capLeft = _tokenCap;
    } else {
      // Otherwise, return the cap left for the token
      _capLeft = _tokenCap - totalSpent[_token];
    }
  }
}
