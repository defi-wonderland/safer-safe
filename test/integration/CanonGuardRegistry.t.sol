// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';
import {CanonGuard} from 'contracts/CanonGuard.sol';
import {CanonGuardRegistry} from 'contracts/periphery/CanonGuardRegistry.sol';
import {Test} from 'forge-std/Test.sol';
import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {ICanonGuardRegistry} from 'interfaces/periphery/ICanonGuardRegistry.sol';
import {EthereumConstants} from 'script/Constants.sol';

contract IntegrationCanonGuardRegistry is EthereumConstants, Test {
  uint256 internal constant _ETHEREUM_FORK_BLOCK = 18_920_905;
  address internal constant _EMERGENCY_TRIGGER = address(1);
  address internal constant _EMERGENCY_CALLER = address(2);

  // ~~~ CONTRACTS ~~~
  ISafe internal _safeProxy;
  ICanonGuard internal _canonGuard;
  ICanonGuardRegistry internal _registry;

  // ~~~ ACTORS ~~~
  address internal _safeOwner;
  address internal _safeOwner2;
  address internal _nonOwner;

  // ~~~ TEST DATA ~~~
  address internal _entity1;
  address internal _entity2;
  address internal _entity3;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('ethereum'), _ETHEREUM_FORK_BLOCK);

    // Deploy the SafeProxy contract
    _safeProxy = ISafe(address(SAFE_PROXY_FACTORY.createProxyWithNonce(address(SAFE), bytes(''), 1)));

    _safeOwner = makeAddr('safeOwner');
    _safeOwner2 = makeAddr('safeOwner2');
    _nonOwner = makeAddr('nonOwner');

    address[] memory _safeOwners = new address[](2);
    _safeOwners[0] = _safeOwner;
    _safeOwners[1] = _safeOwner2;

    _safeProxy.setup({
      _owners: _safeOwners,
      _threshold: 1,
      to: address(0),
      data: bytes(''),
      fallbackHandler: address(0),
      paymentToken: address(0),
      payment: 0,
      paymentReceiver: payable(address(0))
    });

    // Deploy the CanonGuard contract directly (bypassing factory to avoid test issues)
    _canonGuard = ICanonGuard(
      address(
        new CanonGuard(
          address(0), // parent
          address(_safeProxy),
          address(MULTI_SEND_CALL_ONLY),
          SHORT_TX_EXECUTION_DELAY,
          LONG_TX_EXECUTION_DELAY,
          TX_EXPIRY_DELAY,
          MAX_APPROVAL_DURATION,
          _EMERGENCY_TRIGGER,
          _EMERGENCY_CALLER
        )
      )
    );

    // Deploy the CanonGuardRegistry
    _registry = ICanonGuardRegistry(address(new CanonGuardRegistry()));

    // Create test entity addresses
    _entity1 = makeAddr('entity1');
    _entity2 = makeAddr('entity2');
    _entity3 = makeAddr('entity3');
  }

  // ~~~ RECORD TESTS ~~~

  function test_Record_SingleEntity() public {
    address[] memory _entities = new address[](1);
    _entities[0] = _entity1;

    string[] memory _labels = new string[](1);
    _labels[0] = 'My Action Builder';

    vm.prank(_safeOwner);
    _registry.record(address(_canonGuard), _entities, _labels);

    // Verify
    assertEq(_registry.totalEntities(address(_canonGuard)), 1);

    ICanonGuardRegistry.Edition memory _edition = _registry.entityLabel(address(_canonGuard), _entity1);
    assertEq(_edition.label, 'My Action Builder');
    assertEq(_edition.lastEditedAt, block.timestamp);
  }

  function test_Record_MultipleEntities() public {
    address[] memory _entities = new address[](3);
    _entities[0] = _entity1;
    _entities[1] = _entity2;
    _entities[2] = _entity3;

    string[] memory _labels = new string[](3);
    _labels[0] = 'Action Builder 1';
    _labels[1] = 'Action Hub';
    _labels[2] = 'Transfer Builder';

    vm.prank(_safeOwner);
    _registry.record(address(_canonGuard), _entities, _labels);

    // Verify
    assertEq(_registry.totalEntities(address(_canonGuard)), 3);

    ICanonGuardRegistry.Edition memory _edition1 = _registry.entityLabel(address(_canonGuard), _entity1);
    assertEq(_edition1.label, 'Action Builder 1');

    ICanonGuardRegistry.Edition memory _edition2 = _registry.entityLabel(address(_canonGuard), _entity2);
    assertEq(_edition2.label, 'Action Hub');

    ICanonGuardRegistry.Edition memory _edition3 = _registry.entityLabel(address(_canonGuard), _entity3);
    assertEq(_edition3.label, 'Transfer Builder');
  }

  function test_Record_UpdateExistingLabel() public {
    // First record
    address[] memory _entities = new address[](1);
    _entities[0] = _entity1;

    string[] memory _labels = new string[](1);
    _labels[0] = 'Original Label';

    vm.prank(_safeOwner);
    _registry.record(address(_canonGuard), _entities, _labels);

    uint256 _firstTimestamp = block.timestamp;

    // Warp time
    vm.warp(block.timestamp + 1 days);

    // Update label
    _labels[0] = 'Updated Label';

    vm.prank(_safeOwner2); // Different owner can update
    _registry.record(address(_canonGuard), _entities, _labels);

    // Verify - should still be 1 entity, but with updated label
    assertEq(_registry.totalEntities(address(_canonGuard)), 1);

    ICanonGuardRegistry.Edition memory _edition = _registry.entityLabel(address(_canonGuard), _entity1);
    assertEq(_edition.label, 'Updated Label');
    assertGt(_edition.lastEditedAt, _firstTimestamp);
  }

  function test_Record_EmitsEvent() public {
    address[] memory _entities = new address[](1);
    _entities[0] = _entity1;

    string[] memory _labels = new string[](1);
    _labels[0] = 'Test Label';

    vm.expectEmit(true, true, false, true);
    emit ICanonGuardRegistry.EntityRecorded(address(_canonGuard), _entity1, 'Test Label', block.timestamp);

    vm.prank(_safeOwner);
    _registry.record(address(_canonGuard), _entities, _labels);
  }

  function test_Record_RevertWhen_NotSafeSigner() public {
    address[] memory _entities = new address[](1);
    _entities[0] = _entity1;

    string[] memory _labels = new string[](1);
    _labels[0] = 'Test Label';

    vm.prank(_nonOwner);
    vm.expectRevert(ICanonGuardRegistry.NotSafeSigner.selector);
    _registry.record(address(_canonGuard), _entities, _labels);
  }

  function test_Record_RevertWhen_ArrayLengthMismatch() public {
    address[] memory _entities = new address[](2);
    _entities[0] = _entity1;
    _entities[1] = _entity2;

    string[] memory _labels = new string[](1);
    _labels[0] = 'Test Label';

    vm.prank(_safeOwner);
    vm.expectRevert(ICanonGuardRegistry.ArrayLengthMismatch.selector);
    _registry.record(address(_canonGuard), _entities, _labels);
  }

  function test_Record_RevertWhen_EmptyLabel() public {
    address[] memory _entities = new address[](1);
    _entities[0] = _entity1;

    string[] memory _labels = new string[](1);
    _labels[0] = '';

    vm.prank(_safeOwner);
    vm.expectRevert(ICanonGuardRegistry.EmptyLabel.selector);
    _registry.record(address(_canonGuard), _entities, _labels);
  }

  // ~~~ READ TESTS ~~~

  function test_Read_Paginated() public {
    // Record 5 entities
    address[] memory _entities = new address[](5);
    string[] memory _labels = new string[](5);

    for (uint256 i = 0; i < 5; i++) {
      _entities[i] = makeAddr(string(abi.encodePacked('entity', i)));
      _labels[i] = string(abi.encodePacked('Label ', i));
    }

    vm.prank(_safeOwner);
    _registry.record(address(_canonGuard), _entities, _labels);

    // Read first 2
    ICanonGuardRegistry.EntityWithEdition[] memory _result1 = _registry.read(address(_canonGuard), 0, 2);
    assertEq(_result1.length, 2);

    // Read next 2
    ICanonGuardRegistry.EntityWithEdition[] memory _result2 = _registry.read(address(_canonGuard), 2, 2);
    assertEq(_result2.length, 2);

    // Read last 1
    ICanonGuardRegistry.EntityWithEdition[] memory _result3 = _registry.read(address(_canonGuard), 4, 2);
    assertEq(_result3.length, 1);

    // Read with offset beyond total
    ICanonGuardRegistry.EntityWithEdition[] memory _result4 = _registry.read(address(_canonGuard), 10, 2);
    assertEq(_result4.length, 0);
  }

  function test_Read_EmptyRegistry() public view {
    ICanonGuardRegistry.EntityWithEdition[] memory _result = _registry.read(address(_canonGuard), 0, 10);
    assertEq(_result.length, 0);
  }

  // ~~~ REMOVE TESTS ~~~

  function test_Remove_SingleEntity() public {
    // First record
    address[] memory _entities = new address[](2);
    _entities[0] = _entity1;
    _entities[1] = _entity2;

    string[] memory _labels = new string[](2);
    _labels[0] = 'Label 1';
    _labels[1] = 'Label 2';

    vm.prank(_safeOwner);
    _registry.record(address(_canonGuard), _entities, _labels);

    assertEq(_registry.totalEntities(address(_canonGuard)), 2);

    // Remove one entity
    address[] memory _toRemove = new address[](1);
    _toRemove[0] = _entity1;

    vm.prank(_safeOwner);
    _registry.remove(address(_canonGuard), _toRemove);

    // Verify
    assertEq(_registry.totalEntities(address(_canonGuard)), 1);

    ICanonGuardRegistry.Edition memory _edition1 = _registry.entityLabel(address(_canonGuard), _entity1);
    assertEq(_edition1.label, ''); // Should be cleared
    assertEq(_edition1.lastEditedAt, 0);

    ICanonGuardRegistry.Edition memory _edition2 = _registry.entityLabel(address(_canonGuard), _entity2);
    assertEq(_edition2.label, 'Label 2'); // Should remain
  }

  function test_Remove_MultipleEntities() public {
    // First record
    address[] memory _entities = new address[](3);
    _entities[0] = _entity1;
    _entities[1] = _entity2;
    _entities[2] = _entity3;

    string[] memory _labels = new string[](3);
    _labels[0] = 'Label 1';
    _labels[1] = 'Label 2';
    _labels[2] = 'Label 3';

    vm.prank(_safeOwner);
    _registry.record(address(_canonGuard), _entities, _labels);

    // Remove two entities
    address[] memory _toRemove = new address[](2);
    _toRemove[0] = _entity1;
    _toRemove[1] = _entity3;

    vm.prank(_safeOwner2);
    _registry.remove(address(_canonGuard), _toRemove);

    // Verify
    assertEq(_registry.totalEntities(address(_canonGuard)), 1);
  }

  function test_Remove_EmitsEvent() public {
    // First record
    address[] memory _entities = new address[](1);
    _entities[0] = _entity1;

    string[] memory _labels = new string[](1);
    _labels[0] = 'Label';

    vm.prank(_safeOwner);
    _registry.record(address(_canonGuard), _entities, _labels);

    // Remove
    vm.expectEmit(true, true, false, false);
    emit ICanonGuardRegistry.EntityRemoved(address(_canonGuard), _entity1);

    vm.prank(_safeOwner);
    _registry.remove(address(_canonGuard), _entities);
  }

  function test_Remove_RevertWhen_NotSafeSigner() public {
    // First record
    address[] memory _entities = new address[](1);
    _entities[0] = _entity1;

    string[] memory _labels = new string[](1);
    _labels[0] = 'Label';

    vm.prank(_safeOwner);
    _registry.record(address(_canonGuard), _entities, _labels);

    // Try to remove as non-owner
    vm.prank(_nonOwner);
    vm.expectRevert(ICanonGuardRegistry.NotSafeSigner.selector);
    _registry.remove(address(_canonGuard), _entities);
  }

  function test_Remove_RevertWhen_EntityNotFound() public {
    address[] memory _toRemove = new address[](1);
    _toRemove[0] = _entity1;

    vm.prank(_safeOwner);
    vm.expectRevert(ICanonGuardRegistry.EntityNotFound.selector);
    _registry.remove(address(_canonGuard), _toRemove);
  }

  // ~~~ ENCRYPTED LABEL TEST ~~~

  function test_Record_EncryptedLabel() public {
    // Simulate a client-side encrypted label (just a hex string for testing)
    string memory _encryptedLabel = '0x7b22656e637279707465644c6162656c223a2274657374227d';

    address[] memory _entities = new address[](1);
    _entities[0] = _entity1;

    string[] memory _labels = new string[](1);
    _labels[0] = _encryptedLabel;

    vm.prank(_safeOwner);
    _registry.record(address(_canonGuard), _entities, _labels);

    ICanonGuardRegistry.Edition memory _edition = _registry.entityLabel(address(_canonGuard), _entity1);
    assertEq(_edition.label, _encryptedLabel);
  }
}

