// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface IMultiSendCallOnly {
  function multiSend(bytes memory data) external payable;
}
