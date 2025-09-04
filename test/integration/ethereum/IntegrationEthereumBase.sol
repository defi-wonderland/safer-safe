// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';

import {DeployCanonGuard} from 'script/DeployCanonGuard.s.sol';
import {DeployCanonGuardFactories} from 'script/DeployCanonGuardFactories.s.sol';

import {EthereumConstants} from 'script/Constants.sol';

abstract contract IntegrationEthereumBase is DeployCanonGuardFactories, DeployCanonGuard, EthereumConstants, Test {
  uint256 internal constant _ETHEREUM_FORK_BLOCK = 22_000_000;

  address[] internal _safeOwners;
  uint256 internal _safeThreshold;
  uint256 internal _safeBalance;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('ethereum'), _ETHEREUM_FORK_BLOCK);

    // Get the Safe owners
    _safeOwners = SAFE_PROXY.getOwners();
    // Get the Safe threshold
    _safeThreshold = SAFE_PROXY.getThreshold();

    // Set the Safe balances
    _safeBalance = 1 ether;
    deal(address(SAFE_PROXY), _safeBalance);
    deal(address(WETH), address(SAFE_PROXY), _safeBalance);
    deal(address(USDC), address(SAFE_PROXY), _safeBalance);
    deal(address(USDT), address(SAFE_PROXY), _safeBalance);
    deal(address(USDS), address(SAFE_PROXY), _safeBalance);
    deal(address(DAI), address(SAFE_PROXY), _safeBalance);
    deal(address(L3), address(SAFE_PROXY), _safeBalance);
    deal(address(GRT), address(SAFE_PROXY), _safeBalance);
    deal(address(GTC), address(SAFE_PROXY), _safeBalance);
    deal(address(CLEAR), address(SAFE_PROXY), _safeBalance);
    deal(address(NEXT), address(SAFE_PROXY), _safeBalance);
    deal(address(BAL), address(SAFE_PROXY), _safeBalance);
    deal(address(EIGEN), address(SAFE_PROXY), _safeBalance);
    deal(address(KP3R), address(SAFE_PROXY), _safeBalance);

    // Deploy the CanonGuard factory contracts
    deployCanonGuardFactories();

    // Deploy the CanonGuard contract
    deployCanonGuard();

    // Set the CanonGuard as the Safe guard
    vm.prank(address(SAFE_PROXY));
    SAFE_PROXY.setGuard(address(canonGuard));
  }
}
