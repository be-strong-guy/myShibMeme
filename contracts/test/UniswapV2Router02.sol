// contracts/test/UniswapV2Router02.sol
pragma solidity ^0.8.20;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
}

contract UniswapV2Router02 {
    address public factory;
    address public WETH;

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        amountToken = amountTokenDesired;
        amountETH   = msg.value;
        liquidity   = 1000;   // 简化
    }

    receive() external payable {}
}