// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Script} from 'forge-std/Script.sol';

import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {ApproveActionFactory} from 'contracts/factories/ApproveActionFactory.sol';
import {
  CappedTokenTransfersHub,
  CappedTokenTransfersHubFactory
} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {SafeEntrypointFactory} from 'contracts/factories/SafeEntrypointFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {ISimpleTransfers, SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';

import {IAllowanceClaimorFactory} from 'interfaces/factories/IAllowanceClaimorFactory.sol';
import {IApproveActionFactory} from 'interfaces/factories/IApproveActionFactory.sol';
import {ICappedTokenTransfersHubFactory} from 'interfaces/factories/ICappedTokenTransfersHubFactory.sol';
import {ISafeEntrypointFactory} from 'interfaces/factories/ISafeEntrypointFactory.sol';
import {ISimpleActionsFactory} from 'interfaces/factories/ISimpleActionsFactory.sol';
import {ISimpleTransfersFactory} from 'interfaces/factories/ISimpleTransfersFactory.sol';

import {Constants} from 'script/Constants.sol';

contract DeploySaferSafe is Constants, Script {
  // ~~~ FACTORIES ~~~
  ISafeEntrypointFactory public safeEntrypointFactory;
  IAllowanceClaimorFactory public allowanceClaimorFactory;
  IApproveActionFactory public approveActionFactory;
  ICappedTokenTransfersHubFactory public cappedTokenTransfersHubFactory;
  ISimpleActionsFactory public simpleActionsFactory;
  ISimpleTransfersFactory public simpleTransfersFactory;

  function deploySaferSafe() public {
    vm.startBroadcast();

    // // Deploy the SafeEntrypointFactory contract
    // safeEntrypointFactory = new SafeEntrypointFactory(address(MULTI_SEND_CALL_ONLY));

    // // Deploy the AllowanceClaimorFactory contract
    // allowanceClaimorFactory = new AllowanceClaimorFactory();
    // // Deploy the ApproveActionFactory contract
    // approveActionFactory = new ApproveActionFactory();
    // Deploy the CappedTokenTransfersFactory contract
    cappedTokenTransfersHubFactory = new CappedTokenTransfersHubFactory();

    address[] memory _tokens = new address[](1);
    _tokens[0] = 0xBad58e133138549936D2576ebC33251bE841d3e9;

    uint256[] memory _caps = new uint256[](1);
    _caps[0] = 1;

    address CTT = cappedTokenTransfersHubFactory.createCappedTokenTransfersHub({
      _safe: 0x3935C871e4f33EfE65400A010954024Ed3E352f2,
      _recipient: 0xBad58e133138549936D2576ebC33251bE841d3e9,
      _tokens: _tokens,
      _caps: _caps,
      _epochLength: 1
    });

    CappedTokenTransfersHub(CTT).createNewActionBuilder(0xBad58e133138549936D2576ebC33251bE841d3e9, 1);
    // // Deploy the SimpleActionsFactory contract
    // simpleActionsFactory = new SimpleActionsFactory();
    // // Deploy the SimpleTransfersFactory contract
    // simpleTransfersFactory = new SimpleTransfersFactory();

    vm.stopBroadcast();
  }
}
