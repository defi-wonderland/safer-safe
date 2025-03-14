// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SafeEntrypoint} from 'contracts/SafeEntrypoint.sol';

import {SimpleActionsFactory} from 'contracts/actions/factories/SimpleActionsFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {SimpleAction} from 'interfaces/SimpleAction.sol';

import {Safe} from 'safe-contracts/contracts/Safe.sol';
import {SafeProxyFactory} from 'safe-contracts/contracts/proxies/SafeProxyFactory.sol';

contract BasicTest is Test {
  uint256 internal constant _FORK_BLOCK = 18_920_905;
  address internal constant _MULTI_SEND_CALL_ONLY = 0x9641d764fc13c8B624c04430C7356C1C7C8102e2;
  address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address internal constant _OWNER = address(0xc0ffee);

  SimpleAction internal _simpleAction;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), _FORK_BLOCK);
    vm.startPrank(_OWNER);

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
    SafeEntrypoint _safeEntrypoint = new SafeEntrypoint(address(_safe), _MULTI_SEND_CALL_ONLY);

    // Deploy SimpleAction contract
    SimpleActionsFactory _simpleActionsFactory = new SimpleActionsFactory();
    SimpleAction[] memory _simpleActions = new SimpleAction[](2);
    _simpleActions[0] = SimpleAction({target: _WETH, signature: 'deposit()', data: bytes(''), value: 1});

    _simpleActions[1] =
      SimpleAction({target: _OWNER, signature: 'transfer(address,uint256)', data: abi.encode(_OWNER, 1), value: 0});

    address _actionsContract = _simpleActionsFactory.createSimpleActions(_simpleActions);

    // Allow the SafeEntrypoint to call the SimpleAction contract
    _safeEntrypoint.allowActions(address(_actionsContract));

    // Queue the actions
    _safeEntrypoint.queueActions(address(_actionsContract));

    bytes32 _actionsHash = _safeEntrypoint.actionsHash(_actionsContract);

    // Execute the actions
    vm.warp(block.timestamp + 1 hours);

    bytes32 _safeActionsHash = _safeEntrypoint.getSafeTxHash(_actionsContract);
    _safe.approveHash(_safeActionsHash);

    vm.deal(_OWNER, 1 ether);
    _safeEntrypoint.executeActions{value: 1}(_actionsHash);
  }

  function test_executeActions() public {}
}
