//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceFeedExt {
    function latestAnswer() external view returns (int256 answer);
}

contract Presale is OwnableUpgradeable {

    IERC20 public _saleTokenAddress;
    uint256 public tokenPrice_USD;

    uint256 public startTime;
    uint256 public endTime;

    mapping (address => uint256) private _userPaid_BNB;
    IPriceFeedExt public priceFeed_BNB;

    IERC20 public _usdtAddress;
    mapping (address => uint256) private _userPaid_USDT;

    IERC20 public _busdAddress;
    mapping (address => uint256) private _userPaid_BUSD;

    function initialize ()  public initializer {
        __Ownable_init();

        _saleTokenAddress = IERC20(0xB95972FeF33A81998dc6F4f6e9dd3FCffd1b14F4);

        startTime = 1681916400; // April 20th, 00:00 UTC
        endTime =   1684508400; // May 20th, 00:00 UTC

        _usdtAddress = IERC20(0x55d398326f99059fF775485246999027B3197955);
        _busdAddress = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

        priceFeed_BNB = IPriceFeedExt(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

        tokenPrice_USD = 0.1 * 10 ** 8; // 10 Cents per token for sale
    }

    function buyTokensByBNB() external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "PresaleFactory: Not presale period");

        require(msg.value > 0, "Insufficient BNB amount");
        uint256 amountPrice = getLatestBNBPrice() * msg.value;

        // token amount user want to buy
        uint256 tokenAmount = amountPrice / tokenPrice_USD;

        // transfer token to user
        _saleTokenAddress.transfer(msg.sender, tokenAmount);

        // add USD user bought
        _userPaid_BNB[msg.sender] += amountPrice;

        emit Presale(address(this), msg.sender, tokenAmount);
    }

    function buyTokensByUSDT(uint256 _amount) external {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "PresaleFactory: Not presale period");

        // token amount user want to buy
        uint256 tokenAmount = _amount / tokenPrice_USD;
        uint256 decimalTokenAmount = tokenAmount * 10 ** 8;

        // transfer USDT to owners
        _usdtAddress.transferFrom(msg.sender, address(this), _amount);

        // transfer token to user
        _saleTokenAddress.transfer(msg.sender, decimalTokenAmount);

        // add USD user bought
        _userPaid_USDT[msg.sender] += _amount;

        emit Presale(address(this), msg.sender, decimalTokenAmount);
    }

    function buyTokensByBUSD(uint256 _amount) external {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "PresaleFactory: Not presale period");

        // token amount user want to buy
        uint256 tokenAmount = _amount / tokenPrice_USD;
        uint256 decimalTokenAmount = tokenAmount * 10 ** 8;

        // transfer BUSD to owners
        _busdAddress.transferFrom(msg.sender, address(this), _amount);

        // transfer token to user
        _saleTokenAddress.transfer(msg.sender, decimalTokenAmount);

        // add USD user bought
        _userPaid_BUSD[msg.sender] += _amount;

        emit Presale(address(this), msg.sender, decimalTokenAmount);
    }

    function getLatestBNBPrice() public view returns (uint256) {
        return uint256(priceFeed_BNB.latestAnswer());
    }

    function withdrawAll() external onlyOwner {
        require(block.timestamp > endTime);

        uint256 BNBbalance = address(this).balance;
        uint256 USDTbalance = _usdtAddress.balanceOf(address(this));
        uint256 BUSDbalance = _busdAddress.balanceOf(address(this));
        
        if (BNBbalance > 0)
            payable(owner()).transfer(BNBbalance);

        if (USDTbalance > 0)
            _usdtAddress.transfer(owner(), USDTbalance);

        if (BUSDbalance > 0)
            _busdAddress.transfer(owner(), BUSDbalance);

        emit WithdrawAll(msg.sender);
    }

    function withdrawToken() public onlyOwner returns (bool) {
        require(block.timestamp > endTime);

        uint256 balance = _saleTokenAddress.balanceOf(address(this));
        return _saleTokenAddress.transfer(msg.sender, balance);
    }

    function getUserPaidBNB () public view returns (uint256) {
        return _userPaid_BNB[msg.sender];
    }

    function getUserPaidUSDT () public view returns (uint256) {
        return _userPaid_USDT[msg.sender];
    }

    function getUserPaidBUSD () public view returns (uint256) {
        return _userPaid_BUSD[msg.sender];
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

    event Presale(address _from, address _to, uint256 _amount);
    event SetStartTime(uint256 _time);
    event SetEndTime(uint256 _time);
    event WithdrawAll(address addr);

    receive() payable external {}

    fallback() payable external {}
}