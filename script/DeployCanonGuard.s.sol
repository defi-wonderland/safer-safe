// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from 'forge-std/Script.sol';

import {ICanonGuard} from 'interfaces/ICanonGuard.sol';

import {Constants} from 'script/Constants.sol';

/**
 * @title DeployCanonGuard
 * @notice Script that deploys the CanonGuard contract based on the constants in Constants.sol
 */
contract DeployCanonGuard is Constants, Script {
  // ~~~ CANON GUARD ~~~
  ICanonGuard public canonGuard;

  /**
   * @notice Deploys the CanonGuard contract
   */
  function deployCanonGuard() public {
    vm.startBroadcast();

    // Deploy the CanonGuard contract
    canonGuard = ICanonGuard(
      CANON_GUARD_FACTORY.createCanonGuard(
        address(SAFE_PROXY),
        SHORT_TX_EXECUTION_DELAY,
        LONG_TX_EXECUTION_DELAY,
        TX_EXPIRY_DELAY,
        MAX_APPROVAL_DURATION,
        EMERGENCY_TRIGGER,
        EMERGENCY_CALLER
      )
    );

    vm.stopBroadcast();
  }
}
