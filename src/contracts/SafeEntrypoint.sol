// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../interfaces/IActions.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

interface ISafe {
  function execTransaction(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address payable refundReceiver,
    bytes memory signatures
  ) external payable returns (bool success);
}

contract SafeEntrypoint {
  mapping(address _actionsContract => bool _isAllowed) public allowedActions;
  mapping(bytes32 _actionsHash => uint256 _executableAt) public actionsExecutableAt;
  mapping(bytes32 _actionsHash => bytes _actionsData) public actionsData;

  ISafe public immutable SAFE;
  address public immutable MULTI_SEND;

  error NotExecutable();

  constructor(address _safe, address _multiSend) {
    SAFE = ISafe(_safe);
    MULTI_SEND = _multiSend;
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

    actionsExecutableAt[actionsHash] = block.timestamp + actionsDelay;
    actionsData[actionsHash] = abi.encode(actions);
  }

  function executeActions(bytes32 _actionsHash, address[] memory _signers) external payable {
    if (actionsExecutableAt[_actionsHash] > block.timestamp) revert NotExecutable();

    IActions.Action[] memory _actions = abi.decode(actionsData[_actionsHash], (IActions.Action[]));

    bytes memory _multiSendData = _parseMultiSendData(_actions);
    address[] memory _sortedSigners = _sortSigners(_signers);
    bytes memory _signatures = _parseSignatures(_sortedSigners);

    SAFE.execTransaction{value: msg.value}({
      to: MULTI_SEND,
      value: msg.value,
      data: _multiSendData,
      operation: 1, // DELEGATE_CALL
      safeTxGas: 0,
      baseGas: 0,
      gasPrice: 0,
      gasToken: address(0),
      refundReceiver: payable(address(this)),
      signatures: _signatures
    });
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

  modifier isAuthorized() {
    // TODO: check if msg.sender is in the SAFE signers list
    _;
  }
}
