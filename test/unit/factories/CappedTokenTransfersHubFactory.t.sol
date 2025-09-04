// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {CappedTokenTransfersHubFactory} from 'src/contracts/factories/CappedTokenTransfersHubFactory.sol';
import {ICappedTokenTransfersHub} from 'src/interfaces/action-hubs/ICappedTokenTransfersHub.sol';

contract UnitCappedTokenTransfersHubFactorycreateCappedTokenTransfersHub is Test {
  CappedTokenTransfersHubFactory public cappedTokenTransfersHubFactory;
  address public safe;
  address public recipient;
  address[] public tokens;
  uint256[] public caps;
  uint256 public epochLength;

  function setUp() external {
    cappedTokenTransfersHubFactory = new CappedTokenTransfersHubFactory();
    safe = makeAddr('safe');
    recipient = makeAddr('recipient');

    tokens.push(makeAddr('token'));
    caps.push(100 ether);
    epochLength = 100;
  }

  function test_WhenCalled() external {
    address hub =
      cappedTokenTransfersHubFactory.createCappedTokenTransfersHub(safe, recipient, tokens, caps, epochLength);

    // it creates a new CappedTokenTransfersHub
    assertEq(address(ICappedTokenTransfersHub(hub).SAFE()), safe);
    assertEq(ICappedTokenTransfersHub(hub).RECIPIENT(), recipient);
    assertEq(ICappedTokenTransfersHub(hub).EPOCH_LENGTH(), epochLength);
    for (uint256 i = 0; i < caps.length; i++) {
      assertEq(ICappedTokenTransfersHub(hub).caps()[i], caps[i]);
      assertEq(ICappedTokenTransfersHub(hub).tokens()[i], tokens[i]);
    }
  }
}
