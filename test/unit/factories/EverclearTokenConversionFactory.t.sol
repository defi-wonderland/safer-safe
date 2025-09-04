// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {EverclearTokenConversionFactory} from 'src/contracts/factories/EverclearTokenConversionFactory.sol';
import {IEverclearTokenConversion} from 'src/interfaces/actions-builders/IEverclearTokenConversion.sol';

contract UnitEverclearTokenConversionFactorycreateEverclearTokenConversion is Test {
  EverclearTokenConversionFactory public everclearTokenConversionFactory;
  IEverclearTokenConversion public auxEverclearTokenConversion;

  function setUp() external {
    everclearTokenConversionFactory = new EverclearTokenConversionFactory();
  }

  function test_WhenCalled(address _lockbox, address _next, address _safe) external {
    address _everclearTokenConversion =
      everclearTokenConversionFactory.createEverclearTokenConversion(_lockbox, _next, _safe);
    auxEverclearTokenConversion =
      IEverclearTokenConversion(deployCode('EverclearTokenConversion', abi.encode(_lockbox, _next, _safe)));

    // it should deploy a EverclearTokenConversion
    assertEq(address(auxEverclearTokenConversion).code, _everclearTokenConversion.code);

    // it should match the parameters sent to the constructor
    assertEq(address(auxEverclearTokenConversion.CLEAR_LOCKBOX()), _lockbox);
    assertEq(address(auxEverclearTokenConversion.NEXT()), _next);
    assertEq(address(auxEverclearTokenConversion.SAFE()), _safe);

    // it should store the contract as children
    assertTrue(everclearTokenConversionFactory.isChild(_everclearTokenConversion));
  }
}
