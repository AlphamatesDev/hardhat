// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface MeacToken  {
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract SwapContract is Ownable {
    using SafeMath for uint256;
    MeacToken  private token;
    AggregatorV3Interface private priceFeed;
    mapping(address => uint256) public depositsMATIC;
    mapping(address => uint256) public depositsUSDC;
    mapping(address => uint256) public lockedMETAC;
    mapping(address => uint256) public deposittimes;
    uint256 public  totalLockedMETAC = 0 ether;
    uint256 public  totallockTime = 180 days;
    uint256 public  minDepositAmount = 25 / 10 * (10 ** 6); //2.5usdc
    uint256         tokensAmountForUSDC = 0.12 ether; // 1 tokens per 0.12usdc
    uint256 public  totalSwapedMATIC;
    uint256 public  totalSwapedUSDC;
    address private usdcAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  
    constructor(MeacToken _token) {
        token = _token;
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);//for mainnet
    }

    // Deposit USDC and lock Metacoms tokens against your matic value
    function depositUSDCForLockToken(uint256 amnt) public {
        require(amnt >= minDepositAmount, "Minimum amount is 2.5USDC");
        
        IERC20(usdcAddress).transferFrom(msg.sender, address(this), amnt);
        uint256 tokenAmount = (getTokensAmount(amnt));

        depositsUSDC[msg.sender] = depositsUSDC[msg.sender].add(amnt);
        lockedMETAC[msg.sender] = lockedMETAC[msg.sender].add(tokenAmount);
        deposittimes[msg.sender] = block.timestamp;
        totalLockedMETAC = totalLockedMETAC.add(tokenAmount);
    }

    // Deposit Matic and lock Metacoms tokens against your matic value
    function depositMATICForLockToken() public payable {
       require(theUSDCAmount(msg.value) >= minDepositAmount, "Minimum amount is 2.5USDC");
        
        uint256 usdcAmount =  getUSDCAmount(msg.value);
        uint256 tokenAmount = (MaticTokensAmount(usdcAmount));
        
        depositsMATIC[msg.sender] = depositsMATIC[msg.sender].add(msg.value);
        lockedMETAC[msg.sender] = lockedMETAC[msg.sender].add(tokenAmount);
        deposittimes[msg.sender] = block.timestamp;
        totalLockedMETAC = totalLockedMETAC.add(tokenAmount);
    }
    
    // Approve function for onlyOwner of contract
    function approve(address tokenAddress, address spender, uint256 amount) public onlyOwner returns (bool) {
      IERC20(tokenAddress).approve(spender, amount);
      return true;
    }

    // Deposit USDC and get METAC in Exchange 
    function depositUSDCForUnlockToken(uint256 amnt) public {
        require(amnt >= minDepositAmount, "Minimum amount is 2.5USDC");
        
        IERC20(usdcAddress).transferFrom(msg.sender, address(this), amnt);
        uint256 tokenAmount = (getTokensAmount(amnt));
        
        token.transfer(msg.sender, tokenAmount);
        totalSwapedUSDC = totalSwapedUSDC.add(amnt);
    }

    /*
    *Deposit Matic and get METAC in exchange
    *Matic value must be equal to atleast 2.5 usdc
    **/
    function depositMATICForUnlockToken() public payable {
        require(theUSDCAmount(msg.value) >= minDepositAmount, "Minimum amount is 2.5USDC");
       
        uint256 usdcAmount = getUSDCAmount(msg.value);
        uint256 tokenAmount = (MaticTokensAmount(usdcAmount));
        
        token.transfer(msg.sender, tokenAmount);
        totalSwapedMATIC = totalSwapedMATIC.add(msg.value);
    }

    // Function for user to  withdraw their locked Metacoms token after lock period has ended
    function claimTokens() public {
        require(lockedMETAC[msg.sender] > 0, "There are no deposited tokens for you.");
        require(checkTime(msg.sender), "Your tokens are locked now.");
        
        token.transfer(msg.sender, lockedMETAC[msg.sender]);
        totalLockedMETAC = totalLockedMETAC.sub(lockedMETAC[msg.sender]);
        lockedMETAC[msg.sender] = 0;
        depositsMATIC[msg.sender] = 0;
        depositsUSDC[msg.sender] = 0;
        deposittimes[msg.sender] = 0;
    }

    //Read function to show user their data of locked tokens
    function read(address add) public view returns(uint256 _depositMATIC, uint256 _depositUSDC, uint256 _lockedMETAC, uint256 _restTime, bool _checkTime) {
        _depositMATIC = depositsMATIC[add];
        _depositUSDC = depositsUSDC[add];
        _lockedMETAC = lockedMETAC[add];
        _restTime = 0;
        if(totallockTime >= (block.timestamp - deposittimes[add]))
            _restTime = totallockTime - (block.timestamp - deposittimes[add]);
        _checkTime = checkTime(add);
    }

    // Gets latest price of usdc against per matic from price feed
    function getUSDCPerMATIC() public view returns (uint256) {
        (
            ,
            int256 price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        
        return (uint256(price));
    }
    
    //Shows Matic amount in USDC 
    function getUSDCAmount(uint256 maticAmount) public view returns(uint256){
        uint256 usdcAmount = maticAmount.mul(getUSDCPerMATIC());
        return (usdcAmount);
    }

    //Shows Matic amount in USDC 6 decimal
    function theUSDCAmount(uint256 maticAmount) private view returns(uint256){
        uint256 maticrate= getUSDCPerMATIC().div(1e2);
        uint256 usdcAmount = maticAmount.mul(maticrate);
        return (usdcAmount.div(1e18));
    }

    //Calculate the value of METAC user will get against their USDC
    function getTokensAmount(uint256 usdcAmount) private view returns(uint256) {
        uint256 tokensAmount = ((usdcAmount*1e12).mul(1e18)).div(tokensAmountForUSDC);
        return tokensAmount;
    }

    //Calculate the matic amount against usdc amount in 18 decimals
    function MaticTokensAmount(uint256 usdcAmount) private view returns(uint256) {
        uint256 tokensAmount = usdcAmount.mul(1e18).div(tokensAmountForUSDC);
        return (tokensAmount.div(1e8));
    }

    // Function to check if locked period has ended or not 
    function checkTime(address add) private view returns(bool) {
        bool ret = ((deposittimes[add] != 0) && (block.timestamp >= (deposittimes[add] + totallockTime)));
        return ret;
    }

    // Owner transfer Matic to their Wallet
    function releaseFunds(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    //Owner transfer all Matic to their wallet
    function releaseFundsAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //User withdraw tokens
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    //Owner withdraw USDC inthe contract
    function recoverUSDC(uint256 tokenAmount) external onlyOwner {
        IERC20(usdcAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(usdcAddress, tokenAmount);
    }
    
    event Recovered(address token, uint256 amount);
}