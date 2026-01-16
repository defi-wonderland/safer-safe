// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract UniswapPriceAnchorHub is ActionHub {
  constructor(address _recipient, address _parent) ActionHub(_parent) {}

  /// @inheritdoc IUniswapPriceAnchorHub
  address public immutable RECIPIENT;

  /// @inheritdoc IUniswapPriceAnchorHub
  function createNewActionsBuilder(
    address _oracle,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external isSafeOwner returns (address _actionsBuilder) {
    _actionsBuilder = address(
      new UniswapPriceAnchorSwapPair(_oracle, _tokenIn, _tokenOut, _amountIn, RECIPIENT, msg.sender)
    );

    _saveNewActionsBuilder(_actionsBuilder);

    emit UniswapPriceAnchorSwapPairCreated(_actionsBuilder, _oracle, _tokenIn, _tokenOut, _amountIn);
  }

  function reportSwap(address _oracle, address _tokenIn, address _tokenOut, uint256 _amountIn) external isSafe {
    // 1) get the price of the pair from the oracle

    // 2) compare, if the price is between safe range, go to next step, otherwise revert

    // 3) do swap

    // 4) send token out to the recipient
  }
}
