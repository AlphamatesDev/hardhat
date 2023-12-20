//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RaffleLOH is Ownable {

    struct RaffleInfo {
        string  value;
        int256  winnerIndex;
        address winner;
        uint256 totalTicketCnt;
        mapping(uint256 => address) userAddressPerTicket;
        mapping(address => uint256) ticketCntPerUser;
        bool    isFinished;
        bool    isDisabled;
    }

    struct RaffleStatus {
        string  value;
        int256  winnerIndex;
        address winner;
        uint256 totalTicketCnt;
        uint256 ticketCntForUser;
        bool    isFinished;
        bool    isDisabled;
    }

    IERC20 public   lohTicketAddress;
    uint256 public  timeStart;
    uint256 public  period;
    uint256 public  cntRaffles;
    mapping(uint256 => RaffleInfo) public raffleInfo;

    event WithdrawAll(address _address);

    receive() payable external {}

    constructor() {
        lohTicketAddress = IERC20(0xf1A5A831ca54AE6AD36a012F5FB2768e6f5d954A);
        cntRaffles = 21;
        period = 2160000;
    }

    function withdrawLOHTicket() public onlyOwner returns (bool) {
        uint256 balance = lohTicketAddress.balanceOf(address(this));
        return lohTicketAddress.transfer(msg.sender, balance);
    }

    function setLOHTicketAddress(address _address) public onlyOwner {
        lohTicketAddress = IERC20(_address);
    }

    function setRaffleCount(uint256 _cntRaffles) public onlyOwner {
        cntRaffles = _cntRaffles;
    }

    function setPeriodToDeposit(uint256 _period) public onlyOwner {
        period = _period;
    }

    function setRaffleValue(uint256 _raffleIndex, string memory _raffleValue) public onlyOwner {
        raffleInfo[_raffleIndex].value = _raffleValue;
    }

    function setRaffleDisable(uint256 _raffleIndex, bool _isDisabled) public onlyOwner {
        raffleInfo[_raffleIndex].isDisabled = _isDisabled;
    }

    function startRaffles() public onlyOwner {
        timeStart = block.timestamp;
        for (uint256 i = 0; i < cntRaffles; i ++) {
            for (uint256 j = 0; j < raffleInfo[i].totalTicketCnt; j ++) {
                address user = raffleInfo[i].userAddressPerTicket[j];
                raffleInfo[i].ticketCntPerUser[user] = 0;
            }
            raffleInfo[i].totalTicketCnt = 0;
            raffleInfo[i].winnerIndex = -1;
            raffleInfo[i].winner = address(0);
            raffleInfo[i].isFinished = false;
        }
    }

    function decideWinners() public onlyOwner {
        require(timeStart + period < block.timestamp, "Not finished Depositing time yet!");

        for (uint256 i = 0; i < cntRaffles; i ++) {
            if (raffleInfo[i].totalTicketCnt > 0) {
                uint256 winnerIndex = getRandomNumber(i, raffleInfo[i].totalTicketCnt);
                raffleInfo[i].winnerIndex = int256(winnerIndex);
                raffleInfo[i].winner = raffleInfo[i].userAddressPerTicket[winnerIndex];
            }
            raffleInfo[i].isFinished = true;
        }
    }

    function getRandomNumber(uint256 _indexRaffle, uint256 _totalTickets) public view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, _indexRaffle, _totalTickets, address(this))));
        return seed % _totalTickets;
    }

    function addTicket(uint256 _indexRaffle, uint256 _ticketCnt) public {
        require(timeStart < block.timestamp, "Not started Rafflet yet!");
        require(timeStart + period > block.timestamp, "Passed Raffle Time!");
        require(!raffleInfo[_indexRaffle].isFinished, "Finished Raffle");
        require(!raffleInfo[_indexRaffle].isDisabled, "Disabled Raffle");

        for (uint256 i = 0; i < _ticketCnt; i ++) {
            raffleInfo[_indexRaffle].userAddressPerTicket[raffleInfo[_indexRaffle].totalTicketCnt] = msg.sender;
            raffleInfo[_indexRaffle].totalTicketCnt ++;
        }
        raffleInfo[_indexRaffle].ticketCntPerUser[msg.sender] += _ticketCnt;
    }

    function getRaffleInfo(address _userAccount) public view returns (RaffleStatus[] memory _rafflesForUser)
    {
        _rafflesForUser = new RaffleStatus[](cntRaffles);

        for (uint256 i = 0; i < cntRaffles; i ++) {
            _rafflesForUser[i].value = raffleInfo[i].value;
            _rafflesForUser[i].winnerIndex = raffleInfo[i].winnerIndex;
            _rafflesForUser[i].winner = raffleInfo[i].winner;
            _rafflesForUser[i].totalTicketCnt = raffleInfo[i].totalTicketCnt;
            _rafflesForUser[i].ticketCntForUser = raffleInfo[i].ticketCntPerUser[_userAccount];
            _rafflesForUser[i].isFinished = raffleInfo[i].isFinished;
            _rafflesForUser[i].isDisabled = raffleInfo[i].isDisabled;
        }
    }
}