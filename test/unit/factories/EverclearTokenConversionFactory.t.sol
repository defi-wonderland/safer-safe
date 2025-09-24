// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {EverclearTokenConversionFactory} from 'src/contracts/factories/EverclearTokenConversionFactory.sol';
import {IEverclearTokenConversion} from 'src/interfaces/actions-builders/IEverclearTokenConversion.sol';

contract UnitEverclearTokenConversionFactorycreateEverclearTokenConversion is Test {
  EverclearTokenConversionFactory public everclearTokenConversionFactory;
  IEverclearTokenConversion public auxEverclearTokenConversion;

  function setUp() external {
    everclearTokenConversionFactory = new EverclearTokenConversionFactory();
  }

  function test_WhenCalled(address _lockbox, address _next) external {
    address _everclearTokenConversion = everclearTokenConversionFactory.createEverclearTokenConversion(_lockbox, _next);
    auxEverclearTokenConversion = IEverclearTokenConversion(
      deployCode('EverclearTokenConversion', abi.encode(address(everclearTokenConversionFactory), _lockbox, _next))
    );

    // it should deploy a EverclearTokenConversion
    assertEq(address(auxEverclearTokenConversion).code, _everclearTokenConversion.code);

    // it should match the parameters sent to the constructor
    assertEq(address(auxEverclearTokenConversion.CLEAR_LOCKBOX()), _lockbox);
    assertEq(address(auxEverclearTokenConversion.NEXT()), _next);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_everclearTokenConversion).PARENT(), address(everclearTokenConversionFactory));

    // it should store the contract as a factory children
    assertTrue(everclearTokenConversionFactory.isChild(_everclearTokenConversion));
  }
}
