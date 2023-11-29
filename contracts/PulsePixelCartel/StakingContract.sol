// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract StakingContract is Ownable, ReentrancyGuard {

    address public collectionToStake;
    uint256 public cntStakedNFT;
    uint256 public rewardSpeedUp;

    struct UserInfo {
        EnumerableSet.UintSet tokenIds;
        mapping(uint256 => uint256) startBlocks;
    }

    mapping(address => UserInfo) userInfo;
    mapping(uint256 => bool) public isClaimed;

    event Stake(address indexed user, uint256 tokenId);
    event UnStake(address indexed user, uint256 tokenId);

    constructor() {
        collectionToStake = 0x74c46bAdaDaF2f6bca40ba252B9B130DF2b7bD4d;
        rewardSpeedUp = 1; // 1x
    }

    function setCollectionToStake(address _collection) external onlyOwner {
        collectionToStake = _collection;
    }

    function setRewardSpeedUp(uint256 _rewardSpeedUp) external onlyOwner {
        rewardSpeedUp = _rewardSpeedUp;
    }

    function getPLSPerBlock() public view returns (uint256) {
        return address(this).balance / (cntStakedNFT * 3153600) * rewardSpeedUp;
    }

    function withdrawTokens() external onlyOwner {
      payable(owner()).transfer(address(this).balance);
    }

    function emergencyWithdraw() external {
        UserInfo storage _userInfo = userInfo[msg.sender];
        require(EnumerableSet.length(_userInfo.tokenIds) > 0, "You have no tokens staked.");
        for(uint256 i = 0; i < EnumerableSet.length(_userInfo.tokenIds); i++) {
            IERC721(collectionToStake).transferFrom(address(this), msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
            cntStakedNFT --;
            emit UnStake(msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
        }
    }

    function pendingRewardForUser(address _user) public view returns (uint256) {
        UserInfo storage _userInfo = userInfo[_user];
        uint256 pendingRewards = 0;

        for(uint256 i = 0; i < EnumerableSet.length(_userInfo.tokenIds); i++) {
            pendingRewards += ((block.number - _userInfo.startBlocks[EnumerableSet.at(_userInfo.tokenIds, i)]) * getPLSPerBlock());
        }
        return pendingRewards;
    }

    function pendingRewardForTokenId(address _user, uint256 _tokenId) public view returns (uint256) {
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
            cntStakedNFT ++;
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
            cntStakedNFT --;
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

    function getStakingInfo(address _user) public view returns(uint256[] memory _tokenIds, uint256 _pendingRewards) {
        UserInfo storage _userInfo = userInfo[_user];
        uint256 length = EnumerableSet.length(_userInfo.tokenIds);
        _tokenIds = new uint256[](length);
        for(uint256 i = 0; i < length; i++) {
            _tokenIds[i] = EnumerableSet.at(_userInfo.tokenIds, i);
        }
        _pendingRewards = pendingRewardForUser(_user);
    }
}