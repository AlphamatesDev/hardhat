//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RaffleLOH is Ownable {

    struct RaffleInfo {
        string nameRaffle;
        address winner;
        uint256 totalTicketCnt;
        mapping(uint256 => address) userAddressPerTicket;
        mapping(address => uint256) ticketCntPerUser;
    }

    IERC20 public   lohTicketAddress;
    uint256 public  timeStart;
    uint256 public  period1;
    uint256 public  period2;
    uint256 public  cntRaffles;
    mapping(uint256 => RaffleInfo) public raffleInfo;

    event WithdrawAll(address _address);

    receive() payable external {}

    constructor() {
        lohTicketAddress = IERC20(0xf1A5A831ca54AE6AD36a012F5FB2768e6f5d954A);
    }

    function withdrawAll() external onlyOwner {
        uint256 CRObalance = address(this).balance;
        
        if (CRObalance > 0)
            payable(owner()).transfer(CRObalance);

        emit WithdrawAll(msg.sender);
    }

    function withdrawLOHTicket() public onlyOwner returns (bool) {
        uint256 balance = lohTicketAddress.balanceOf(address(this));
        return lohTicketAddress.transfer(msg.sender, balance);
    }

    function setLOHTicketAddress(address _address) public onlyOwner {
        lohTicketAddress = IERC20(_address);
    }

    function setRaffleConditions(uint256 _cntRaffles, uint256 _period1, uint256 _period2) public onlyOwner {
        cntRaffles = _cntRaffles;
        period1 = _period1;
        period2 = _period2;
    }

    function startRaffles() public onlyOwner {
        timeStart = block.timestamp;
        for (uint256 i = 0; i < cntRaffles; i ++) {
            for (uint256 j = 0; j < raffleInfo[i].totalTicketCnt; j ++) {
                address user = raffleInfo[i].userAddressPerTicket[j];
                raffleInfo[i].ticketCntPerUser[user] = 0;
            }
            raffleInfo[i].totalTicketCnt = 0;
            raffleInfo[i].winner = address(0);
        }
    }

    function decideWinners() public onlyOwner {
        require(timeStart + period1 > block.timestamp, "Not finished Depositing time yet!");

        for (uint256 i = 0; i < cntRaffles; i ++) {
            uint256 winnerIndex = getRandomNumber(i, raffleInfo[i].totalTicketCnt);
            raffleInfo[i].winner = raffleInfo[i].userAddressPerTicket[winnerIndex];
        }
    }

    function getRandomNumber(uint256 _indexRaffle, uint256 _totalTickets) public view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, _indexRaffle, _totalTickets, address(this))));
        return seed % _totalTickets;
    }

    function addTicket(uint256 _indexRaffle, uint256 _ticketCnt) public {
        require(timeStart > block.timestamp, "Not started Rafflet yet!");
        require(timeStart + period1 < block.timestamp, "Passed Raffle Time!");

        for (uint256 i = 0; i < _ticketCnt; i ++) {
            raffleInfo[_indexRaffle].userAddressPerTicket[raffleInfo[_indexRaffle].totalTicketCnt] = msg.sender;
            raffleInfo[_indexRaffle].totalTicketCnt ++;
        }
        raffleInfo[_indexRaffle].ticketCntPerUser[msg.sender] += _ticketCnt;
    }

    function getRaffleInfo(address _userAccount) public view returns (
        address[] memory _winners,
        uint256[] memory _totalTicketCnts,
        uint256[] memory _ticketCnt)
    {
        _winners = new address[](cntRaffles);
        _totalTicketCnts = new uint256[](cntRaffles);
        _ticketCnt = new uint256[](cntRaffles);

        for (uint256 i = 0; i < cntRaffles; i ++) {
            _winners[i] = raffleInfo[i].winner;
            _totalTicketCnts[i] = raffleInfo[i].totalTicketCnt;
            _ticketCnt[i] = raffleInfo[i].ticketCntPerUser[_userAccount];
        }
    }
}