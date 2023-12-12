// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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

    function pendingTicket(address _collection, address _user, uint256 _tokenId) public view returns (uint256, uint256) {
        uint256 pendingRewards = 0;
        uint256 nextTimestamp = 0;
        
        if (!allowedToStake[_collection])
            return (0, 0);

        if (EnumerableSet.contains(userInfo[_collection][_user].tokenIds, _tokenId)) {
            uint256         rarity = _tokenId / (IERC721A(_collection).totalSupply() / 5);
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

    function addAutoRestake(address _collection, uint256[] calldata _tokenIds) public nonReentrant {
        require(allowedToStake[_collection], "Not allowed to stake for this collection");
        require(_tokenIds.length > 0, "_tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(IERC721A(_collection).ownerOf(_tokenIds[i]) == msg.sender, "Not Your NFT.");

            (uint256 _pendingTickets, uint256 _nextTimestamp) = pendingTicket(_collection, msg.sender, _tokenIds[i]);
            if(_pendingTickets > 0) {
                require(lohTicket.transfer(msg.sender, _pendingTickets), "Reward Token Transfer is failed.");
                if (!userInfo[_collection][msg.sender].autoRestakes[_tokenIds[i]])
                    userInfo[_collection][msg.sender].startTimestamps[_tokenIds[i]] = block.timestamp;
                else
                    userInfo[_collection][msg.sender].startTimestamps[_tokenIds[i]] = _nextTimestamp;
            }

            userInfo[_collection][msg.sender].autoRestakes[_tokenIds[i]] = true;
            userInfo[_collection][msg.sender].isClaimeds[_tokenIds[i]] = false;
            emit AddAutoRestake(_collection, msg.sender, _tokenIds[i]);
        }
    }

    function unStake(address _collection, uint256[] calldata _tokenIds) public nonReentrant {
        require(_tokenIds.length > 0, "_tokenIds parameter has zero length.");

        UserInfo storage _userInfo = userInfo[_collection][msg.sender];
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(EnumerableSet.remove(_userInfo.tokenIds, _tokenIds[i]), "Not your NFT Id.");
            (uint256 _pendingTickets, ) = pendingTicket(_collection, msg.sender, _tokenIds[i]);
            if(_pendingTickets > 0) {
                require(lohTicket.transfer(msg.sender, _pendingTickets), "Reward Token Transfer is failed.");
            }
            IERC721A(_collection).transferFrom(address(this), msg.sender, _tokenIds[i]);
            
            userInfo[_collection][msg.sender].startTimestamps[_tokenIds[i]] = block.timestamp;
            userInfo[_collection][msg.sender].autoRestakes[_tokenIds[i]] = false;
            userInfo[_collection][msg.sender].isClaimeds[_tokenIds[i]] = false;

            emit UnStake(_collection, msg.sender, _tokenIds[i]);
        }
    }

    function claimRewards(address _collection, uint256[] calldata _tokenIds) public nonReentrant {
        require(_tokenIds.length > 0, "tokenIds parameter has zero length.");
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            (uint256 _pendingTickets, uint256 _nextTimestamp) = pendingTicket(_collection, msg.sender, _tokenIds[i]);
            if(_pendingTickets > 0) {
                require(lohTicket.transfer(msg.sender, _pendingTickets), "Reward Token Transfer is failed.");
                userInfo[_collection][msg.sender].startTimestamps[_tokenIds[i]] = _nextTimestamp;
                if (!userInfo[_collection][msg.sender].autoRestakes[_tokenIds[i]])
                    userInfo[_collection][msg.sender].isClaimeds[_tokenIds[i]] = true;
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
}