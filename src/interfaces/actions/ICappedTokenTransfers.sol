// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {ITransactionBuilder} from 'interfaces/actions/ITransactionBuilder.sol';

interface ICappedTokenTransfers is ISafeManageable, ITransactionBuilder {
  struct TokenTransfer {
    address token;
    address recipient;
    uint256 amount;
  }

  function tokenCap(address _token) external view returns (uint256 _transferCap);
  function capSpent(address _token) external view returns (uint256 _transferCapSpent);
  function tokenCooldown(address _token) external view returns (uint256 _transferCooldown);

  function tokenTransfers(uint256 _index) external view returns (address _token, address _recipient, uint256 _amount);

  // ~~~ ERRORS ~~~

  error LengthMismatch();
  error ExceededCap();
  error TokenCooldown();
  error UnallowedToken();

  // ~~~ ADMIN METHODS ~~~

  function addCappedToken(address _token, uint256 _cap) external;

  function addTokenTransfer(address _token, address _recipient, uint256 _amount) external;

  function addTokenTransfers(
    address[] memory _tokens,
    address[] memory _recipients,
    uint256[] memory _amounts
  ) external;
}
