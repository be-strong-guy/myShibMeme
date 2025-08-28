// contracts/test/UniswapV2Factory.sol
pragma solidity ^0.8.20;

contract UniswapV2Factory {
    address public feeToSetter;
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    constructor(address _feeToSetter) { feeToSetter = _feeToSetter; }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(getPair[token0][token1] == address(0));
        pair = address(new UniswapV2Pair(token0, token1));
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
    }
}

contract UniswapV2Pair {
    address public token0;
    address public token1;
    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }
}