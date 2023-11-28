// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract StakingContract is Ownable, ReentrancyGuard {

    uint256 rewardTokenPerBlock;
    address public collectionToStake;

    struct UserInfo {
        EnumerableSet.UintSet tokenIds;
        uint256 startBlock;
    }

    mapping(address => UserInfo) userInfo;

    event Stake(address indexed collection, address indexed user, uint256 tokenId);
    event UnStake(address indexed collection, address indexed user, uint256 tokenId);

    constructor() {
    }

    function setCollectionToStake(address _collection) external onlyOwner {
        collectionToStake = _collection;
    }

    function setRewardTokenPerBlock(uint256 _rewardTokenPerBlock) external onlyOwner {
        rewardTokenPerBlock = _rewardTokenPerBlock;
    }

    function withdrawTokens() external onlyOwner {
      payable(owner()).transfer(address(this).balance);
    }

    function emergencyWithdraw() external {
        UserInfo storage _userInfo = userInfo[msg.sender];
        require(EnumerableSet.length(_userInfo.tokenIds) > 0, "You have no tokens staked.");
        for(uint256 i = 0; i < EnumerableSet.length(_userInfo.tokenIds); i++) {
            IERC721(collectionToStake).transferFrom(address(this), msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
            emit UnStake(collectionToStake, msg.sender, EnumerableSet.at(_userInfo.tokenIds, i));
        }
    }

    function pendingReward(address _user) public view returns (uint256) {
        UserInfo storage _userInfo = userInfo[_user];
        return EnumerableSet.length(_userInfo.tokenIds) * (block.number - _userInfo.startBlock) * rewardTokenPerBlock;
    }

    function stake(uint256[] calldata tokenIds) public nonReentrant {
        require(tokenIds.length > 0, "tokenIds parameter has zero length.");
        
        userInfo[msg.sender].startBlock = block.number;

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(IERC721(collectionToStake).ownerOf(tokenIds[i]) == msg.sender, "Not Your NFT.");
            IERC721(collectionToStake).transferFrom(msg.sender, address(this), tokenIds[i]);
            EnumerableSet.add(userInfo[msg.sender].tokenIds, tokenIds[i]);
            emit Stake(collectionToStake, msg.sender, tokenIds[i]);
        }
    }

    function unStake(uint256[] calldata tokenIds) public nonReentrant {
        require(tokenIds.length > 0, "tokenIds parameter has zero length.");

        UserInfo storage _userInfo = userInfo[msg.sender];
        _userInfo.startBlock = block.number;

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(EnumerableSet.remove(_userInfo.tokenIds, tokenIds[i]), "Not your NFT Id.");
            IERC721(collectionToStake).transferFrom(address(this), msg.sender, tokenIds[i]);
            emit UnStake(collectionToStake, msg.sender, tokenIds[i]);
        }
    }

    function claimRewards() public nonReentrant {
        uint256 _pendingRewards = pendingReward(msg.sender);
        if(_pendingRewards > 0) {
            payable(msg.sender).transfer(_pendingRewards);
            userInfo[msg.sender].startBlock = block.number;
        }
    }

    function getStakingInfo(address _user) public view returns(uint256[] memory _tokenIds, uint256 _pendingRewards) {
        UserInfo storage _userInfo = userInfo[_user];
        uint256 length = EnumerableSet.length(_userInfo.tokenIds);
        _tokenIds = new uint256[](length);
        for(uint256 i = 0; i < length; i++) {
            _tokenIds[i] = EnumerableSet.at(_userInfo.tokenIds, i);
        }
        _pendingRewards = pendingReward(_user);
    }
}