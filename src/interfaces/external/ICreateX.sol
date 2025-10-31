// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ICreateX
 * @notice Interface for the CreateX contract
 */
interface ICreateX {
  /**
   * @notice Deploys a new contract using CREATE3
   * @param _salt The salt for the deployment
   * @param _initCode The init code for the deployment
   * @return _newContract The address of the new contract
   */
  function deployCreate3(bytes32 _salt, bytes memory _initCode) external payable returns (address _newContract);

  /**
   * @notice Deploys a new contract using CREATE2
   * @param _salt The salt for the deployment
   * @param _initCode The init code for the deployment
   * @return _newContract The address of the new contract
   */
  function deployCreate2(bytes32 _salt, bytes memory _initCode) external payable returns (address _newContract);

  /**
   * @notice Computes the address of a contract deployed using CREATE3
   * @param _salt The salt for the deployment
   * @return _computedAddress The computed address
   */
  function computeCreate3Address(bytes32 _salt) external pure returns (address _computedAddress);

  /**
   * @notice Computes the address of a contract deployed using CREATE2
   * @param _salt The salt for the deployment
   * @param _initCodeHash The init code hash
   * @return _computedAddress The computed address
   */
  function computeCreate2Address(bytes32 _salt, bytes32 _initCodeHash) external pure returns (address _computedAddress);
}
