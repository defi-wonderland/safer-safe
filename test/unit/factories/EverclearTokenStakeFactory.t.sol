// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {EverclearTokenStakeFactory} from 'src/contracts/factories/EverclearTokenStakeFactory.sol';
import {IEverclearTokenStake} from 'src/interfaces/actions-builders/IEverclearTokenStake.sol';

contract UnitEverclearTokenStakeFactorycreateEverclearTokenStake is Test {
  EverclearTokenStakeFactory public everclearTokenStakeFactory;
  IEverclearTokenStake public auxEverclearTokenStake;

  function setUp() external {
    everclearTokenStakeFactory = new EverclearTokenStakeFactory();
  }

  function test_WhenCalled(
    address _vestingEscrow,
    address _vestingWallet,
    address _spokeBridge,
    address _clearLockbox,
    address _next,
    address _clear,
    address _safe,
    uint256 _lockTime
  ) external {
    address _everclearTokenStake = everclearTokenStakeFactory.createEverclearTokenStake(
      _vestingEscrow, _vestingWallet, _spokeBridge, _clearLockbox, _next, _clear, _safe, _lockTime
    );

    auxEverclearTokenStake = IEverclearTokenStake(
      deployCode(
        'EverclearTokenStake',
        abi.encode(
          address(everclearTokenStakeFactory),
          _vestingEscrow,
          _vestingWallet,
          _spokeBridge,
          _clearLockbox,
          _next,
          _clear,
          _safe,
          _lockTime
        )
      )
    );
    // it should deploy a EverclearTokenStake
    assertEq(address(auxEverclearTokenStake).code, _everclearTokenStake.code);

    // it should match the parameters sent to the constructor
    assertEq(address(IEverclearTokenStake(_everclearTokenStake).VESTING_ESCROW()), _vestingEscrow);
    assertEq(address(IEverclearTokenStake(_everclearTokenStake).VESTING_WALLET()), _vestingWallet);
    assertEq(address(IEverclearTokenStake(_everclearTokenStake).SPOKE_BRIDGE()), _spokeBridge);
    assertEq(address(IEverclearTokenStake(_everclearTokenStake).CLEAR_LOCKBOX()), _clearLockbox);
    assertEq(address(IEverclearTokenStake(_everclearTokenStake).NEXT()), _next);
    assertEq(address(IEverclearTokenStake(_everclearTokenStake).CLEAR()), _clear);
    assertEq(address(IEverclearTokenStake(_everclearTokenStake).SAFE()), _safe);
    assertEq(IEverclearTokenStake(_everclearTokenStake).LOCK_TIME(), _lockTime);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_everclearTokenStake).PARENT(), address(everclearTokenStakeFactory));

    // it should store the contract as a factory children
    assertTrue(everclearTokenStakeFactory.isChild(_everclearTokenStake));
  }
}
