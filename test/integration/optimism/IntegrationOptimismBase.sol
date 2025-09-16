// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';

import {DeployCanonGuard} from 'script/DeployCanonGuard.s.sol';
import {DeployCanonGuardFactories} from 'script/DeployCanonGuardFactories.s.sol';

import {OptimismConstants} from 'script/Constants.sol';

abstract contract IntegrationOptimismBase is DeployCanonGuardFactories, DeployCanonGuard, OptimismConstants, Test {
  uint256 internal constant _OPTIMISM_FORK_BLOCK = 122_000_000;

  address[] internal _safeOwners;
  uint256 internal _safeThreshold;
  uint256 internal _safeBalance;

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

    // Deploy the CanonGuard factory contracts
    deployCanonGuardFactories();

    // Deploy the CanonGuard contract
    deployCanonGuard();

    // Set the CanonGuard as the Safe guard
    vm.prank(address(SAFE_PROXY));
    SAFE_PROXY.setGuard(address(canonGuard));
  }
}
