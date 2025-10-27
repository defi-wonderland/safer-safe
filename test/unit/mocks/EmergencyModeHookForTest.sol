// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {EmergencyModeHook} from 'contracts/EmergencyModeHook.sol';

contract EmergencyModeHookForTest is EmergencyModeHook {
  constructor(
    address _emergencyTrigger,
    address _emergencyCaller,
    address _safe
  ) EmergencyModeHook(_emergencyTrigger, _emergencyCaller, _safe) {}

  function forTest_onBeforeExecution() public {
    super._onBeforeExecution();
  }
}
