// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract StakingRaijins is Ownable {

    struct RewardCondition {
        uint256 amount;
        uint256 period;
    }

    struct UserInfo {
        EnumerableSet.UintSet       tokenIds;
        mapping(uint256 => uint256) timeTypes;
        mapping(uint256 => uint256) startTimestamps;
        mapping(uint256 => bool)    autoRestakes;
        mapping(uint256 => bool)    isClaimeds;
    }

    struct StakingInfo {
        address _address;
        uint256 _tokenId;
        uint256 _timeType;
        uint256 _startTimestamp;
        bool    _autoRestake;
        bool    _isClaimed;
        uint256 _pendingTicket;
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

    IERC20 public raijinsTicket;
    
    mapping(address => bool) public allowedToStake;

    mapping(address => uint256) public rarityPerCollection;

    mapping(address => string) public namePerCollection;

    /* 4: Time Types, 5: Rarity Types */
    RewardCondition[5][4] public rewardCondition;

    bool public autoRestakeAsDefault;

    mapping(address => mapping(address => UserInfo)) userInfo;

    event Stake(address indexed collection, address indexed user, uint256 tokenId, uint256 timeType);
    event AddAutoRestake(address indexed collection, address indexed user, uint256 tokenId);
    event UnStake(address indexed collection, address indexed user, uint256 tokenId);

    constructor() {
        raijinsTicket = IERC20(0xd22bdF42215144Cf46F1725431002a5a388e3E6E);

        allowedToStake[0x74847697754Aa2063FE180D6CD246AA82Fa773ff] = true;

        rarityPerCollection[0x74847697754Aa2063FE180D6CD246AA82Fa773ff] = 0;

        namePerCollection[0x74847697754Aa2063FE180D6CD246AA82Fa773ff] = "Blue Raijins";
        
        autoRestakeAsDefault = true;
        
        rewardCondition[0][0].amount = 5 * 10 ** 18;
        rewardCondition[0][0].period = 604800;


        rewardCondition[1][0].amount = 21 * 10 ** 18;
        rewardCondition[1][0].period = 2592000;


        rewardCondition[2][0].amount = 43 * 10 ** 18;
        rewardCondition[2][0].period = 5184000;

        rewardCondition[3][0].amount = 70 * 10 ** 18;
        rewardCondition[3][0].period = 7776000;
    }


    function setRewardCondition(uint256 _timeType, uint256 _rarity, uint256 _amount, uint256 _period) external onlyOwner {
        rewardCondition[_timeType][_rarity].amount = _amount;
        rewardCondition[_timeType][_rarity].period = _period;
    }

    function setRewardTokenAddress(address _rewardTokenAddress) external onlyOwner {
        raijinsTicket = IERC20(_rewardTokenAddress);
    }

    function allowCollectionToStake(address _collection, bool _allow) external onlyOwner {
        allowedToStake[_collection] = _allow;
    }

    function setAutoRestakeAsDefault(bool _autoRestakeAsDefault) external onlyOwner {
        autoRestakeAsDefault = _autoRestakeAsDefault;
    }

    function withdrawTickets() external onlyOwner {
      raijinsTicket.transfer(msg.sender, raijinsTicket.balanceOf(address(this)));
    }

    function emergencyWithdraw(address _collection) external {
        UserInfo storage _userInfo = userInfo[_collection][msg.sender];
        require(EnumerableSet.length(_userInfo.tokenIds) > 0, "You have no tokens staked.");
        for(uint256 i = 0; i < EnumerableSet.length(_userInfo.tokenIds); i++) {
            IERC721(_collection).transferFrom(address(this), msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
            emit UnStake(_collection, msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
        }
    }

    function pendingTicket(address _collection, address _user, uint256 _tokenId) public view returns (uint256, uint256) {
        uint256 pendingRewards = 0;
        uint256 nextTimestamp = 0;
        
        if (!allowedToStake[_collection])
            return (0, 0);

        if (EnumerableSet.contains(userInfo[_collection][_user].tokenIds, _tokenId)) {
            uint256         rarity = getRarity(_collection);
            uint256         timeType = userInfo[_collection][_user].timeTypes[_tokenId];
            uint256         startTimestamp = userInfo[_collection][_user].startTimestamps[_tokenId];
            bool            autoRestake = userInfo[_collection][_user].autoRestakes[_tokenId];
            bool            isClaimed = userInfo[_collection][_user].isClaimeds[_tokenId];
            RewardCondition memory condition = rewardCondition[timeType][rarity];

            if (!autoRestake) {
                if (isClaimed)
                    pendingRewards = 0;
                else if (block.timestamp - startTimestamp >= condition.period)
                    pendingRewards = condition.amount;
                nextTimestamp = startTimestamp;
            } else {
                pendingRewards = condition.amount * ((block.timestamp - startTimestamp) / condition.period);
                nextTimestamp = startTimestamp + ((block.timestamp - startTimestamp) / condition.period) * condition.period;
            }
        }
        return (pendingRewards, nextTimestamp);
    }

    function stake(address[] calldata _collections, uint256[] calldata _tokenIds, uint256[] calldata _timeTypes) public {
        require(_tokenIds.length > 0, "tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(allowedToStake[_collections[i]], "Not allowed to stake for this collection");
            require(IERC721(_collections[i]).ownerOf(_tokenIds[i]) == msg.sender, "Not Your NFT.");
            userInfo[_collections[i]][msg.sender].startTimestamps[_tokenIds[i]] = block.timestamp;
            userInfo[_collections[i]][msg.sender].timeTypes[_tokenIds[i]] = _timeTypes[i];
            userInfo[_collections[i]][msg.sender].autoRestakes[_tokenIds[i]] = autoRestakeAsDefault;
            IERC721(_collections[i]).transferFrom(msg.sender, address(this), _tokenIds[i]);
            EnumerableSet.add(userInfo[_collections[i]][msg.sender].tokenIds, _tokenIds[i]);
            emit Stake(_collections[i], msg.sender, _tokenIds[i], _timeTypes[i]);
        }
    }

    function addAutoRestake(address[] calldata _collections, uint256[] calldata _tokenIds) public {
        require(_tokenIds.length > 0, "_tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(allowedToStake[_collections[i]], "Not allowed to stake for this collection");
            require(EnumerableSet.contains(userInfo[_collections[i]][msg.sender].tokenIds, _tokenIds[i]), "Not Your NFT.");

            (uint256 _pendingTickets, uint256 _nextTimestamp) = pendingTicket(_collections[i], msg.sender, _tokenIds[i]);
            if(_pendingTickets > 0) {
                require(raijinsTicket.transfer(msg.sender, _pendingTickets), "Reward Token Transfer is failed.");
                if (!userInfo[_collections[i]][msg.sender].autoRestakes[_tokenIds[i]])
                    userInfo[_collections[i]][msg.sender].startTimestamps[_tokenIds[i]] = block.timestamp;
                else
                    userInfo[_collections[i]][msg.sender].startTimestamps[_tokenIds[i]] = _nextTimestamp;
            }

            userInfo[_collections[i]][msg.sender].autoRestakes[_tokenIds[i]] = true;
            userInfo[_collections[i]][msg.sender].isClaimeds[_tokenIds[i]] = false;
            emit AddAutoRestake(_collections[i], msg.sender, _tokenIds[i]);
        }
    }

    function removeAutoRestake(address[] calldata _collections, uint256[] calldata _tokenIds) public {
        require(_tokenIds.length > 0, "_tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(allowedToStake[_collections[i]], "Not allowed to stake for this collection");
            require(EnumerableSet.contains(userInfo[_collections[i]][msg.sender].tokenIds, _tokenIds[i]), "Not Your NFT.");

            userInfo[_collections[i]][msg.sender].autoRestakes[_tokenIds[i]] = false;
            emit AddAutoRestake(_collections[i], msg.sender, _tokenIds[i]);
        }
    }

    function unStake(address[] calldata _collections, uint256[] calldata _tokenIds) public {
        require(_tokenIds.length > 0, "_tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            UserInfo storage _userInfo = userInfo[_collections[i]][msg.sender];
            require(EnumerableSet.contains(_userInfo.tokenIds, _tokenIds[i]), "Not Your NFT.");
            (uint256 _pendingTickets, ) = pendingTicket(_collections[i], msg.sender, _tokenIds[i]);
            if(_pendingTickets > 0) {
                require(raijinsTicket.transfer(msg.sender, _pendingTickets), "Reward Token Transfer is failed.");
            }
            require(EnumerableSet.remove(_userInfo.tokenIds, _tokenIds[i]), "Not your NFT Id.");
            IERC721(_collections[i]).transferFrom(address(this), msg.sender, _tokenIds[i]);
            
            userInfo[_collections[i]][msg.sender].startTimestamps[_tokenIds[i]] = block.timestamp;
            userInfo[_collections[i]][msg.sender].autoRestakes[_tokenIds[i]] = false;
            userInfo[_collections[i]][msg.sender].isClaimeds[_tokenIds[i]] = false;

            emit UnStake(_collections[i], msg.sender, _tokenIds[i]);
        }
    }

    function claimRewards(address[] calldata _collections, uint256[] calldata _tokenIds) public {
        require(_tokenIds.length > 0, "tokenIds parameter has zero length.");
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            (uint256 _pendingTickets, uint256 _nextTimestamp) = pendingTicket(_collections[i], msg.sender, _tokenIds[i]);
            if(_pendingTickets > 0) {
                require(raijinsTicket.transfer(msg.sender, _pendingTickets), "Reward Token Transfer is failed.");
                userInfo[_collections[i]][msg.sender].startTimestamps[_tokenIds[i]] = _nextTimestamp;
                if (!userInfo[_collections[i]][msg.sender].autoRestakes[_tokenIds[i]])
                    userInfo[_collections[i]][msg.sender].isClaimeds[_tokenIds[i]] = true;
            }
        }
    }

    function setRarity(address _collection, uint256 _rarity) external onlyOwner {
        rarityPerCollection[_collection] = _rarity;
    }

    function getRarity(address _collection) public view returns (uint256) {
        return rarityPerCollection[_collection];
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
                _nftsStaked[tempCnt]._timeType = _userInfo.timeTypes[_nftsStaked[tempCnt]._tokenId];
                _nftsStaked[tempCnt]._startTimestamp = _userInfo.startTimestamps[_nftsStaked[tempCnt]._tokenId];
                _nftsStaked[tempCnt]._autoRestake = _userInfo.autoRestakes[_nftsStaked[tempCnt]._tokenId];
                _nftsStaked[tempCnt]._isClaimed = _userInfo.isClaimeds[_nftsStaked[tempCnt]._tokenId];
                (_nftsStaked[tempCnt]._pendingTicket, ) = pendingTicket(_collections[kkk], _user, _nftsStaked[tempCnt]._tokenId);
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