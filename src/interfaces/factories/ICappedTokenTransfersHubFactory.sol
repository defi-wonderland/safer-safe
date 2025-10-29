// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ICappedTokenTransfersHubFactory
 * @notice Interface for the CappedTokenTransfersHubFactory contract
 */
interface ICappedTokenTransfersHubFactory {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a new CappedTokenTransfersHub contract is created
   * @param _cappedTokenTransfersHub The address of the created CappedTokenTransfersHub contract
   * @param _safe The Gnosis Safe contract address
   * @param _recipient The recipient of the token transfers
   */
  event CappedTokenTransfersHubCreated(
    address indexed _cappedTokenTransfersHub, address indexed _safe, address indexed _recipient
  );

  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a CappedTokenTransfersHub contract
   * @param _safe The Gnosis Safe contract address
   * @param _recipient The recipient of the token transfers
   * @param _tokens The tokens to transfer
   * @param _caps The caps for the token transfers
   * @param _epochLength The epoch length for the token transfers
   * @return _cappedTokenTransfersHub The CappedTokenTransfersHub contract address
   */
  function createCappedTokenTransfersHub(
    address _safe,
    address _recipient,
    address[] memory _tokens,
    uint256[] memory _caps,
    uint256 _epochLength
  ) external returns (address _cappedTokenTransfersHub);
}
