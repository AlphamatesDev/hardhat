// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract StakingRaijinsMatic is Ownable {

    struct UserInfo {
        EnumerableSet.UintSet   tokenIds;
        uint256                 claimedReward;
        uint256                 pendingReward;
    }

    struct StakingInfo {
        address _address;
        uint256 _tokenId;
    }

    struct TokenInfo {
        address token_address;
        string  name;
        uint256 token_id;
    }

    struct ApprovalStatus {
        address token_address;
        bool    isApproval;
    }

    mapping(address => bool) public allowedToStake;

    mapping(address => string) public namePerCollection;

    mapping(address => mapping(address => UserInfo)) userInfo;

    uint256 public totalDistributed;
    mapping(uint256 => address) public userPerItem;

    event Stake(address indexed collection, address indexed user, uint256 tokenId);
    event UnStake(address indexed collection, address indexed user, uint256 tokenId);
    event ClaimRewards(address indexed collection, address indexed user, uint256 amount);

    receive() payable external {}
    fallback() payable external {}

    constructor() {
        allowedToStake[0x74847697754Aa2063FE180D6CD246AA82Fa773ff] = true;

        namePerCollection[0x74847697754Aa2063FE180D6CD246AA82Fa773ff] = "Blue Raijins";
    }

    function allowCollectionToStake(address _collection, bool _allow) external onlyOwner {
        allowedToStake[_collection] = _allow;
    }

    function emergencyWithdraw(address _collection) external {
        UserInfo storage _userInfo = userInfo[_collection][msg.sender];
        require(EnumerableSet.length(_userInfo.tokenIds) > 0, "You have no tokens staked.");
        for(uint256 i = 0; i < EnumerableSet.length(_userInfo.tokenIds); i++) {
            IERC721(_collection).transferFrom(address(this), msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
            emit UnStake(_collection, msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
        }
    }

    function withdrawMatic(uint256 _amount) external onlyOwner {
        uint256 maticBalance = address(this).balance;

        require(_amount <= maticBalance, "Invalid withdraw amount");
        
        if (_amount > 0)
            payable(owner()).transfer(_amount);
    }

    function stake(address[] calldata _collections, uint256[] calldata _tokenIds) public {
        require(_tokenIds.length > 0, "tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(allowedToStake[_collections[i]], "Not allowed to stake for this collection");
            require(IERC721(_collections[i]).ownerOf(_tokenIds[i]) == msg.sender, "Not Your NFT.");

            IERC721(_collections[i]).transferFrom(msg.sender, address(this), _tokenIds[i]);
            EnumerableSet.add(userInfo[_collections[i]][msg.sender].tokenIds, _tokenIds[i]);
            userPerItem[_tokenIds[i]] = msg.sender;

            emit Stake(_collections[i], msg.sender, _tokenIds[i]);
        }
    }

    function unStake(address[] calldata _collections, uint256[] calldata _tokenIds) public {
        require(_tokenIds.length > 0, "_tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            UserInfo storage _userInfo = userInfo[_collections[i]][msg.sender];
            require(EnumerableSet.contains(_userInfo.tokenIds, _tokenIds[i]), "Not Your NFT.");
            require(EnumerableSet.remove(_userInfo.tokenIds, _tokenIds[i]), "Not your NFT Id.");
            IERC721(_collections[i]).transferFrom(address(this), msg.sender, _tokenIds[i]);
            
            emit UnStake(_collections[i], msg.sender, _tokenIds[i]);
        }
    }

    function distributeMatic(address _collection) external payable onlyOwner {
        require(msg.value > 0, "Invalid distribution amount!");

        uint256 tokenCount = IERC721(_collection).balanceOf(address(this));
        uint256 distributeAmountPerNFT = msg.value / tokenCount;

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = IERC721Enumerable(_collection).tokenOfOwnerByIndex(address(this), i);
            address userStaked = userPerItem[tokenId];
            userInfo[_collection][userStaked].pendingReward += distributeAmountPerNFT;
        }

        totalDistributed = totalDistributed + msg.value;
    }

    function claimRewards(address _collection) public {
        require(allowedToStake[_collection], "Not allowed to stake for this collection");
        
        uint256 pendingReward = userInfo[_collection][msg.sender].pendingReward;
        require(pendingReward > 0, "Invalind pending amount");

        payable(msg.sender).transfer(pendingReward);

        userInfo[_collection][msg.sender].pendingReward = 0;
        userInfo[_collection][msg.sender].claimedReward += pendingReward;

        emit ClaimRewards(_collection, msg.sender, pendingReward);
    }

    function setNamePerCollection(address _collection, string memory _name) external onlyOwner {
        namePerCollection[_collection] = _name;
    }

    function tokensOfOwner(address _collection, address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = IERC721(_collection).balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++) {
                result[i] = IERC721Enumerable(_collection).tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function getUserStatus(address _collection, address _user) public view returns(uint256 _claimedReward, uint256 _pendingReward) {
        _claimedReward = userInfo[_collection][_user].claimedReward;
        _pendingReward = userInfo[_collection][_user].pendingReward;
    }

    function getStakingInfo(address[] calldata _collections, address _user) public view returns (StakingInfo[] memory _nftsStaked)
    {
        uint256 nftCnt = 0;
        for (uint256 kkk = 0; kkk < _collections.length; kkk ++)
            nftCnt += EnumerableSet.length(userInfo[_collections[kkk]][_user].tokenIds);

        _nftsStaked = new StakingInfo[](nftCnt);

        uint256 tempCnt = 0;

        for (uint256 kkk = 0; kkk < _collections.length; kkk ++) {
            UserInfo storage _userInfo = userInfo[_collections[kkk]][_user];
            uint256 length = EnumerableSet.length(_userInfo.tokenIds);

            for(uint256 i = 0; i < length; i++) {
                _nftsStaked[tempCnt]._address = _collections[kkk];
                _nftsStaked[tempCnt]._tokenId = EnumerableSet.at(_userInfo.tokenIds, i);
                tempCnt ++;
            }
        }
    }

    function getTokensInWallet(address[] calldata _collections, address _user) public view returns (TokenInfo[] memory _tokensInWallet) {
        uint256 tokenCnt = 0;
        for (uint256 i = 0; i < _collections.length; i ++) {
            if (allowedToStake[_collections[i]] == true)
                tokenCnt += tokensOfOwner(_collections[i], _user).length;
        }

        if (tokenCnt == 0)
            return _tokensInWallet;

        _tokensInWallet = new TokenInfo[](tokenCnt);

        uint256 tempCnt = 0;

        for (uint256 i = 0; i < _collections.length; i ++) {
            if (allowedToStake[_collections[i]] == true) {
                uint256[] memory tokenIds = tokensOfOwner(_collections[i], _user);
                string memory tokenName = namePerCollection[_collections[i]];
                
                for (uint256 j = 0; j < tokenIds.length; j ++) {
                    _tokensInWallet[tempCnt].token_address = _collections[i];
                    _tokensInWallet[tempCnt].name = tokenName;
                    _tokensInWallet[tempCnt].token_id = tokenIds[j];
                    tempCnt ++;
                }
            }
        }
        return _tokensInWallet;
    }

    function getApprovalStatus(address[] calldata _collections, address _user) public view returns (ApprovalStatus[] memory _approvalStatus) {
        uint256 collectionCnt = 0;
        for (uint256 i = 0; i < _collections.length; i ++) {
            if (allowedToStake[_collections[i]] == true)
                collectionCnt ++;
        }

        _approvalStatus = new ApprovalStatus[](collectionCnt);

        uint256 tempCnt = 0;

        for (uint256 i = 0; i < _collections.length; i ++) {
            if (allowedToStake[_collections[i]] == true) {
                _approvalStatus[tempCnt].token_address = _collections[i];
                _approvalStatus[tempCnt].isApproval = IERC721(_collections[i]).isApprovedForAll(_user, address(this));
                tempCnt ++;
            }
        }

        return _approvalStatus;
    }
}