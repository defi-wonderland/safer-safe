// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

interface IMultiSendCallOnly {
  function multiSend(bytes memory data) external payable;
}
