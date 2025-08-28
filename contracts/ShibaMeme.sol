// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 *  SHIB-Style Meme Token
 *  功能点:
 *  1. 交易税：6% (2% LP, 2% 营销, 2% 销毁)
 *  2. 流动性池交互：支持 add/remove liquidity
 *  3. 交易限制：单笔 ≤ 0.5% totalSupply；最大钱包 ≤ 2% totalSupply
 */

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external view returns (address);
    function WETH() external view returns (address);
}

contract ShibaMeme {
    string  public name     = "ShibaMeme";
    string  public symbol   = "SHIBME";
    uint8   public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Ethereum Mainnet Uniswap V2
    address public constant DEAD   = 0x000000000000000000000000000000000000dEaD;

    address public pair;
    address public marketingWallet;

    uint256 public tax = 6; // 6%
    uint256 public maxTxAmount;
    uint256 public maxWallet;

    bool private inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply, address _marketing) {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = totalSupply;
        marketingWallet = _marketing;

        maxTxAmount   = totalSupply * 5 / 1000;  // 0.5%
        maxWallet     = totalSupply * 2 / 100;   // 2%

        // 创建交易对
        pair = address(0);
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    function setPair(address _pair) external {
        require(pair == address(0), "Pair already set");
        pair = _pair;
    }
    /* ===== ERC20 标准函数 ===== */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    /* ===== 内部转账逻辑 ===== */
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        // 普通转账 & 添加流动性豁免
      //  bool takeFee = !(from == address(this) || to == address(this) || from == pair || to == pair);
        // for test
        bool takeFee = true;
        if (takeFee) {
            require(amount <= maxTxAmount, "Exceeds maxTxAmount");
            if (to != pair) require(balanceOf[to] + amount <= maxWallet, "Exceeds maxWallet");
        }

        uint256 taxAmount = takeFee ? amount * tax / 100 : 0;
        uint256 sendAmount = amount - taxAmount;

        balanceOf[from] -= amount;
        balanceOf[to]   += sendAmount;

        if (taxAmount > 0) {
            uint256 burnAmount = taxAmount * 2 / 6;   // 2% burn
            uint256 lpAmount   = taxAmount * 2 / 6;   // 2% LP
            uint256 mktAmount  = taxAmount * 2 / 6;   // 2% marketing

            balanceOf[DEAD] += burnAmount;
            emit Transfer(from, DEAD, burnAmount);

            balanceOf[marketingWallet] += mktAmount;
            emit Transfer(from, marketingWallet, mktAmount);

            // 将 LP 部分先转给合约，稍后统一 swap & add liquidity
            balanceOf[address(this)] += lpAmount;
            emit Transfer(from, address(this), lpAmount);
        }

        emit Transfer(from, to, sendAmount);
        return true;
    }
    function setMaxTxPercent(uint256 pct) external {
        maxTxAmount = totalSupply * pct / 100;
    }
    function setMaxWalletPercent(uint256 pct) external {
        maxWallet = totalSupply * pct / 100;
    }
    function setMarketingWallet(address _wallet) external {
        marketingWallet = _wallet;
    }
    /* ===== 手动添加流动性（开发阶段或脚本调用） ===== */
    function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) external payable {
        require(msg.value == ethAmount, "ETH mismatch");
        _transfer(msg.sender, address(this), tokenAmount);

        IUniswapV2Router02(ROUTER).addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }

    /* ===== 提取误发代币(仅 owner 场景) ===== */
    receive() external payable {}
}