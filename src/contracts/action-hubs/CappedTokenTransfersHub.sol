// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';

import {EnumerableSetLib} from 'solady/utils/EnumerableSetLib.sol';
import {SafeManageable} from 'src/contracts/SafeManageable.sol';

import {ActionHub} from 'src/contracts/action-hubs/ActionHub.sol';
import {CappedTokenTransfers} from 'src/contracts/actions-builders/CappedTokenTransfers.sol';

contract CappedTokenTransfersHub is ActionHub, ICappedTokenTransfersHub, SafeManageable {
  using EnumerableSetLib for EnumerableSetLib.AddressSet;

  /// @inheritdoc ICappedTokenTransfersHub
  address public immutable RECIPIENT;

  /// @inheritdoc ICappedTokenTransfersHub
  uint256 public immutable EPOCH_LENGTH;

  /// @inheritdoc ICappedTokenTransfersHub
  uint256 public immutable STARTING_TIMESTAMP;

  /// @inheritdoc ICappedTokenTransfersHub
  uint256 public currentEpoch;

  /// @inheritdoc ICappedTokenTransfersHub
  mapping(address _token => uint256 _totalSpent) public totalSpent;

  /// @inheritdoc ICappedTokenTransfersHub
  mapping(address _token => uint256 _cap) public cap;

  /// @notice The tokens to cap
  EnumerableSetLib.AddressSet private __tokens;

  /**
   * @notice Constructor that sets up the actionHub
   * @param _safe The safe to use
   * @param _recipient The recipient of the tokens
   * @param _tokens The tokens to cap
   * @param _caps The caps for the tokens
   * @param _epochLength Duration of each epoch in seconds. Epochs are counted from STARTING_TIMESTAMP and computed as
   *  (block.timestamp - STARTING_TIMESTAMP) / _epochLength. Per token caps reset when the epoch increments. Can't be zero.
   */
  constructor(
    address _safe,
    address _recipient,
    address[] memory _tokens,
    uint256[] memory _caps,
    uint256 _epochLength
  ) SafeManageable(_safe) {
    RECIPIENT = _recipient;
    EPOCH_LENGTH = _epochLength;
    STARTING_TIMESTAMP = block.timestamp;

    if (_epochLength == 0) revert EpochLengthCannotBeZero();

    for (uint256 i = 0; i < _tokens.length; i++) {
      // If the token is already registered, add the cap to the existing cap
      if (!__tokens.add(_tokens[i])) {
        cap[_tokens[i]] += _caps[i];
      } else {
        cap[_tokens[i]] = _caps[i];
      }
    }
  }

  /// @inheritdoc ICappedTokenTransfersHub
  function createNewActionBuilder(
    address _token,
    uint256 _amount
  ) external isSafeOwner returns (address _actionBuilder) {
    if (!__tokens.contains(_token)) revert TokenNotRegisteredInHub();

    bytes memory _initCode =
      abi.encodePacked(type(CappedTokenTransfers).creationCode, abi.encode(_token, _amount, RECIPIENT, address(this)));
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

  /// @inheritdoc ICappedTokenTransfersHub
  function tokens() external view returns (address[] memory _tokens) {
    _tokens = __tokens.values();
  }

  /// @inheritdoc ICappedTokenTransfersHub
  function capLeft(address _token) external view returns (uint256 _capLeft) {
    uint256 _currentEpoch = (block.timestamp - STARTING_TIMESTAMP) / EPOCH_LENGTH;
    uint256 _tokenCap = cap[_token];

    // If we're in a new epoch, return the full cap
    if (_currentEpoch > currentEpoch) {
      _capLeft = _tokenCap;
    } else {
      // Otherwise, return the cap left for the token
      _capLeft = _tokenCap - totalSpent[_token];
    }
  }
}
