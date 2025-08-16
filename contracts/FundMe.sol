// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 预言机
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// 1. 创建一个收款函数
// 2. 记录投资人并且查看
// 3. 活动结束后，达到目标值，生产商可以提款
// 4. 活动结束后，没有达到目标值，投资人在锁定期以后退款
contract FundMe {
    // 地址与资金映射
    mapping(address => uint256) public fundMap;

    // 每次最少转账10USD
    uint256 private constant MIN_FUND = 10;

    // 目标100USD
    uint256 private constant TARGET_FUND = 100;

    // 预言机
    AggregatorV3Interface private dataFeed;

    // 锁定期
    uint256 public lockTime;

    // 开始时间(合约部署时间)
    uint256 public deployTime;

    // 合约所有者
    address public owner;

    // 通证合约地址
    address private fundMeTokenAddress;

    // 资金提取标记
    bool public getFundFlag = false;

    constructor(uint256 _lockTime) {
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );

        lockTime = _lockTime;
        deployTime = block.timestamp;
        owner = msg.sender;
    }

    // 设置通证合约的地址
    function setfundMeTokenAddress(address _fundMeTokenAddress) public isOwner {
        fundMeTokenAddress = _fundMeTokenAddress;
    }

    // 收款
    function fund() external payable checkMinFund doing {
        fundMap[msg.sender] = msg.value + fundMap[msg.sender];
    }

    // 提取资金
    function getFund() external isOwner end {
        require(
            ethToUsd(address(this).balance) >= TARGET_FUND,
            "Target is not reached"
        );

        // 将当前合约余额转到合约所有者账户
        bool success;
        (success,) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(success, "transfer tx failed");

        // 资金提取成功标记
        getFundFlag = true;
    }

    // 扣除账户余额
    function deductFund(address account, uint256 fundAmount) public {
        require(
            msg.sender == fundMeTokenAddress,
            "you do not have permission to call this funtion."
        );
        require(fundMap[account] >= fundAmount, "you fund fund shortage.");

        fundMap[account] = fundMap[account] - fundAmount;
    }

    // 查询资金余额
    function queryFund() external view returns (uint256) {
        return fundMap[msg.sender];
    }

    // 退款
    function refund() external end {
        // 1. 资金是否已经目标值
        require(
            ethToUsd(address(this).balance) < TARGET_FUND,
            "Target is reached!"
        );

        // 2. 用户资金
        uint256 userFund = fundMap[msg.sender];
        require(userFund > 0, "there is no fund for you!");

        // 3. 转账
        payable(msg.sender).transfer(userFund);
        fundMap[msg.sender] = 0;
    }

    // 变更合约所有人
    function changeOwner(address _owner) external isOwner {
        owner = _owner;
    }

    // eth转USD
    function ethToUsd(uint256 ethAmount) public view returns (uint256) {
        uint256 ratio = uint256(getChainlinkDataFeedLatestAnswer());
        return (ethAmount * ratio) / 10 ** 26;
    }

    // 获取eth转USD比例
    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        // prettier-ignore
        (
        /* uint80 roundID */,
            int answer,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    modifier checkMinFund() {
        // 校验资金
        require(ethToUsd(msg.value) >= MIN_FUND, "Send more ETH");
        _;
    }

    modifier doing() {
        // 校验窗口
        require(block.timestamp >= deployTime, "Activity not start!");
        require(block.timestamp <= deployTime + lockTime, "Activity the end!");
        _;
    }

    modifier end() {
        // 校验窗口
        require(block.timestamp >= deployTime, "Activity not start!");
        require(block.timestamp > deployTime + lockTime, "Activity the end!");
        _;
    }

    modifier isOwner() {
        // 校验合约所有者
        require(msg.sender == owner, "You is not contract owner!");
        _;
    }
}
