// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IOwnerManager} from '@safe-smart-account/interfaces/IOwnerManager.sol';
import {Test} from 'forge-std/Test.sol';
import {CanonGuardRegistry} from 'src/contracts/periphery/CanonGuardRegistry.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';
import {ICanonGuardRegistry} from 'src/interfaces/periphery/ICanonGuardRegistry.sol';

contract UnitCanonGuardRegistry is Test {
  CanonGuardRegistry public registry;

  address public canonGuard = makeAddr('canonGuard');
  address public safe = makeAddr('safe');
  address public constant ZERO_SENTINEL = address(0xfbb67fda52d4bfb8bf);

  function setUp() public {
    registry = new CanonGuardRegistry();

    // Mock CanonGuard.SAFE() to return safe address
    vm.mockCall(canonGuard, abi.encodeWithSelector(ISafeManageable.SAFE.selector), abi.encode(safe));
  }

  function _mockAndExpect(address _target, bytes memory _call, bytes memory _returnData) internal {
    vm.mockCall(_target, _call, _returnData);
    vm.expectCall(_target, _call);
  }

  function _mockSignerCheck(address _caller, bool _isOwner) internal {
    vm.mockCall(safe, abi.encodeWithSelector(IOwnerManager.isOwner.selector, _caller), abi.encode(_isOwner));
  }

  modifier whenCallerIsSigner(address _caller) {
    _mockSignerCheck(_caller, true);
    vm.startPrank(_caller);
    _;
    vm.stopPrank();
  }

  function test_Record_WhenTheCallerIsNotASigner(address _caller, address _entity, string memory _label) external {
    _mockSignerCheck(_caller, false);

    address[] memory _entities = new address[](1);
    _entities[0] = _entity;
    string[] memory _labels = new string[](1);
    _labels[0] = _label;

    // it reverts with NotSafeSigner
    vm.expectRevert(ICanonGuardRegistry.NotSafeSigner.selector);
    vm.prank(_caller);
    registry.record(canonGuard, _entities, _labels);
  }

  function test_Record_WhenTheArraysHaveDifferentLengths(
    address _caller,
    address _entity1,
    address _entity2,
    string memory _label1
  ) external whenCallerIsSigner(_caller) {
    address[] memory _entities = new address[](2);
    _entities[0] = _entity1;
    _entities[1] = _entity2;
    string[] memory _labels = new string[](1);
    _labels[0] = _label1;

    // it reverts with ArrayLengthMismatch
    vm.expectRevert(ICanonGuardRegistry.ArrayLengthMismatch.selector);
    registry.record(canonGuard, _entities, _labels);
  }

  function test_Record_WhenALabelIsEmpty(address _caller, address _entity) external whenCallerIsSigner(_caller) {
    address[] memory _entities = new address[](1);
    _entities[0] = _entity;
    string[] memory _labels = new string[](1);
    _labels[0] = '';

    // it reverts with EmptyLabel
    vm.expectRevert(ICanonGuardRegistry.EmptyLabel.selector);
    registry.record(canonGuard, _entities, _labels);
  }

  function test_Record_WhenExecutingTheFunction(
    address _caller,
    address _entity1,
    address _entity2,
    string memory _label1,
    string memory _label2
  ) external whenCallerIsSigner(_caller) {
    vm.assume(_entity1 != _entity2);
    vm.assume(_entity1 != ZERO_SENTINEL);
    vm.assume(_entity2 != ZERO_SENTINEL);
    vm.assume(bytes(_label1).length > 0);
    vm.assume(bytes(_label2).length > 0);

    address[] memory _entities = new address[](2);
    _entities[0] = _entity1;
    _entities[1] = _entity2;
    string[] memory _labels = new string[](2);
    _labels[0] = _label1;
    _labels[1] = _label2;

    uint256 _timestamp = block.timestamp;

    // it emits EntityRecorded event
    vm.expectEmit();
    emit ICanonGuardRegistry.EntityRecorded(canonGuard, _entity1, _label1, _timestamp);
    vm.expectEmit();
    emit ICanonGuardRegistry.EntityRecorded(canonGuard, _entity2, _label2, _timestamp);

    registry.record(canonGuard, _entities, _labels);

    // it adds the entity to the set
    assertEq(registry.totalEntities(canonGuard), 2);

    // it stores the edition
    ICanonGuardRegistry.Edition memory _edition1 = registry.entityLabel(canonGuard, _entity1);
    assertEq(_edition1.label, _label1);
    assertEq(_edition1.lastEditedAt, _timestamp);

    ICanonGuardRegistry.Edition memory _edition2 = registry.entityLabel(canonGuard, _entity2);
    assertEq(_edition2.label, _label2);
    assertEq(_edition2.lastEditedAt, _timestamp);
  }

  function test_Remove_WhenTheCallerIsNotASigner(address _caller, address _entity) external {
    _mockSignerCheck(_caller, false);

    address[] memory _entities = new address[](1);
    _entities[0] = _entity;

    // it reverts with NotSafeSigner
    vm.expectRevert(ICanonGuardRegistry.NotSafeSigner.selector);
    vm.prank(_caller);
    registry.remove(canonGuard, _entities);
  }

  function test_Remove_WhenTheEntityIsNotFound(address _caller, address _entity) external whenCallerIsSigner(_caller) {
    vm.assume(_entity != ZERO_SENTINEL);

    address[] memory _entities = new address[](1);
    _entities[0] = _entity;

    // it reverts with EntityNotFound
    vm.expectRevert(ICanonGuardRegistry.EntityNotFound.selector);
    registry.remove(canonGuard, _entities);
  }

  function test_Remove_WhenExecutingTheFunction(
    address _caller,
    address _entity1,
    string memory _label1
  ) external whenCallerIsSigner(_caller) {
    vm.assume(_entity1 != ZERO_SENTINEL);
    vm.assume(bytes(_label1).length > 0);

    // First, record an entity
    address[] memory _recordEntities = new address[](1);
    _recordEntities[0] = _entity1;
    string[] memory _labels = new string[](1);
    _labels[0] = _label1;
    registry.record(canonGuard, _recordEntities, _labels);

    // Now remove it
    address[] memory _removeEntities = new address[](1);
    _removeEntities[0] = _entity1;

    // it emits EntityRemoved event
    vm.expectEmit();
    emit ICanonGuardRegistry.EntityRemoved(canonGuard, _entity1);

    registry.remove(canonGuard, _removeEntities);

    // it removes the entity from the set
    assertEq(registry.totalEntities(canonGuard), 0);

    // it clears the edition
    ICanonGuardRegistry.Edition memory _edition = registry.entityLabel(canonGuard, _entity1);
    assertEq(_edition.label, '');
    assertEq(_edition.lastEditedAt, 0);
  }

  function test_TotalEntities_ReturnsTheLengthOfTheSet(
    address _caller,
    address _entity1,
    address _entity2,
    string memory _label1,
    string memory _label2
  ) external whenCallerIsSigner(_caller) {
    vm.assume(_entity1 != _entity2);
    vm.assume(_entity1 != ZERO_SENTINEL);
    vm.assume(_entity2 != ZERO_SENTINEL);
    vm.assume(bytes(_label1).length > 0);
    vm.assume(bytes(_label2).length > 0);

    assertEq(registry.totalEntities(canonGuard), 0);

    address[] memory _entities = new address[](2);
    _entities[0] = _entity1;
    _entities[1] = _entity2;
    string[] memory _labels = new string[](2);
    _labels[0] = _label1;
    _labels[1] = _label2;

    registry.record(canonGuard, _entities, _labels);

    // it returns the length of the set
    assertEq(registry.totalEntities(canonGuard), 2);
  }

  function test_Read_WhenOffsetIsGreaterThanTheTotalNumberOfEntities(
    address _caller,
    address _entity1,
    address _entity2,
    string memory _label1,
    uint256 _offset
  ) external whenCallerIsSigner(_caller) {
    vm.assume(_entity1 != _entity2);
    vm.assume(_entity1 != ZERO_SENTINEL);
    vm.assume(_entity2 != ZERO_SENTINEL);
    vm.assume(bytes(_label1).length > 0);
    vm.assume(_offset > 2);

    address[] memory _entities = new address[](1);
    _entities[0] = _entity1;
    string[] memory _labels = new string[](1);
    _labels[0] = _label1;

    registry.record(canonGuard, _entities, _labels);

    ICanonGuardRegistry.EntityWithEdition[] memory _result = registry.read(canonGuard, _offset, 0);

    // it returns an empty array
    assertEq(_result.length, 0);
  }

  modifier whenExecutingTheFunction(address[10] memory _entities, string[10] memory _labels) {
    for (uint256 i = 0; i < 10; i++) {
      // Prevents wasting fuzz
      if (_entities[i] == ZERO_SENTINEL) _entities[i] = makeAddr(string(abi.encodePacked('entity', i)));
      if (bytes(_labels[i]).length == 0) _labels[i] = string(abi.encodePacked('label', i));

      // Prevents duplicate entities
      if (registry.entityLabel(canonGuard, _entities[i]).lastEditedAt != 0) {
        // Found duplicate entity
        _entities[i] = makeAddr(string(abi.encodePacked('dup-entity', i)));
      }

      address[] memory _entitiesArray = new address[](1);
      _entitiesArray[0] = _entities[i];
      string[] memory _labelsArray = new string[](1);
      _labelsArray[0] = _labels[i];

      registry.record(canonGuard, _entitiesArray, _labelsArray);
    }
    _;
  }

  function test_Read_WhenEntitiesToReturnAreLessThanTheLimit(
    address _caller,
    address[10] memory _entities,
    string[10] memory _labels,
    uint256 _offset,
    uint256 _limit
  ) external whenCallerIsSigner(_caller) whenExecutingTheFunction(_entities, _labels) {
    _offset = bound(_offset, 1, 10);
    uint256 _toReturn = 10 - _offset;
    _limit = bound(_limit, _toReturn, type(uint256).max);

    ICanonGuardRegistry.EntityWithEdition[] memory _result = registry.read(canonGuard, _offset, _limit);

    assertEq(_result.length, _toReturn);

    // it returns the entities with their editions
    for (uint256 i = 0; i < _toReturn; i++) {
      assertEq(_result[i].entity, _entities[i + _offset]);
      assertEq(_result[i].edition.label, _labels[i + _offset]);
      assertEq(_result[i].edition.lastEditedAt, block.timestamp);
    }
  }

  function test_Read_WhenEntitiesToReturnAreGreaterThanTheLimit(
    address _caller,
    address[10] memory _entities,
    string[10] memory _labels,
    uint256 _offset,
    uint256 _limit
  ) external whenCallerIsSigner(_caller) whenExecutingTheFunction(_entities, _labels) {
    _offset = bound(_offset, 1, 10);
    uint256 _toReturn = 10 - _offset;
    _limit = bound(_limit, 0, _toReturn);

    ICanonGuardRegistry.EntityWithEdition[] memory _result = registry.read(canonGuard, _offset, _limit);

    assertEq(_result.length, _limit);

    // it returns the entities with their editions
    for (uint256 i = 0; i < _limit; i++) {
      assertEq(_result[i].entity, _entities[i + _offset]);
      assertEq(_result[i].edition.label, _labels[i + _offset]);
      assertEq(_result[i].edition.lastEditedAt, block.timestamp);
    }
  }

  function test_EntityLabel_ReturnsTheEditionOfTheEntity(
    address _caller,
    address _entity,
    string memory _label
  ) external whenCallerIsSigner(_caller) {
    vm.assume(_entity != ZERO_SENTINEL);
    vm.assume(bytes(_label).length > 0);

    address[] memory _entities = new address[](1);
    _entities[0] = _entity;
    string[] memory _labels = new string[](1);
    _labels[0] = _label;

    uint256 _timestamp = block.timestamp;
    registry.record(canonGuard, _entities, _labels);

    // it returns the edition of the entity
    ICanonGuardRegistry.Edition memory _edition = registry.entityLabel(canonGuard, _entity);
    assertEq(_edition.label, _label);
    assertEq(_edition.lastEditedAt, _timestamp);
  }
}
