// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISimpleTransfers} from 'interfaces/actions-builders/ISimpleTransfers.sol';

/**
 * @title ISimpleTransfersFactory
 * @notice Interface for the SimpleTransfersFactory contract
 */
interface ISimpleTransfersFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a SimpleTransfers contract
   * @dev In Etherscan interface, the transaction should be parsed as follows:
   * Describing a WETH.transfer(address(0xc0ffee), 1)
   *  [
   *    [
   *      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
   *      "0x0000000000000000000000000000000000C0FFEE",
   *      "1"
   *    ]
   *  ]
   * @param _transferActions The array of transfer actions
   * @return _simpleTransfers The SimpleTransfers contract address
   */
  function createSimpleTransfers(ISimpleTransfers
        .TransferAction[] memory _transferActions) external returns (address _simpleTransfers);

  /**
   * @notice Creates a SimpleTransfers contract with a single transfer action
   * @dev In Etherscan interface, the transaction should be parsed as follows:
   * Describing a WETH.transfer(address(0xc0ffee), 1):
   *  "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
   *  "0x0000000000000000000000000000000000C0FFEE",
   *  "1"
   * @param _transferAction The transfer action
   * @return _simpleTransfers The SimpleTransfers contract address
   */
  function createSimpleTransfer(
    ISimpleTransfers.TransferAction memory _transferAction
  ) external returns (address _simpleTransfers);
}
