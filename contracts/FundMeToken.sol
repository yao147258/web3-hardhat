// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FundMe} from "./FundMe.sol";

contract FundMeToken is ERC20 {
    FundMe fundMe;

    constructor(address fundMeAddress) ERC20("FundMeToken", "FT") {
        fundMe = FundMe(fundMeAddress);
    }

    // 获取通证
    function mint(uint256 tokenAmount) public fundMeCompleted {
        require(
            fundMe.fundMap(msg.sender) >= tokenAmount,
            "You cannot mint this many tokens!"
        );

        // 颁发通证
        _mint(msg.sender, tokenAmount);

        // 扣除用户对应的余额
        fundMe.deductFund(msg.sender, tokenAmount);
    }

    // 兑换通证(使用通证)
    function claim(uint256 tokenAmount) public fundMeCompleted {
        // to do exchange issue
        require(
            balanceOf(msg.sender) >= tokenAmount,
            "You dont have enough ERC20 tokens"
        );

        // 销毁通证
        _burn(msg.sender, tokenAmount);
    }

    modifier fundMeCompleted() {
        require(fundMe.getFundFlag(), "The fundme is not completed yet");
        _;
    }
}
