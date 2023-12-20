// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IERC721A {
    error ApprovalCallerNotOwnerNorApproved();

    error ApprovalQueryForNonexistentToken();

    error ApproveToCaller();

    error BalanceQueryForZeroAddress();

    error MintToZeroAddress();

    error MintZeroQuantity();

    error OwnerQueryForNonexistentToken();

    error TransferCallerNotOwnerNorApproved();

    error TransferFromIncorrectOwner();

    error TransferToNonERC721ReceiverImplementer();

    error TransferToZeroAddress();

    error URIQueryForNonexistentToken();

    error MintERC2309QuantityExceedsLimit();

    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    function totalSupply() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

interface IERC721AQueryable is IERC721A {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

contract StakingLOH is Ownable, ReentrancyGuard {

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

    IERC20 public lohTicket;
    mapping(address => bool) public allowedToStake;

    /* 5: Rarity Types, 4: Time Types */
    RewardCondition[5][4] rewardCondition;

    mapping(address => mapping(address => UserInfo)) userInfo;

    event Stake(address indexed collection, address indexed user, uint256 tokenId, uint256 timeType);
    event AddAutoRestake(address indexed collection, address indexed user, uint256 tokenId);
    event UnStake(address indexed collection, address indexed user, uint256 tokenId);

    constructor() {
        lohTicket = IERC20(0xf1A5A831ca54AE6AD36a012F5FB2768e6f5d954A);
        allowedToStake[0x51084c32AA5ee43a0e7bD8220195da53b5c69868] = true; // Volume 1
        allowedToStake[0x770FA15c43b84F61434321F5167814b64790E6Fa] = true; // Reapers
        
        rewardCondition[0][0].amount = 1;
        rewardCondition[0][1].amount = 2;
        rewardCondition[0][2].amount = 3;
        rewardCondition[0][3].amount = 4;
        rewardCondition[0][4].amount = 5;
        rewardCondition[0][0].period = 604800;
        rewardCondition[0][1].period = 604800;
        rewardCondition[0][2].period = 604800;
        rewardCondition[0][3].period = 604800;
        rewardCondition[0][4].period = 604800;

        rewardCondition[1][0].amount = 5;
        rewardCondition[1][1].amount = 9;
        rewardCondition[1][2].amount = 14;
        rewardCondition[1][3].amount = 17;
        rewardCondition[1][4].amount = 21;
        rewardCondition[1][0].period = 2592000;
        rewardCondition[1][1].period = 2592000;
        rewardCondition[1][2].period = 2592000;
        rewardCondition[1][3].period = 2592000;
        rewardCondition[1][4].period = 2592000;

        rewardCondition[2][0].amount = 11;
        rewardCondition[2][1].amount = 19;
        rewardCondition[2][2].amount = 29;
        rewardCondition[2][3].amount = 36;
        rewardCondition[2][4].amount = 43;
        rewardCondition[2][0].period = 5184000;
        rewardCondition[2][1].period = 5184000;
        rewardCondition[2][2].period = 5184000;
        rewardCondition[2][3].period = 5184000;
        rewardCondition[2][4].period = 5184000;

        rewardCondition[3][0].amount = 17;
        rewardCondition[3][1].amount = 31;
        rewardCondition[3][2].amount = 47;
        rewardCondition[3][3].amount = 59;
        rewardCondition[3][4].amount = 70;
        rewardCondition[3][0].period = 7776000;
        rewardCondition[3][1].period = 7776000;
        rewardCondition[3][2].period = 7776000;
        rewardCondition[3][3].period = 7776000;
        rewardCondition[3][4].period = 7776000;
    }

    function setRewardTokenAddress(address _rewardTokenAddress) external onlyOwner {
        lohTicket = IERC20(_rewardTokenAddress);
    }

    function allowCollectionToStake(address _collection, bool _allow) external onlyOwner {
        allowedToStake[_collection] = _allow;
    }

    function withdrawTickets() external onlyOwner {
      lohTicket.transfer(msg.sender, lohTicket.balanceOf(address(this)));
    }

    function emergencyWithdraw(address _collection) external {
        UserInfo storage _userInfo = userInfo[_collection][msg.sender];
        require(EnumerableSet.length(_userInfo.tokenIds) > 0, "You have no tokens staked.");
        for(uint256 i = 0; i < EnumerableSet.length(_userInfo.tokenIds); i++) {
            IERC721A(_collection).transferFrom(address(this), msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
            emit UnStake(_collection, msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
        }
    }

    function getRarity(address _collection, uint256 _tokenId) public pure returns (uint256) {
        if (_collection == 0x770FA15c43b84F61434321F5167814b64790E6Fa)
            return 4;

        if (_tokenId >= 1 && _tokenId <= 150)
            return 3;
        else if (_tokenId >= 151 && _tokenId <= 450)
            return 2;
        else if (_tokenId >= 451 && _tokenId <= 900)
            return 1;
        else if (_tokenId >= 901 && _tokenId <= 3000)
            return 0;

        return 0;
    }

    function pendingTicket(address _collection, address _user, uint256 _tokenId) public view returns (uint256, uint256) {
        uint256 pendingRewards = 0;
        uint256 nextTimestamp = 0;
        
        if (!allowedToStake[_collection])
            return (0, 0);

        if (EnumerableSet.contains(userInfo[_collection][_user].tokenIds, _tokenId)) {
            uint256         rarity = getRarity(_collection, _tokenId);
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
                nextTimestamp += uint256((block.timestamp - startTimestamp) / condition.period) * condition.period;
            }
        }
        return (pendingRewards, nextTimestamp);
    }

    function stake(address[] calldata _collections, uint256[] calldata _tokenIds, uint256[] calldata _timeTypes) public nonReentrant {
        require(_tokenIds.length > 0, "tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(allowedToStake[_collections[i]], "Not allowed to stake for this collection");
            require(IERC721A(_collections[i]).ownerOf(_tokenIds[i]) == msg.sender, "Not Your NFT.");
            userInfo[_collections[i]][msg.sender].startTimestamps[_tokenIds[i]] = block.timestamp;
            userInfo[_collections[i]][msg.sender].timeTypes[_tokenIds[i]] = _timeTypes[i];
            userInfo[_collections[i]][msg.sender].autoRestakes[_tokenIds[i]] = false;
            IERC721A(_collections[i]).transferFrom(msg.sender, address(this), _tokenIds[i]);
            EnumerableSet.add(userInfo[_collections[i]][msg.sender].tokenIds, _tokenIds[i]);
            emit Stake(_collections[i], msg.sender, _tokenIds[i], _timeTypes[i]);
        }
    }

    function addAutoRestake(address[] calldata _collections, uint256[] calldata _tokenIds) public nonReentrant {
        require(_tokenIds.length > 0, "_tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(allowedToStake[_collections[i]], "Not allowed to stake for this collection");
            require(EnumerableSet.contains(userInfo[_collections[i]][msg.sender].tokenIds, _tokenIds[i]), "Not Your NFT.");

            (uint256 _pendingTickets, uint256 _nextTimestamp) = pendingTicket(_collections[i], msg.sender, _tokenIds[i]);
            if(_pendingTickets > 0) {
                require(lohTicket.transfer(msg.sender, _pendingTickets), "Reward Token Transfer is failed.");
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

    function removeAutoRestake(address[] calldata _collections, uint256[] calldata _tokenIds) public nonReentrant {
        require(_tokenIds.length > 0, "_tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(allowedToStake[_collections[i]], "Not allowed to stake for this collection");
            require(EnumerableSet.contains(userInfo[_collections[i]][msg.sender].tokenIds, _tokenIds[i]), "Not Your NFT.");

            userInfo[_collections[i]][msg.sender].autoRestakes[_tokenIds[i]] = false;
            emit AddAutoRestake(_collections[i], msg.sender, _tokenIds[i]);
        }
    }

    function unStake(address[] calldata _collections, uint256[] calldata _tokenIds) public nonReentrant {
        require(_tokenIds.length > 0, "_tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            UserInfo storage _userInfo = userInfo[_collections[i]][msg.sender];
            require(EnumerableSet.remove(_userInfo.tokenIds, _tokenIds[i]), "Not your NFT Id.");
            (uint256 _pendingTickets, ) = pendingTicket(_collections[i], msg.sender, _tokenIds[i]);
            if(_pendingTickets > 0) {
                require(lohTicket.transfer(msg.sender, _pendingTickets), "Reward Token Transfer is failed.");
            }
            IERC721A(_collections[i]).transferFrom(address(this), msg.sender, _tokenIds[i]);
            
            userInfo[_collections[i]][msg.sender].startTimestamps[_tokenIds[i]] = block.timestamp;
            userInfo[_collections[i]][msg.sender].autoRestakes[_tokenIds[i]] = false;
            userInfo[_collections[i]][msg.sender].isClaimeds[_tokenIds[i]] = false;

            emit UnStake(_collections[i], msg.sender, _tokenIds[i]);
        }
    }

    function claimRewards(address[] calldata _collections, uint256[] calldata _tokenIds) public nonReentrant {
        require(_tokenIds.length > 0, "tokenIds parameter has zero length.");
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            (uint256 _pendingTickets, uint256 _nextTimestamp) = pendingTicket(_collections[i], msg.sender, _tokenIds[i]);
            if(_pendingTickets > 0) {
                require(lohTicket.transfer(msg.sender, _pendingTickets), "Reward Token Transfer is failed.");
                userInfo[_collections[i]][msg.sender].startTimestamps[_tokenIds[i]] = _nextTimestamp;
                if (!userInfo[_collections[i]][msg.sender].autoRestakes[_tokenIds[i]])
                    userInfo[_collections[i]][msg.sender].isClaimeds[_tokenIds[i]] = true;
            }
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

    function getTokensInWallet(address[] calldata _collections) public view returns (TokenInfo[] memory _tokensInWallet) {
        uint256 tokenCnt = 0;
        for (uint256 i = 0; i < _collections.length; i ++) {
            if (allowedToStake[_collections[i]] == true)
                tokenCnt += IERC721AQueryable(_collections[i]).tokensOfOwner(msg.sender).length;
        }

        if (tokenCnt == 0)
            return _tokensInWallet;

        _tokensInWallet = new TokenInfo[](tokenCnt);

        uint256 tempCnt = 0;

        for (uint256 i = 0; i < _collections.length; i ++) {
            if (allowedToStake[_collections[i]] == true) {
                uint256[] memory tokenIds = IERC721AQueryable(_collections[i]).tokensOfOwner(msg.sender);
                string memory tokenName = IERC721A(_collections[i]).name();
                
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
                _approvalStatus[tempCnt].isApproval = IERC721A(_collections[i]).isApprovedForAll(_user, address(this));
                tempCnt ++;
            }
        }

        return _approvalStatus;
    }
}