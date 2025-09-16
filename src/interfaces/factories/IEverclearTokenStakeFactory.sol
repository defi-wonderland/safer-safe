// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IEverclearTokenStakeFactory
 * @notice Interface for the EverclearTokenStakeFactory contract
 */
interface IEverclearTokenStakeFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates an EverclearTokenStake contract
   * @param _vestingEscrow The VestingEscrow contract address
   * @param _vestingWallet The VestingWallet contract address
   * @param _spokeBridge The SpokeBridge contract address
   * @param _clearLockbox The ClearLockbox contract address
   * @param _next The NEXT contract address
   * @param _clear The CLEAR contract address
   * @param _safe The Gnosis Safe contract address
   * @param _lockTime The lock time
   * @return _everclearTokenStake The EverclearTokenStake contract address
   */
  function createEverclearTokenStake(
    address _vestingEscrow,
    address _vestingWallet,
    address _spokeBridge,
    address _clearLockbox,
    address _next,
    address _clear,
    address _safe,
    uint256 _lockTime
  ) external returns (address _everclearTokenStake);
}
