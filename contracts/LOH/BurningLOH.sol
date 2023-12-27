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

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed from,
        address indexed to
    );
}

interface IERC721AQueryable is IERC721A {
    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory);
}

interface IStandardERC721A {
    function burn(uint256 _tokenId) external;
}

contract BurningLOH is Ownable, ReentrancyGuard {
    struct TokenInfo {
        address token_address;
        string name;
        uint256 token_id;
    }

    struct ApprovalStatus {
        address token_address;
        bool isApproval;
    }

    uint256 public startTime;
    uint256 public burningPeriod;

    mapping(address => bool) public allowedToBurn;

    mapping(address => uint256) pointAmount;

    mapping(address => uint256) pointsPerUser;

    event Burn(address _user, address _collection, uint256 _tokenId, uint256 _pointAmount);

    constructor() {
        allowedToBurn[0x51084c32AA5ee43a0e7bD8220195da53b5c69868] = true; // Volume 1
        allowedToBurn[0x770FA15c43b84F61434321F5167814b64790E6Fa] = true; // Reapers

        pointAmount[0x51084c32AA5ee43a0e7bD8220195da53b5c69868] = 5;
        pointAmount[0x770FA15c43b84F61434321F5167814b64790E6Fa] = 45;

        startTime = block.timestamp;
        burningPeriod = 3600 * 24 * 21;
    }

    function setPointAmount(address _collection, uint256 _amount) public onlyOwner() {
        pointAmount[_collection] = _amount;
    }

    function setTime(uint256 _startTime, uint256 _burningPeriod) public onlyOwner() {
        startTime = _startTime;
        burningPeriod = _burningPeriod;
    }

    function getEndTime() public view returns (uint256) {
        return (startTime + burningPeriod);
    }

    function burn(address[] calldata _collections, uint256[] calldata _tokenIds) public nonReentrant {
        require(block.timestamp > startTime, "not started burning yet.");
        require(block.timestamp < (startTime + burningPeriod), "passed burning period.");
        require(_tokenIds.length > 0, "tokenIds parameter has zero length.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(allowedToBurn[_collections[i]], "Not allowed to stake for this collection");
            IStandardERC721A(_collections[i]).burn(_tokenIds[i]);
            pointsPerUser[msg.sender] += pointAmount[_collections[i]];
            emit Burn(msg.sender, _collections[i], _tokenIds[i], pointAmount[_collections[i]]);
        }
    }

    function getTokensInWallet(
        address[] calldata _collections
    ) public view returns (TokenInfo[] memory _tokensInWallet) {
        uint256 tokenCnt = 0;
        for (uint256 i = 0; i < _collections.length; i++) {
            if (allowedToBurn[_collections[i]] == true)
                tokenCnt += IERC721AQueryable(_collections[i])
                    .tokensOfOwner(msg.sender)
                    .length;
        }

        if (tokenCnt == 0) return _tokensInWallet;

        _tokensInWallet = new TokenInfo[](tokenCnt);

        uint256 tempCnt = 0;

        for (uint256 i = 0; i < _collections.length; i++) {
            if (allowedToBurn[_collections[i]] == true) {
                uint256[] memory tokenIds = IERC721AQueryable(_collections[i])
                    .tokensOfOwner(msg.sender);
                string memory tokenName = IERC721A(_collections[i]).name();

                for (uint256 j = 0; j < tokenIds.length; j++) {
                    _tokensInWallet[tempCnt].token_address = _collections[i];
                    _tokensInWallet[tempCnt].name = tokenName;
                    _tokensInWallet[tempCnt].token_id = tokenIds[j];
                    tempCnt++;
                }
            }
        }
        return _tokensInWallet;
    }

    function getApprovalStatus(
        address[] calldata _collections,
        address _user
    ) public view returns (ApprovalStatus[] memory _approvalStatus) {
        uint256 collectionCnt = 0;
        for (uint256 i = 0; i < _collections.length; i++) {
            if (allowedToBurn[_collections[i]] == true) collectionCnt++;
        }

        _approvalStatus = new ApprovalStatus[](collectionCnt);

        uint256 tempCnt = 0;

        for (uint256 i = 0; i < _collections.length; i++) {
            if (allowedToBurn[_collections[i]] == true) {
                _approvalStatus[tempCnt].token_address = _collections[i];
                _approvalStatus[tempCnt].isApproval = IERC721A(_collections[i])
                    .isApprovedForAll(_user, address(this));
                tempCnt++;
            }
        }

        return _approvalStatus;
    }
}
