// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Script} from 'forge-std/Script.sol';

contract Deploy is Script {
  function setUp() public {}

  function run() public {
    vm.startBroadcast();
    vm.stopBroadcast();
  }
}
