// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract UniswapPriceAnchorSwapPair is ActionsBuilder {
  constructor(
    address _oracle,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    address _recipient,
    address _parent
  ) ActionsBuilder(_parent) {
    ORACLE = _oracle;
    TOKEN_IN = _tokenIn;
    TOKEN_OUT = _tokenOut;
    AMOUNT_IN = _amountIn;
    RECIPIENT = _recipient;
  }

  /// @inheritdoc IUniswapPriceAnchorSwapPair
  address public immutable TOKEN_IN;

  /// @inheritdoc IUniswapPriceAnchorSwapPair
  address public immutable TOKEN_OUT;

  /// @inheritdoc IUniswapPriceAnchorSwapPair
  uint256 public immutable AMOUNT_IN;

  /// @inheritdoc IUniswapPriceAnchorSwapPair
  address public immutable RECIPIENT;

  /// @inheritdoc IUniswapPriceAnchorSwapPair
  address public immutable ORACLE;

  function getActions() external view override(ActionsBuilder, IActionsBuilder) returns (Action[] memory _actions) {
    _actions = new Action[](2);

    // 1) approve token in to be swapped by the price anchor hub
    _actions[0] = Action({target: TOKEN_IN, data: abi.encodeCall(IERC20.approve, (ORACLE, AMOUNT_IN)), value: 0});

    // 2) call reportSwap() on the price anchor hub
    _actions[1] = Action({
      target: PARENT,
      data: abi.encodeCall(IUniswapPriceAnchorHub.reportSwap, (ORACLE, TOKEN_IN, TOKEN_OUT, AMOUNT_IN)),
      value: 0
    });
  }
}
