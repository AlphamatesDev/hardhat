//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceFeedExt {
    function latestAnswer() external view returns (int256 answer);
}

contract BuyLOHTicket is OwnableUpgradeable {

    IERC20 public _lohTicketAddress;
    uint256 public tokenPrice_USD;

    mapping (address => uint256) private _userPaid_CRO;
    IPriceFeedExt public priceFeed_CRO;
    
    event BuyLOHTicket(address _from, address _to, uint256 _amount);
    event WithdrawAll(address addr);
    
    receive() payable external {}
    fallback() payable external {}

    function initialize ()  public initializer {
        __Ownable_init();

        _lohTicketAddress = IERC20(0x759d34685468604c695De301ad11A9418e2f1038);

        priceFeed_CRO = IPriceFeedExt(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);

        tokenPrice_USD = 0.35 * 10 ** 8; // 35 Cents per ticket
    }

    function buyTokensByCRO() external payable {
        require(msg.value > 0, "Insufficient CRO amount");
        uint256 amountPrice = getLatestCROPrice() * msg.value;

        // token amount user want to buy
        uint256 tokenAmount = amountPrice / tokenPrice_USD;

        // transfer token to user
        _lohTicketAddress.transfer(msg.sender, tokenAmount);

        // add USD user bought
        _userPaid_CRO[msg.sender] += amountPrice;

        emit BuyLOHTicket(address(this), msg.sender, tokenAmount);
    }

    function buyTokensByCROWithReferral(address toReward) external payable {
        require(msg.value > 0, "Insufficient CRO amount");
        uint256 amountPrice = getLatestCROPrice() * msg.value;

        // token amount user want to buy
        uint256 tokenAmount = amountPrice / tokenPrice_USD;

        // transfer token to user
        _lohTicketAddress.transfer(msg.sender, tokenAmount);

        // transfer reward to referral provider
        payable(toReward).transfer(msg.value * 5 / 100);

        // add USD user bought
        _userPaid_CRO[msg.sender] += amountPrice;

        emit BuyLOHTicket(address(this), msg.sender, tokenAmount);
    }

    function getLatestCROPrice() public view returns (uint256) {
        return uint256(priceFeed_CRO.latestAnswer());
    }

    function withdrawAll() external onlyOwner {
        require(block.timestamp > endTime);

        uint256 CRObalance = address(this).balance;
        
        if (CRObalance > 0)
            payable(owner()).transfer(CRObalance);

        emit WithdrawAll(msg.sender);
    }

    function withdrawToken() public onlyOwner returns (bool) {
        require(block.timestamp > endTime);

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
    function setLOHTicketPriceByUSD(uint256 _tokenPrice) public onlyOwner {
        tokenPrice_USD = _tokenPrice;
    }
}