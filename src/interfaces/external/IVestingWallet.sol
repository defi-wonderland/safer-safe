// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IVestingWallet
 * @notice Interface for the VestingWallet contract
 */
interface IVestingWallet {
  /**
   * @notice Claim the vested amount
   * @param _vestingEscrow The vesting escrow address
   */
  function claim(address _vestingEscrow) external;

  /**
   * @notice Release the vested amount
   */
  function release() external;

  /**
   * @notice Get the vested amount
   * @param _timestamp The timestamp
   * @return _amount The vested amount
   */
  function vestedAmount(uint64 _timestamp) external view returns (uint256 _amount);

  /**
   * @notice Get the released amount
   * @return _amount The released amount
   */
  function released() external view returns (uint256 _amount);

  /**
   * @notice Get the releasable amount
   * @return _amount The releasable amount
   */
  function releasable() external view returns (uint256 _amount);
}
