// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Script} from 'forge-std/Script.sol';

import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';

import {CanonGuardFactory} from 'contracts/factories/CanonGuardFactory.sol';
import {CappedTokenTransfersHubFactory} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';

import {IAllowanceClaimorFactory} from 'interfaces/factories/IAllowanceClaimorFactory.sol';

import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';
import {ICappedTokenTransfersHubFactory} from 'interfaces/factories/ICappedTokenTransfersHubFactory.sol';
import {ISimpleActionsFactory} from 'interfaces/factories/ISimpleActionsFactory.sol';
import {ISimpleTransfersFactory} from 'interfaces/factories/ISimpleTransfersFactory.sol';

import {Constants} from 'script/Constants.sol';

contract DeployCanonGuardFactories is Constants, Script {
  // ~~~ FACTORIES ~~~
  ICanonGuardFactory public canonGuardFactory;
  IAllowanceClaimorFactory public allowanceClaimorFactory;
  ICappedTokenTransfersHubFactory public cappedTokenTransfersHubFactory;
  ISimpleActionsFactory public simpleActionsFactory;
  ISimpleTransfersFactory public simpleTransfersFactory;

  function deployCanonGuardFactories() public {
    vm.startBroadcast();

    // Deploy the CanonGuardFactory contract
    canonGuardFactory = new CanonGuardFactory(address(MULTI_SEND_CALL_ONLY));

    // Deploy the AllowanceClaimorFactory contract
    allowanceClaimorFactory = new AllowanceClaimorFactory();
    // Deploy the CappedTokenTransfersFactory contract
    cappedTokenTransfersHubFactory = new CappedTokenTransfersHubFactory();
    // Deploy the SimpleActionsFactory contract
    simpleActionsFactory = new SimpleActionsFactory();
    // Deploy the SimpleTransfersFactory contract
    simpleTransfersFactory = new SimpleTransfersFactory();

    vm.stopBroadcast();
  }
}
