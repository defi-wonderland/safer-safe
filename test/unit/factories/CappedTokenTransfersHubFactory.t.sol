// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {CappedTokenTransfersHubFactory} from 'src/contracts/factories/CappedTokenTransfersHubFactory.sol';
import {IActionHub} from 'src/interfaces/action-hubs/IActionHub.sol';
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
      assertEq(ICappedTokenTransfersHub(hub).cap(tokens[i]), caps[i]);
      assertEq(ICappedTokenTransfersHub(hub).tokens()[i], tokens[i]);
    }

    // it should set the parent address in the child contract
    assertEq(IActionHub(hub).PARENT(), address(cappedTokenTransfersHubFactory));

    // it should store the contract as a factory children
    assertTrue(cappedTokenTransfersHubFactory.isChild(hub));
  }
}
