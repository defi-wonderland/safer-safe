// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';

abstract contract Utils is Test {
  function _getNextContractDeployedAddress(address _deployer) internal view returns (address) {
    return vm.computeCreateAddress(_deployer, vm.getNonce(_deployer));
  }
}
