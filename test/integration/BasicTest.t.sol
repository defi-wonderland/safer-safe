// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';

import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';

import {DeployCanonGuardFactories} from 'script/DeployCanonGuardFactories.s.sol';

import {EthereumConstants} from 'script/Constants.sol';

contract IntegrationBasicTest is DeployCanonGuardFactories, EthereumConstants, Test {
  uint256 internal constant _ETHEREUM_FORK_BLOCK = 18_920_905;

  // ~~~ SAFE ~~~
  ISafe internal _safeProxy;
  address internal _safeOwner;
  uint256 internal _safeThreshold;

  // ~~~ CANON_GUARD ~~~
  ICanonGuard internal _canonGuard;

  // ~~~ ACTIONS ~~~
  address internal _actionsBuilder;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('ethereum'), _ETHEREUM_FORK_BLOCK);

    // Deploy the SafeProxy contract
    _safeProxy = ISafe(address(SAFE_PROXY_FACTORY.createProxyWithNonce(address(SAFE), bytes(''), 1)));

    _safeOwner = makeAddr('safeOwner');
    vm.deal(_safeOwner, 1 ether);

    address[] memory _safeOwners = new address[](1);
    _safeOwners[0] = _safeOwner;
    _safeThreshold = 1;

    _safeProxy.setup({
      _owners: _safeOwners,
      _threshold: _safeThreshold,
      to: address(0),
      data: bytes(''),
      fallbackHandler: address(0),
      paymentToken: address(0),
      payment: 0,
      paymentReceiver: payable(address(0))
    });

    // Deploy the CanonGuard factory contracts
    deployCanonGuardFactories();

    // Deploy the CanonGuard contract
    _canonGuard = ICanonGuard(
      canonGuardFactory.createCanonGuard(
        address(_safeProxy),
        SHORT_TX_EXECUTION_DELAY,
        LONG_TX_EXECUTION_DELAY,
        TX_EXPIRY_DELAY,
        MAX_APPROVAL_DURATION,
        EMERGENCY_TRIGGER,
        EMERGENCY_CALLER
      )
    );

    vm.prank(address(_safeProxy));
    _safeProxy.setGuard(address(_canonGuard));

    // Deploy the SimpleActions contract
    ISimpleActions.SimpleAction memory _depositAction =
      ISimpleActions.SimpleAction({target: address(WETH), signature: 'deposit()', data: bytes(''), value: 1});
    ISimpleActions.SimpleAction memory _transferAction = ISimpleActions.SimpleAction({
      target: address(WETH),
      signature: 'transfer(address,uint256)',
      data: abi.encode(_safeOwner, 1),
      value: 0
    });

    ISimpleActions.SimpleAction[] memory _simpleActions = new ISimpleActions.SimpleAction[](2);
    _simpleActions[0] = _depositAction;
    _simpleActions[1] = _transferAction;

    _actionsBuilder = simpleActionsFactory.createSimpleActions(_simpleActions);
  }

  function test_ExecuteTransaction() public {
    // Allow the CanonGuard to call the SimpleActions contract
    uint256 _approvalDuration = 1 days;

    vm.prank(address(_safeProxy));
    _canonGuard.approveActionsBuilderOrHub(_actionsBuilder, _approvalDuration);

    vm.startPrank(_safeOwner);

    // Queue the transaction
    _canonGuard.queueTransaction(_actionsBuilder);

    // Wait for the timelock period
    vm.warp(block.timestamp + SHORT_TX_EXECUTION_DELAY);

    // Get and approve the Safe transaction hash
    bytes32 _safeTxHash = _canonGuard.getSafeTransactionHash(_actionsBuilder);
    _safeProxy.approveHash(_safeTxHash);

    // Execute the transaction
    _canonGuard.executeTransaction{value: 1}(_actionsBuilder);
  }
}
