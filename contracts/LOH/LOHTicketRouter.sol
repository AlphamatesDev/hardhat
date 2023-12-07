//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceFeedExt {
    struct PriceInfo {
        // Price
        uint256 price;
        // Confidence interval around the price
        uint256 conf;
    }
    function latestAnswer() external view returns (PriceInfo memory priceInfo);
}

contract LOHTicketRouter is OwnableUpgradeable {

    IERC20 public _lohTicketAddress;
    uint256 public lohTicketPrice_USD;

    mapping (address => uint256) private _userPaid_CRO;
    IPriceFeedExt public priceFeed_CRO;
    
    event BuyLOHTicket(address _from, address _to, uint256 _amount);
    event WithdrawAll(address addr);

    receive() payable external {}
    fallback() payable external {}

    function initialize ()  public initializer {
        __Ownable_init();

        _lohTicketAddress = IERC20(0xf1A5A831ca54AE6AD36a012F5FB2768e6f5d954A);

        priceFeed_CRO = IPriceFeedExt(0x5B55012bC6DBf545B6a5ab6237030f79b1E38beD);

        lohTicketPrice_USD = 0.35 * 10 ** 8; // 35 Cents per ticket
    }

    function buyLOHTicketsByCRO() external payable {
        require(msg.value > 0, "Insufficient CRO amount");
        uint256 amountPrice = getLatestCROPrice() * msg.value;

        // lohTicket amount user want to buy
        uint256 lohTicketAmount = amountPrice / lohTicketPrice_USD;

        // transfer lohTicket to user
        _lohTicketAddress.transfer(msg.sender, lohTicketAmount);

        // add USD user bought
        _userPaid_CRO[msg.sender] += amountPrice;

        emit BuyLOHTicket(address(this), msg.sender, lohTicketAmount);
    }

    function buyLOHTicketsByCROWithReferral(address toReward) external payable {
        require(msg.value > 0, "Insufficient CRO amount");
        uint256 amountPrice = getLatestCROPrice() * msg.value;

        // lohTicket amount user want to buy
        uint256 lohTicketAmount = amountPrice / lohTicketPrice_USD;

        // transfer lohTicket to user
        _lohTicketAddress.transfer(msg.sender, lohTicketAmount);

        // transfer reward to referral provider
        payable(toReward).transfer(msg.value * 5 / 100);

        // add USD user bought
        _userPaid_CRO[msg.sender] += amountPrice;

        emit BuyLOHTicket(address(this), msg.sender, lohTicketAmount);
    }

    function getLatestCROPrice() public view returns (uint256) {
        return uint256(priceFeed_CRO.latestAnswer().price);
    }

    function withdrawAll() external onlyOwner {
        uint256 CRObalance = address(this).balance;
        
        if (CRObalance > 0)
            payable(owner()).transfer(CRObalance);

        emit WithdrawAll(msg.sender);
    }

    function withdrawLOHTicket() public onlyOwner returns (bool) {
        uint256 balance = _lohTicketAddress.balanceOf(address(this));
        return _lohTicketAddress.transfer(msg.sender, balance);
    }

    function getUserPaidCRO () public view returns (uint256) {
        return _userPaid_CRO[msg.sender];
    }

    function setLOHTicketAddress(address _address) public onlyOwner {
        _lohTicketAddress = IERC20(_address);
    }

    /* Price Decimal is 8 */
    function setLOHTicketPriceByUSD(uint256 _lohTicketPrice) public onlyOwner {
        lohTicketPrice_USD = _lohTicketPrice;
    }
}