// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ISimpleActions
 * @notice Interface for the SimpleActions contract
 */
interface ISimpleActions {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Struct for a simple transaction action
   * @param target The target address of the action (e.g., WETH)
   * @param signature The signature of the action (e.g., "transfer(address,uint256)")
   * @param data The data of the action (i.e., abi.encode(address,uint256))
   * @param value The value of the action (i.e., msg.value)
   */
  struct SimpleAction {
    address target;
    string signature;
    bytes data;
    uint256 value;
  }

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a simple action is added
   * @param _target The target address of the action
   * @param _signature The signature of the action
   * @param _data The data of the action
   * @param _value The value of the action
   */
  event SimpleActionAdded(address indexed _target, string indexed _signature, bytes _data, uint256 _value);
}
