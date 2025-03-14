// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

struct SimpleAction {
  address target; // e.g. WETH
  string signature; // e.g. "transfer(address,uint256)"
  bytes data; // e.g. abi.encode(address,uint256)
  uint256 value; // (msg.value)
}
