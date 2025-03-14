// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {IActions} from '../interfaces/IActions.sol';
import {IMultiSendCallOnly} from '../interfaces/IMultiSendCallOnly.sol';
import {SafeManageable} from './SafeManageable.sol';

contract SafeEntrypoint is SafeManageable {
  address public immutable MULTI_SEND_CALL_ONLY;

  mapping(address _actionsContract => bool _isAllowed) public allowedActions;
  mapping(bytes32 _actionsHash => uint256 _executableAt) public actionsExecutableAt;
  mapping(bytes32 _actionsHash => bytes _actionsData) public actionsData;

  event ActionsQueued(bytes32 actionsHash, uint256 executableAt);
  event ActionsExecuted(bytes32 actionsHash, bytes32 safeTxHash);

  error NotExecutable();
  error NotSuccess();

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

    bytes32 _actionsHash = keccak256(abi.encode(actions));

    uint256 actionsDelay;
    if (allowedActions[actionsContract]) {
      actionsDelay = 1 hours;
    } else {
      actionsDelay = 7 days;
    }

    uint256 _executableAt = block.timestamp + actionsDelay;
    actionsExecutableAt[_actionsHash] = _executableAt;
    actionsData[_actionsHash] = abi.encode(actions);

    // NOTE: event picked up by off-chain monitoring service
    emit ActionsQueued(_actionsHash, _executableAt);
  }

  function executeActions(bytes32 _actionsHash, address[] memory _signers) external payable {
    _executeActions(_actionsHash, _signers);
  }

  function executeActions(bytes32 _actionsHash) external payable {
    _executeActions(_actionsHash, _getApprovedSigners(_actionsHash));
  }

  function simulateActions(address _actionsContract) external payable {
    // NOTE: tx will revert so we don't need to staticcall getActions()
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

  function actionsHash(address _actionsContract) external view returns (bytes32) {
    IActions.Action[] memory actions = _simulateGetActions(_actionsContract);
    return keccak256(abi.encode(actions));
  }

  function getSafeTxHash(address _actionsContract) external view returns (bytes32) {
    IActions.Action[] memory _actions = _simulateGetActions(_actionsContract);
    bytes memory _actionsData = _parseMultiSendData(_actions);
    return _getSafeTxHash(_actionsData, SAFE.nonce());
  }

  function getSafeTxHash(bytes32 _actionsHash) external view returns (bytes32) {
    bytes memory _actionsData = _parseMultiSendData(abi.decode(actionsData[_actionsHash], (IActions.Action[])));
    return _getSafeTxHash(_actionsData, SAFE.nonce());
  }

  function getSafeTxHash(bytes32 _actionsHash, uint256 _nonce) external view returns (bytes32) {
    bytes memory _actionsData = _parseMultiSendData(abi.decode(actionsData[_actionsHash], (IActions.Action[])));
    return _getSafeTxHash(_actionsData, _nonce);
  }

  function getApprovedSigners(bytes32 _txHash) external view returns (address[] memory _approvedSigners) {
    return _getApprovedSigners(_txHash);
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

  function _execSafeTx(bytes memory _data, bytes memory _signatures) internal {
    SAFE.execTransaction{value: msg.value}({
      to: MULTI_SEND_CALL_ONLY,
      value: 0,
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

  function _simulateGetActions(address _actionsContract) internal view returns (IActions.Action[] memory actions) {
    // Encode the function call for getActions()
    bytes memory callData = abi.encodeWithSelector(IActions.getActions.selector, bytes(''));

    // Make a static call (executes the code but reverts any state changes)
    bytes memory returnData;
    bool success;
    (success, returnData) = _actionsContract.staticcall(callData);

    // If the call succeeded, decode the returned data
    if (success && returnData.length > 0) {
      actions = abi.decode(returnData, (IActions.Action[]));
    } else {
      revert NotSuccess();
    }

    return actions;
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

  function _getApprovedSigners(bytes32 _actionsHash) internal view returns (address[] memory _approvedSigners) {
    address[] memory _signers = SAFE.getOwners();

    bytes memory _actionsData = _parseMultiSendData(abi.decode(actionsData[_actionsHash], (IActions.Action[])));
    bytes32 _txHash = _getSafeTxHash(_actionsData, SAFE.nonce());

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

  function _parseMultiSendData(IActions.Action[] memory _actions) internal pure returns (bytes memory _multiSendData) {
    // Initialize an empty bytes array to avoid null reference
    _multiSendData = new bytes(0);

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

    _multiSendData = abi.encodeWithSelector(IMultiSendCallOnly.multiSend.selector, _multiSendData);

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

  function _parseSignatures(address[] memory _signers) internal pure returns (bytes memory) {
    // Each signature requires exactly 65 bytes:
    // r: 32 bytes
    // s: 32 bytes
    // v: 1 byte

    // The total length will be signers.length * 65 bytes
    bytes memory signatures = new bytes(_signers.length * 65);

    for (uint256 i = 0; i < _signers.length; i++) {
      // Calculate position in the signatures array (65 bytes per signature)
      uint256 pos = 65 * i;

      // Set r to the signer address (converted to bytes32)
      bytes32 r = bytes32(uint256(uint160(_signers[i])));

      // Set s to zero (not used for approved hash validation)
      bytes32 s = bytes32(0);

      // Set v to 1 (indicates this is an approved hash signature)
      uint8 v = 1;

      // Write the signature values to the byte array
      assembly {
        // r value: first 32 bytes of the signature
        mstore(add(add(signatures, 32), pos), r)

        // s value: next 32 bytes of the signature
        mstore(add(add(signatures, 32), add(pos, 32)), s)

        // v value: final 1 byte of the signature
        mstore8(add(add(signatures, 32), add(pos, 64)), v)
      }
    }

    return signatures;
  }
}
