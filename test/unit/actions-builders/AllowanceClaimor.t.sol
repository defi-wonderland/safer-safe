// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {AllowanceClaimor} from 'src/contracts/actions-builders/AllowanceClaimor.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitAllowanceClaimor is Test {
  AllowanceClaimor public allowanceClaimor;
  address public safe;
  address public token;
  address public tokenOwner;
  address public tokenRecipient;

  function setUp() public {
    safe = makeAddr('safe');
    token = makeAddr('token');
    tokenOwner = makeAddr('tokenOwner');
    tokenRecipient = makeAddr('tokenRecipient');

    allowanceClaimor = new AllowanceClaimor(address(0), safe, token, tokenOwner, tokenRecipient);
  }

  function _mockAndExpect(address _target, bytes memory _call, bytes memory _returnData) internal {
    vm.mockCall(_target, _call, _returnData);
    vm.expectCall(_target, _call);
  }

  function test_ConstructorWhenCalled(
    address _safe,
    address _token,
    address _tokenOwner,
    address _tokenRecipient
  ) external {
    allowanceClaimor = new AllowanceClaimor(address(0), _safe, _token, _tokenOwner, _tokenRecipient);

    // it should set the correct values
    assertEq(allowanceClaimor.SAFE(), _safe);
    assertEq(address(allowanceClaimor.TOKEN()), _token);
    assertEq(allowanceClaimor.TOKEN_OWNER(), _tokenOwner);
    assertEq(allowanceClaimor.TOKEN_RECIPIENT(), _tokenRecipient);
  }

  modifier whenCalled() {
    _;
  }

  function test_GetActionsWhenCalled(uint256 _allowance, uint256 _balance) external whenCalled {
    // it should call allowance on the token
    _mockAndExpect(token, abi.encodeWithSelector(IERC20.allowance.selector, tokenOwner, safe), abi.encode(_allowance));

    // it should call balanceOf on the token
    _mockAndExpect(token, abi.encodeWithSelector(IERC20.balanceOf.selector, tokenOwner), abi.encode(_balance));

    allowanceClaimor.getActions();
  }

  function test_GetActionsWhenAmountToClaimIsGreaterThanBalance(
    uint256 _allowance,
    uint256 _balance
  ) external whenCalled {
    _balance = bound(_balance, 0, type(uint256).max - 1);
    _allowance = bound(_allowance, _balance + 1, type(uint256).max);

    _mockAndExpect(token, abi.encodeWithSelector(IERC20.allowance.selector, tokenOwner, safe), abi.encode(_allowance));
    _mockAndExpect(token, abi.encodeWithSelector(IERC20.balanceOf.selector, tokenOwner), abi.encode(_balance));

    // it should set amount to claim to balance
    IActionsBuilder.Action[] memory _actions = allowanceClaimor.getActions();
    assertEq(_actions.length, 1);
    assertEq(_actions[0].target, token);
    assertEq(
      _actions[0].data, abi.encodeWithSelector(IERC20.transferFrom.selector, tokenOwner, tokenRecipient, _balance)
    );
    assertEq(_actions[0].value, 0);
  }

  function test_GetActionsWhenAmountToClaimIsLessThanOrEqualToBalance(
    uint256 _allowance,
    uint256 _balance
  ) external whenCalled {
    _balance = bound(_balance, 0, type(uint256).max);
    _allowance = bound(_allowance, 0, _balance);

    _mockAndExpect(token, abi.encodeWithSelector(IERC20.allowance.selector, tokenOwner, safe), abi.encode(_allowance));
    _mockAndExpect(token, abi.encodeWithSelector(IERC20.balanceOf.selector, tokenOwner), abi.encode(_balance));

    // it should return the correct actions
    IActionsBuilder.Action[] memory _actions = allowanceClaimor.getActions();
    assertEq(_actions.length, 1);
    assertEq(_actions[0].target, token);
    assertEq(
      _actions[0].data, abi.encodeWithSelector(IERC20.transferFrom.selector, tokenOwner, tokenRecipient, _allowance)
    );
    assertEq(_actions[0].value, 0);
  }
}
