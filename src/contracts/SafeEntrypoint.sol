// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../interfaces/IActions.sol';
import {SafeManageable} from './SafeManageable.sol';

contract SafeEntrypoint is SafeManageable {
  mapping(address _actionsContract => bool _isAllowed) public allowedActions;
  mapping(bytes32 _actionsHash => uint256 _executableAt) public actionsExecutableAt;
  mapping(bytes32 _actionsHash => bytes _actionsData) public actionsData;

  address public immutable MULTI_SEND_CALL_ONLY;

  error NotExecutable();

  event ActionsQueued(bytes32 actionsHash, uint256 executableAt);
  event ActionsExecuted(bytes32 actionsHash, bytes32 safeTxHash);

  constructor(address _safe, address _multiSend) SafeManageable(_safe) {
    MULTI_SEND_CALL_ONLY = _multiSend;
  }

  function allowActions(address _actionsContract) external isMsig {
    allowedActions[_actionsContract] = true;
  }

  function disallowActions(address _actionsContract) external isAuthorized {
    allowedActions[_actionsContract] = false;
  }

  function queueActions(address actionsContract) external isAuthorized {
    IActions.Action[] memory actions = IActions(actionsContract).getActions();

    bytes32 actionsHash = keccak256(abi.encode(actions));

    uint256 actionsDelay;
    if (allowedActions[actionsContract]) {
      actionsDelay = 1 hours;
    } else {
      actionsDelay = 7 days;
    }

    uint256 _executableAt = block.timestamp + actionsDelay;
    actionsExecutableAt[actionsHash] = _executableAt;
    actionsData[actionsHash] = abi.encode(actions);

    // NOTE: event picked up by off-chain monitoring service
    emit ActionsQueued(actionsHash, _executableAt);
  }

  function executeActions(bytes32 _actionsHash, address[] memory _signers) external payable {
    _executeActions(_actionsHash, _signers);
  }

  function executeActions(bytes32 _actionsHash) external payable {
    _executeActions(_actionsHash, _getApprovedSigners(_actionsHash));
  }

  function _executeActions(bytes32 _actionsHash, address[] memory _signers) internal {
    if (actionsExecutableAt[_actionsHash] > block.timestamp) revert NotExecutable();

    IActions.Action[] memory _actions = abi.decode(actionsData[_actionsHash], (IActions.Action[]));

    bytes memory _multiSendData = _parseMultiSendData(_actions);
    address[] memory _sortedSigners = _sortSigners(_signers);
    bytes memory _signatures = _parseSignatures(_sortedSigners);

    // NOTE: only for event logging
    uint256 _nonce = SAFE.nonce();
    bytes32 _safeTxHash = _getSafeTxHash(_multiSendData, _nonce);
    _execSafeTx(_multiSendData, _signatures);

    // NOTE: event emitted in simulation to facilitate safeTxHash for approval
    emit ActionsExecuted(_actionsHash, _safeTxHash);
  }

  function getSafeTxHash(bytes32 _actionsHash) external view returns (bytes32) {
    return _getSafeTxHash(actionsData[_actionsHash], SAFE.nonce());
  }

  function getSafeTxHash(bytes32 _actionsHash, uint256 _nonce) external view returns (bytes32) {
    return _getSafeTxHash(actionsData[_actionsHash], _nonce);
  }

  function simulateActions(address _actionsContract) external payable {
    IActions.Action[] memory _actions = IActions(_actionsContract).getActions();

    bytes32 _actionsHash = keccak256(abi.encode(_actions));
    bytes memory _multiSendData = _parseMultiSendData(_actions);
    // NOTE: tx will fail unless number of signers is 0
    bytes memory _emptySignatures = _parseSignatures(new address[](0));

    uint256 _nonce = SAFE.nonce();
    bytes32 _safeTxHash = _getSafeTxHash(_multiSendData, _nonce);
    _execSafeTx(_multiSendData, _emptySignatures);

    // NOTE: event emitted in simulation to facilitate safeTxHash for approval
    emit ActionsExecuted(_actionsHash, _safeTxHash);
  }

  function _parseMultiSendData(IActions.Action[] memory _actions) internal pure returns (bytes memory _multiSendData) {
    // Loop through each action and encode it
    for (uint256 i = 0; i < _actions.length; i++) {
      // Extract the current action
      IActions.Action memory action = _actions[i];

      // For each action, we encode:
      // 1 byte: operation (0 = Call, 1 = DelegateCall) - using 0 (Call) by default
      // 20 bytes: target address
      // 32 bytes: ether value
      // 32 bytes: data length
      // N bytes: data payload

      // Encode each action using abi.encodePacked to avoid padding
      bytes memory encodedAction = abi.encodePacked(
        uint8(0), // operation (0 = Call)
        action.target, // target address
        action.value, // ether value
        uint256(action.data.length), // data length
        action.data // data payload
      );

      // Append the encoded action to the multiSendData
      _multiSendData = abi.encodePacked(_multiSendData, encodedAction);
    }

    return _multiSendData;
  }

  function _sortSigners(address[] memory _signers) internal pure returns (address[] memory) {
    for (uint256 i = 0; i < _signers.length; i++) {
      for (uint256 j = 0; j < _signers.length - i - 1; j++) {
        // If the current element is greater than the next element, swap them
        if (_signers[j] > _signers[j + 1]) {
          // Swap elements
          address temp = _signers[j];
          _signers[j] = _signers[j + 1];
          _signers[j + 1] = temp;
        }
      }
    }

    return _signers;
  }

  function getApprovedSigners(bytes32 _txHash) external view returns (address[] memory _approvedSigners) {
    return _getApprovedSigners(_txHash);
  }

  function _getApprovedSigners(bytes32 _txHash) internal view returns (address[] memory _approvedSigners) {
    address[] memory _signers = SAFE.getOwners();

    // Create a temporary array to store approved signers
    address[] memory tempApproved = new address[](_signers.length);
    uint256 approvedCount = 0;

    // Single pass through all signers
    for (uint256 i = 0; i < _signers.length; i++) {
      // Check if this signer has approved the hash
      if (SAFE.approvedHashes(_signers[i], _txHash)) {
        tempApproved[approvedCount] = _signers[i];
        approvedCount++;
      }
    }

    // Create the final result array with the exact size needed
    _approvedSigners = new address[](approvedCount);

    // Copy from temporary array to final array
    for (uint256 i = 0; i < approvedCount; i++) {
      _approvedSigners[i] = tempApproved[i];
    }

    return _approvedSigners;
  }

  function _parseSignatures(address[] memory _signers) internal pure returns (bytes memory _signatures) {
    // For approved hash validation, we need to create signatures with:
    // v = 1 (indicating approved hash validation)
    // r = address of the signer (converted to bytes32)
    // s = 0 (not used for approved hash validation)

    // Each signature takes 65 bytes (r = 32 bytes, s = 32 bytes, v = 1 byte)
    _signatures = new bytes(_signers.length * 65);

    // Fill the signatures bytes with the proper format for each signer
    for (uint256 i = 0; i < _signers.length; i++) {
      address signer = _signers[i];

      // Calculate the offset for this signature
      uint256 offset = i * 65;

      // Store the address of the signer in the r value (bytes 0-31)
      bytes32 r = bytes32(uint256(uint160(signer)));

      // s value is not used for approved hash validation (bytes 32-63)
      bytes32 s = bytes32(0);

      // v value = 1 indicates this is an approved hash signature (byte 64)
      uint8 v = 1;

      // Place values in the signatures array
      assembly {
        mstore(add(add(_signatures, 32), offset), r)
        mstore(add(add(_signatures, 64), offset), s)
        mstore8(add(add(_signatures, 96), offset), v)
      }
    }

    return _signatures;
  }

  function _getSafeTxHash(bytes memory _data, uint256 _nonce) internal view returns (bytes32) {
    return SAFE.getTransactionHash({
      to: MULTI_SEND_CALL_ONLY,
      value: 0,
      data: _data,
      operation: 1, // DELEGATE_CALL
      safeTxGas: 0,
      baseGas: 0,
      gasPrice: 0,
      gasToken: address(0),
      refundReceiver: payable(address(this)),
      _nonce: _nonce
    });
  }

  function _execSafeTx(bytes memory _data, bytes memory _signatures) internal {
    SAFE.execTransaction{value: msg.value}({
      to: MULTI_SEND_CALL_ONLY,
      value: msg.value,
      data: _data,
      operation: 1, // DELEGATE_CALL
      safeTxGas: 0,
      baseGas: 0,
      gasPrice: 0,
      gasToken: address(0),
      refundReceiver: payable(address(this)),
      signatures: _signatures
    });
  }
}
