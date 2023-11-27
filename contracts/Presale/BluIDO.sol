//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceFeedExt {
    function latestAnswer() external view returns (int256 answer);
}

contract BluIDO is OwnableUpgradeable {

    IERC20 public _saleTokenAddress;
    uint256 public tokenPrice_USD;

    uint256 public startTime;
    uint256 public endTime;

    mapping (address => uint256) private _userPaid_MATIC;
    IPriceFeedExt public priceFeed_MATIC;

    function initialize ()  public initializer {
        __Ownable_init();

        _saleTokenAddress = IERC20(0x759d34685468604c695De301ad11A9418e2f1038);

        startTime = 1693397345; // Aug 30th, 00:00 UTC
        endTime =   1696043331; // Sep 30th, 00:00 UTC

        priceFeed_MATIC = IPriceFeedExt(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);

        tokenPrice_USD = 0.1 * 10 ** 8; // 10 Cents per token for sale
    }

    function buyTokensByMATIC() external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "BluIDOFactory: Not BluIDO period");

        require(msg.value > 0, "Insufficient MATIC amount");
        uint256 amountPrice = getLatestMATICPrice() * msg.value;

        // token amount user want to buy
        uint256 tokenAmount = amountPrice / tokenPrice_USD;

        // transfer token to user
        _saleTokenAddress.transfer(msg.sender, tokenAmount);

        // add USD user bought
        _userPaid_MATIC[msg.sender] += amountPrice;

        emit BluIDO(address(this), msg.sender, tokenAmount);
    }

    function buyTokensByMATICWithReferral(address toReward) external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "BluIDOFactory: Not BluIDO period");

        require(msg.value > 0, "Insufficient MATIC amount");
        uint256 amountPrice = getLatestMATICPrice() * msg.value;

        // token amount user want to buy
        uint256 tokenAmount = amountPrice / tokenPrice_USD;

        // transfer token to user
        _saleTokenAddress.transfer(msg.sender, tokenAmount);

        // transfer reward to referral provider
        payable(toReward).transfer(msg.value * 5 / 100);

        // add USD user bought
        _userPaid_MATIC[msg.sender] += amountPrice;

        emit BluIDO(address(this), msg.sender, tokenAmount);
    }

    function getLatestMATICPrice() public view returns (uint256) {
        return uint256(priceFeed_MATIC.latestAnswer());
    }

    function withdrawAll() external onlyOwner {
        require(block.timestamp > endTime);

        uint256 MATICbalance = address(this).balance;
        
        if (MATICbalance > 0)
            payable(owner()).transfer(MATICbalance);

        emit WithdrawAll(msg.sender);
    }

    function withdrawToken() public onlyOwner returns (bool) {
        require(block.timestamp > endTime);

        uint256 balance = _saleTokenAddress.balanceOf(address(this));
        return _saleTokenAddress.transfer(msg.sender, balance);
    }

    function getUserPaidMATIC () public view returns (uint256) {
        return _userPaid_MATIC[msg.sender];
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

    function setSaleTokenAddress(address _address) public onlyOwner {
        _saleTokenAddress = IERC20(_address);
    }

    /* Price Decimal is 8 */
    function setSaleTokenPriceByUSD(uint256 _tokenPrice) public onlyOwner {
        tokenPrice_USD = _tokenPrice;
    }

    event BluIDO(address _from, address _to, uint256 _amount);
    event SetStartTime(uint256 _time);
    event SetEndTime(uint256 _time);
    event WithdrawAll(address addr);

    receive() payable external {}

    fallback() payable external {}
}