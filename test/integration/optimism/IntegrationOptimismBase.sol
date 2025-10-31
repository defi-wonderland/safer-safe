// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';

import {DeployCanonGuard} from 'script/DeployCanonGuard.s.sol';

import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {OptimismConstants} from 'script/Constants.sol';

abstract contract IntegrationOptimismBase is DeployCanonGuard, OptimismConstants, Test {
  uint256 internal constant _OPTIMISM_FORK_BLOCK = 122_000_000;

  address internal constant _EMERGENCY_TRIGGER = address(1);
  address internal constant _EMERGENCY_CALLER = address(2);

  address[] internal _safeOwners;
  uint256 internal _safeThreshold;
  uint256 internal _safeBalance;

  ICanonGuard public canonGuard;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('optimism'), _OPTIMISM_FORK_BLOCK);

    // Get the Safe owners
    _safeOwners = SAFE_PROXY.getOwners();
    // Get the Safe threshold
    _safeThreshold = SAFE_PROXY.getThreshold();

    // Set the Safe balances
    _safeBalance = 1 ether;
    deal(address(SAFE_PROXY), _safeBalance);
    deal(address(WETH), address(SAFE_PROXY), _safeBalance);
    deal(address(OP), address(SAFE_PROXY), _safeBalance);
    deal(address(KITE), address(SAFE_PROXY), _safeBalance);
    deal(address(WLD), address(SAFE_PROXY), _safeBalance);

    // Deploy the CanonGuard contract
    run();

    // Deploy the CanonGuard contract
    vm.prank(address(SAFE_PROXY));
    canonGuard = ICanonGuard(
      canonGuardFactory.createCanonGuard(
        address(SAFE_PROXY),
        address(MULTI_SEND_CALL_ONLY),
        SHORT_TX_EXECUTION_DELAY,
        LONG_TX_EXECUTION_DELAY,
        TX_EXPIRY_DELAY,
        MAX_APPROVAL_DURATION,
        _EMERGENCY_TRIGGER,
        _EMERGENCY_CALLER
      )
    );

    // Set the CanonGuard as the Safe guard
    vm.prank(address(SAFE_PROXY));
    SAFE_PROXY.setGuard(address(canonGuard));
  }
}
