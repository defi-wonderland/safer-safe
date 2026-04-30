// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';
import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {ICanonGuardRegistry} from 'interfaces/periphery/ICanonGuardRegistry.sol';
import {EnumerableSetLib} from 'solady/utils/EnumerableSetLib.sol';

/**
 * @title CanonGuardRegistry
 * @notice A shared registry for labeling entities (action builders, hubs) associated with CanonGuard instances
 * @dev Only Safe signers can record/remove labels for their CanonGuard's entities
 */
contract CanonGuardRegistry is ICanonGuardRegistry {
  using EnumerableSetLib for EnumerableSetLib.AddressSet;

  // ~~~ STORAGE ~~~

  /// @notice Mapping of CanonGuard address to set of registered entities
  mapping(address _canonGuard => EnumerableSetLib.AddressSet _entities) internal _canonGuardEntities;

  /// @notice Mapping of CanonGuard address to entity address to edition data
  mapping(address _canonGuard => mapping(address _entity => Edition _edition)) internal _entityLabels;

  // ~~~ MODIFIERS ~~~

  /**
   * @notice Ensures the caller is a signer of the Safe associated with the CanonGuard
   * @param _canonGuard The CanonGuard instance to check against
   */
  modifier onlySafeSigner(address _canonGuard) {
    _onlySafeSigner(_canonGuard);
    _;
  }

  // ~~~ MUTATIVE METHODS ~~~

  /// @inheritdoc ICanonGuardRegistry
  function record(
    address _canonGuard,
    address[] calldata _entities,
    string[] calldata _labels
  ) external onlySafeSigner(_canonGuard) {
    if (_entities.length != _labels.length) revert ArrayLengthMismatch();

    uint256 _length = _entities.length;
    for (uint256 _i; _i < _length; ++_i) {
      address _entity = _entities[_i];
      string calldata _label = _labels[_i];

      // Validate non-empty label
      if (bytes(_label).length == 0) revert EmptyLabel();

      // Add to set (no-op if already exists)
      _canonGuardEntities[_canonGuard].add(_entity);

      // Store the edition
      uint256 _timestamp = block.timestamp;
      _entityLabels[_canonGuard][_entity] = Edition({label: _label, lastEditedAt: _timestamp});

      emit EntityRecorded(_canonGuard, _entity, _label, _timestamp);
    }
  }

  /// @inheritdoc ICanonGuardRegistry
  function remove(address _canonGuard, address[] calldata _entities) external onlySafeSigner(_canonGuard) {
    uint256 _length = _entities.length;
    for (uint256 _i; _i < _length; ++_i) {
      address _entity = _entities[_i];

      // Remove from set - revert if not found
      if (!_canonGuardEntities[_canonGuard].remove(_entity)) revert EntityNotFound();

      // Clear the edition data
      delete _entityLabels[_canonGuard][_entity];

      emit EntityRemoved(_canonGuard, _entity);
    }
  }

  // ~~~ VIEW METHODS ~~~

  /// @inheritdoc ICanonGuardRegistry
  function totalEntities(address _canonGuard) external view returns (uint256 _total) {
    _total = _canonGuardEntities[_canonGuard].length();
  }

  /// @inheritdoc ICanonGuardRegistry
  function read(
    address _canonGuard,
    uint256 _offset,
    uint256 _limit
  ) external view returns (EntityWithEdition[] memory _entities) {
    EnumerableSetLib.AddressSet storage _set = _canonGuardEntities[_canonGuard];
    uint256 _totalCount = _set.length();

    // Handle edge cases
    if (_offset >= _totalCount) {
      return new EntityWithEdition[](0);
    }

    // Calculate actual count to return
    uint256 _remaining = _totalCount - _offset;
    uint256 _count = _limit < _remaining ? _limit : _remaining;

    _entities = new EntityWithEdition[](_count);

    for (uint256 _i; _i < _count; ++_i) {
      address _entity = _set.at(_offset + _i);
      _entities[_i] = EntityWithEdition({entity: _entity, edition: _entityLabels[_canonGuard][_entity]});
    }
  }

  /// @inheritdoc ICanonGuardRegistry
  function entityLabel(address _canonGuard, address _entity) external view returns (Edition memory _edition) {
    _edition = _entityLabels[_canonGuard][_entity];
  }

  /**
   * @notice Internal function to check if the caller is a Safe signer
   * @param _canonGuard The CanonGuard instance to check against
   */
  function _onlySafeSigner(address _canonGuard) internal view {
    ISafe _safe = ISafeManageable(_canonGuard).SAFE();
    if (!_safe.isOwner(msg.sender)) revert NotSafeSigner();
  }
}
