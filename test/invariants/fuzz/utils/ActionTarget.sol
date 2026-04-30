// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// "Global" mock for all call target of the safe

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract ActionTarget is IERC20 {
  // Allowance claimor
  bool public isTransferFromCalled;
  address public transferFromSender;
  address public transferFromRecipient;
  uint256 public transferFromAmount;

  // Arbitrary action
  bool public isDepositCalled;
  bool public isTransferCalled;
  address public transferRecipient;
  uint256 public transferAmount;

  // OPx
  bool public isDowngraded;
  uint256 public downgradeAmount; // should be balanceOf

  // Everclear token conversion
  bool public isApproved;
  address public approveSpender;
  uint256 public approveAmount;
  bool public isERC20Deposited;
  uint256 public depositAmount;

  // Everclear token stake
  bool public isClaimed;
  address public claimRecipient;
  bool public isReleased;
  bool public isIncreaseLockPositionCalled;

  bool public isUpdateStateCalled;
  bytes public updateStateData;
  uint128 public lockPositionAmount;
  uint128 public lockTime;
  uint256 public gasLimit;

  // Cap tracking
  mapping(address token => uint256 cap) public tokenCaps;
  mapping(address token => uint256 totalSpent) public tokenTotalSpent;
  uint256 public lastEpochState;
  uint256 public constant EPOCH_LENGTH = 1 days;
  uint256 public constant STARTING_TIMESTAMP = 1;

  // Vesting/External functions
  uint256 public constant UNCLAIMED_AMOUNT = 1000;
  uint256 public constant VESTED_AMOUNT = 2000;
  uint256 public constant RELEASED_AMOUNT = 500;
  uint256 public constant QUOTE_MESSAGE_FEE = 0.1 ether;
  uint32 public constant EVERCLEAR_ID = 1;

  function deposit() public payable {
    isDepositCalled = true;
  }

  function transfer(address _to, uint256 _amount) public override returns (bool) {
    isTransferCalled = true;
    transferRecipient = _to;
    transferAmount = _amount;
    return true;
  }

  function claim(address _vestingEscrow) external {
    isClaimed = true;
    claimRecipient = _vestingEscrow;
  }

  function release() external {
    isReleased = true;
  }

  function approve(address _spender, uint256 _amount) public override returns (bool) {
    isApproved = true;
    approveSpender = _spender;
    approveAmount = _amount;
    return true;
  }

  function deposit(uint256 _amount) external {
    isERC20Deposited = true;
    depositAmount = _amount;
  }

  function downgrade(uint256 _amount) external {
    isDowngraded = true;
    downgradeAmount = _amount;
  }

  function updateState(bytes calldata _data) external {
    isUpdateStateCalled = true;
    updateStateData = _data;
  }

  function increaseLockPosition(uint128 _amount, uint128 _lockTime, uint256 _gasLimit) external payable {
    isIncreaseLockPositionCalled = true;
    lockPositionAmount = _amount;
    lockTime = _lockTime;
    gasLimit = _gasLimit;
  }

  // Additional required external view functions
  function unclaimed() external pure returns (uint256) {
    return UNCLAIMED_AMOUNT;
  }

  function vestedAmount(uint64) external pure returns (uint256) {
    return VESTED_AMOUNT;
  }

  function released() external pure returns (uint256) {
    return RELEASED_AMOUNT;
  }

  function quoteMessage(uint32, bytes calldata, uint256) external pure returns (uint256) {
    return 0;
  }

  function gateway() external view returns (address) {
    return address(this);
  }

  // Hub-specific functions - this should not be implemented in ActionTarget
  // The real hub will deploy actual contracts

  function cap(address _token) external view returns (uint256) {
    return tokenCaps[_token];
  }

  function totalSpent(address _token) external view returns (uint256) {
    return tokenTotalSpent[_token];
  }

  function lastEpoch() external view returns (uint256) {
    return lastEpochState;
  }

  function setCap(address _token, uint256 _cap) external {
    tokenCaps[_token] = _cap;
  }

  // ERC20 Implementation
  function name() public pure returns (string memory) {
    return 'ActionTarget';
  }

  function symbol() public pure returns (string memory) {
    return 'AT';
  }

  function decimals() public pure returns (uint8) {
    return 18;
  }

  function totalSupply() public view override returns (uint256) {
    return 1;
  }

  // solhint-disable-next-line no-unused-vars
  function balanceOf(address account) public view override returns (uint256) {
    return 123;
  }

  // solhint-disable-next-line no-unused-vars
  function allowance(address owner, address spender) public view override returns (uint256) {
    return 789;
  }

  function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
    isTransferFromCalled = true;
    transferFromSender = from;
    transferFromRecipient = to;
    transferFromAmount = amount;
    return true;
  }
}
