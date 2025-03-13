// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../interfaces/IActions.sol';
import {ISafe} from '../interfaces/ISafe.sol';

contract SafeEntrypoint {
  mapping(address _actionsContract => bool _isAllowed) public allowedActions;
  mapping(bytes32 _actionsHash => uint256 _executableAt) public actionsExecutableAt;
  mapping(bytes32 _actionsHash => bytes _actionsData) public actionsData;

  ISafe public immutable SAFE;
  address public immutable MULTI_SEND_CALL_ONLY;

  error NotExecutable();
  error NotAuthorized();

  event ActionsQueued(bytes32 actionsHash, uint256 executableAt);
  event ActionsExecuted(bytes32 actionsHash, bytes32 safeTxHash);

  constructor(address _safe, address _multiSend) {
    SAFE = ISafe(_safe);
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

  function _parseMultiSendData(IActions.Action[] memory _actions) internal returns (bytes memory) {
    // TODO: parse actions into MultiSend calldata
  }

  function _sortSigners(address[] memory _signers) internal returns (address[] memory) {
    // TODO: sort signers by address alphabetically
  }

  function _parseSignatures(address[] memory _signers) internal returns (bytes memory) {
    // TODO: parse sorted signers into "signatures"
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

  modifier isMsig() {
    // NOTE: SAFE has (probably) 1w execution timelock
    if (msg.sender != address(SAFE)) revert NotAuthorized();
    _;
  }

  modifier isAuthorized() {
    // TODO: check if msg.sender is in the SAFE signers list
    _;
  }
}
