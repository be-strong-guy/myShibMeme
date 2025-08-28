# ShibaMeme 代币部署与使用指南

## 1 环境准备
- Node.js ≥ 18
- Hardhat 或 Foundry
- 一个以太坊测试网 RPC（Sepolia）
- 0.1 ETH 测试币 + 若干 faucet 代币

## 2 部署步骤

### 2.1 安装依赖
```bash
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npx hardhat init

### 2.2 如何运行
```bash
npx hardhat run deploy/deploy.js --network sepolia
```

## 3 在 Uniswap 添加流动性
打开 Uniswap V2 前端（https://app.uniswap.org/#/add/v2）。
选择 ETH / SHIBME 交易对。
输入 ETH 数量，前端会自动计算需要授权的 SHIBME 数量。
在钱包中先执行 approve(tokenAddress, amount)，再调用 addLiquidityETH 或直接在前端完成。

## 4 日常交易
买/卖：在 Uniswap 前端直接交易即可，合约已自动扣除 6% 税。
转账：直接调用 transfer(to, amount)，注意单笔 ≤ 0.5% 总供应量，接收方余额 ≤ 2% 总供应量。

## 5 调整参数（仅合约 owner）
如需修改税率或限额，可在合约中增加 onlyOwner 修饰符的 setter 函数，例如：
```solidity
function setTax(uint256 _tax) external onlyOwner { tax = _tax; }
```
