// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract StakingPPC is Ownable, ReentrancyGuard {

    address public collectionToStake;
    uint256 public cntStakedRewardableNFT;
    uint256 public rewardSpeedUp;

    struct UserInfo {
        EnumerableSet.UintSet tokenIds;
        mapping(uint256 => uint256) startBlocks;
    }

    mapping(address => UserInfo) userInfo;
    mapping(uint256 => bool) public isClaimed;

    event Stake(address indexed user, uint256 tokenId);
    event UnStake(address indexed user, uint256 tokenId);

    receive() external payable {}

    constructor() {
        collectionToStake = 0xCbA43d9fa84459F91c2D6bEdA2706FE127Ce3d22;
        cntStakedRewardableNFT = 0;
        rewardSpeedUp = 1; // 1x
    }

    function setCollectionToStake(address _collection) external onlyOwner {
        collectionToStake = _collection;
    }

    function setRewardSpeedUp(uint256 _rewardSpeedUp) external onlyOwner {
        rewardSpeedUp = _rewardSpeedUp;
    }

    function setIsClaimed(uint256 _tokenId, bool _isClaimed) external onlyOwner {
        isClaimed[_tokenId] = _isClaimed;
    }

    function getPLSPerBlock() public view returns (uint256) {
        if (cntStakedRewardableNFT == 0) return 0;

        return address(this).balance / (cntStakedRewardableNFT * 3153600) * rewardSpeedUp; //3153600 Blocks per year, 10s per block
    }

    function withdrawTokens() external onlyOwner {
      payable(owner()).transfer(address(this).balance);
    }

    function emergencyWithdraw() external {
        UserInfo storage _userInfo = userInfo[msg.sender];
        require(EnumerableSet.length(_userInfo.tokenIds) > 0, "You have no tokens staked.");
        for(uint256 i = 0; i < EnumerableSet.length(_userInfo.tokenIds); i++) {
            IERC721(collectionToStake).transferFrom(address(this), msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
            if (!isClaimed[EnumerableSet.at(_userInfo.tokenIds, i)])
                cntStakedRewardableNFT --;
            emit UnStake(msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
        }
    }

    function pendingRewardForUser(address _user) public view returns (uint256) {
        UserInfo storage _userInfo = userInfo[_user];
        uint256 pendingRewards = 0;

        for(uint256 i = 0; i < EnumerableSet.length(_userInfo.tokenIds); i++) {
            if (!isClaimed[EnumerableSet.at(_userInfo.tokenIds, i)])
                pendingRewards += ((block.number - _userInfo.startBlocks[EnumerableSet.at(_userInfo.tokenIds, i)]) * getPLSPerBlock());
        }
        return pendingRewards;
    }

    function pendingRewardForTokenId(address _user, uint256 _tokenId) public view returns (uint256) {
        if (isClaimed[_tokenId]) return 0;

        UserInfo storage _userInfo = userInfo[_user];
        uint256 pendingRewards = 0;

        if (EnumerableSet.contains(_userInfo.tokenIds, _tokenId)) {
            pendingRewards = ((block.number - _userInfo.startBlocks[_tokenId]) * getPLSPerBlock());
        }
        return pendingRewards;
    }

    function stake(uint256[] calldata tokenIds) public nonReentrant {
        require(tokenIds.length > 0, "tokenIds parameter has zero length.");

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(IERC721(collectionToStake).ownerOf(tokenIds[i]) == msg.sender, "Not Your NFT.");
            IERC721(collectionToStake).transferFrom(msg.sender, address(this), tokenIds[i]);
            EnumerableSet.add(userInfo[msg.sender].tokenIds, tokenIds[i]);
            userInfo[msg.sender].startBlocks[tokenIds[i]] = block.number;
            if (!isClaimed[tokenIds[i]])
                cntStakedRewardableNFT ++;
            emit Stake(msg.sender, tokenIds[i]);
        }
    }

    function unStake(uint256[] calldata tokenIds) public nonReentrant {
        require(tokenIds.length > 0, "tokenIds parameter has zero length.");

        UserInfo storage _userInfo = userInfo[msg.sender];

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(EnumerableSet.remove(_userInfo.tokenIds, tokenIds[i]), "Not your NFT Id.");
            _userInfo.startBlocks[tokenIds[i]] = block.number;
            IERC721(collectionToStake).transferFrom(address(this), msg.sender, tokenIds[i]);
            if (!isClaimed[tokenIds[i]])
                cntStakedRewardableNFT --;
            emit UnStake(msg.sender, tokenIds[i]);
        }
    }

    function claimRewards(uint256 tokenId) public nonReentrant {
        require(!isClaimed[tokenId], "Already claimed");

        uint256 _pendingRewards = pendingRewardForTokenId(msg.sender, tokenId);
        if(_pendingRewards > 0) {
            payable(msg.sender).transfer(_pendingRewards);
            userInfo[msg.sender].startBlocks[tokenId] = block.number;
            isClaimed[tokenId] = true;
        }
    }

    function claimRewardsForTokens(uint256[] calldata tokenIds) public nonReentrant {
        require(tokenIds.length > 0, "tokenIds parameter has zero length.");
        for(uint256 i = 0; i < tokenIds.length; i++) {
            if(!isClaimed[tokenIds[i]]) {
                uint256 _pendingRewards = pendingRewardForTokenId(msg.sender, tokenIds[i]);
                if(_pendingRewards > 0) {
                    payable(msg.sender).transfer(_pendingRewards);
                    userInfo[msg.sender].startBlocks[tokenIds[i]] = block.number;
                    isClaimed[tokenIds[i]] = true;
                }
            }
        }
    }

    function getStakingInfo(address _user) public view returns(uint256[] memory _tokenIds, bool[] memory _isClaimed, uint256[] memory _pendingRewards) {
        UserInfo storage _userInfo = userInfo[_user];
        uint256 length = EnumerableSet.length(_userInfo.tokenIds);
        _tokenIds = new uint256[](length);
        _isClaimed = new bool[](length);
        _pendingRewards = new uint256[](length);
        for(uint256 i = 0; i < length; i++) {
            _tokenIds[i] = EnumerableSet.at(_userInfo.tokenIds, i);
            _isClaimed[i] = isClaimed[_tokenIds[i]];
            if (!_isClaimed[i])
                _pendingRewards[i] = pendingRewardForTokenId(_user, _tokenIds[i]);
            else
                _pendingRewards[i] = 0;
        }
    }
}