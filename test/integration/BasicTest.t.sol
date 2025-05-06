// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';

import {SafeEntrypoint} from 'contracts/SafeEntrypoint.sol';
import {SafeEntrypointFactory} from 'contracts/factories/SafeEntrypointFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';

import {ISimpleActions} from 'interfaces/actions/ISimpleActions.sol';

import {Safe} from '@safe-smart-account/Safe.sol';
import {SafeProxyFactory} from '@safe-smart-account/proxies/SafeProxyFactory.sol';

contract BasicTest is Test {
  uint256 internal constant _FORK_BLOCK = 18_920_905;
  address internal constant _MULTI_SEND_CALL_ONLY = 0x9641d764fc13c8B624c04430C7356C1C7C8102e2;
  address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address internal constant _OWNER = address(0xc0ffee);

  ISimpleActions.SimpleAction internal _simpleAction;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), _FORK_BLOCK);

    // Deploy the Safe contract
    address[] memory _owners = new address[](1);
    _owners[0] = _OWNER;

    address _safeProxyFactory = address(new SafeProxyFactory());
    address _safeSingleton = address(new Safe());

    address _safeProxy = address(SafeProxyFactory(_safeProxyFactory).createProxyWithNonce(_safeSingleton, bytes(''), 1));

    Safe _safe = Safe(payable(_safeProxy));

    _safe.setup({
      _owners: _owners,
      _threshold: 1,
      to: address(0),
      data: bytes(''),
      fallbackHandler: address(0),
      paymentToken: address(0),
      payment: 0,
      paymentReceiver: payable(address(0))
    });

    // Deploy the SafeEntrypoint contract
    uint256 _shortExecutionDelay = 1 hours;
    uint256 _longExecutionDelay = 7 days;

    SafeEntrypointFactory _safeEntrypointFactory = new SafeEntrypointFactory(_MULTI_SEND_CALL_ONLY);
    SafeEntrypoint _safeEntrypoint = SafeEntrypoint(
      _safeEntrypointFactory.createSafeEntrypoint(address(_safe), _shortExecutionDelay, _longExecutionDelay)
    );

    // Deploy SimpleAction contract
    ISimpleActions.SimpleAction[] memory _simpleActions = new ISimpleActions.SimpleAction[](2);
    _simpleActions[0] = ISimpleActions.SimpleAction({target: _WETH, signature: 'deposit()', data: bytes(''), value: 1});
    _simpleActions[1] = ISimpleActions.SimpleAction({
      target: _WETH,
      signature: 'transfer(address,uint256)',
      data: abi.encode(_OWNER, 1),
      value: 0
    });

    SimpleActionsFactory _simpleActionsFactory = new SimpleActionsFactory();
    address _actionsBuilder = _simpleActionsFactory.createSimpleActions(_simpleActions);

    // Allow the SafeEntrypoint to call the SimpleActions contract
    uint256 _approvalDuration = block.timestamp + 1 days;

    vm.prank(address(_safe)); // TODO: Replicate Safe transaction without pranking it
    _safeEntrypoint.approveActionsBuilder(_actionsBuilder, _approvalDuration);

    vm.startPrank(_OWNER);

    // Queue the transaction
    address[] memory _actionsBuilders = new address[](1);
    _actionsBuilders[0] = _actionsBuilder;

    uint256 _txId = _safeEntrypoint.queueTransaction(_actionsBuilders);

    // Wait for the timelock period
    vm.warp(block.timestamp + _shortExecutionDelay);

    // Get and approve the Safe transaction hash
    bytes32 _safeTxHash = _safeEntrypoint.getSafeTransactionHash(_txId);
    _safe.approveHash(_safeTxHash);

    // Execute the transaction
    vm.deal(_OWNER, 1 ether);
    _safeEntrypoint.executeTransaction{value: 1}(_txId);
  }

  function test_executeTransaction() public {}
}
