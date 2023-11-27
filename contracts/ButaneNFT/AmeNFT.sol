// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/utils/math/Math.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import 'hardhat/console.sol';

interface IVRFv2SubscriptionManager {
    function requestRandomWords() external returns(uint256);
}

contract AmeNFT is ERC1155, Ownable {

    using Strings for uint256;

    string public constant NAME = "AMEMembership";
    string public constant SYMBOL = "AMEM";

    string public baseTokenURI;

    uint256 constant maxTokenId = 3;

    uint256[3] public maxSupply = [25000,25000,25000];
    uint256[3] public maxMintPerWallet = [20,20,20];
    uint256[3] public totalMinted = [0,0,0];
    uint256[3] public mintPrice = [4000000000000000000,7750000000000000000,8600000000000000000];
    bytes32[2] public merkleRoot;

    uint256 public startTime = 1685840927;
    uint256 public endTime = 1695840927;
 
    bool public paused = false;
    bool public isPublisSale = true;

    address public paymentTokenAddress = address(0);

    constructor(string memory _baseURI_, address _paymentTokenAddress) ERC1155(_baseURI_) {
        baseTokenURI = _baseURI_;
        paymentTokenAddress = _paymentTokenAddress;
    }

    function setMaxSupply(uint256 _maxSupply1, uint256 _maxSupply2, uint256 _maxSupply3) public onlyOwner() {
        maxSupply[0] = _maxSupply1;
        maxSupply[1] = _maxSupply2;
        maxSupply[2] = _maxSupply3;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet1, uint256 _maxMintPerWallet2, uint256 _maxMintPerWallet3) public onlyOwner() {
        maxMintPerWallet[0] = _maxMintPerWallet1;
        maxMintPerWallet[1] = _maxMintPerWallet2;
        maxMintPerWallet[2] = _maxMintPerWallet3;
    }

    function setMintPrice(uint256 _mintPrice1, uint256 _mintPrice2, uint256 _mintPrice3) public onlyOwner() {
        mintPrice[0] = _mintPrice1;
        mintPrice[1] = _mintPrice2;
        mintPrice[2] = _mintPrice3;
    }

    function setMerkleRoot(bytes32 _merkleRoot1, bytes32 _merkleRoot2) external onlyOwner {
        merkleRoot[0] = _merkleRoot1;
        merkleRoot[1] = _merkleRoot2;
    }

    function setPublisSale(bool _isPubicSale) public onlyOwner() {
        isPublisSale = _isPubicSale;
    }

    modifier onlyNotPaused() {
        require(!paused, 'Contract is paused.');
        _;
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function checkWhitelist(address _user, uint256 _tokenId, bytes32[] calldata _proof) public view returns(bool) {
        if(_tokenId == 3) return true;
        uint256 _tokenIndex = _tokenId - 1;
        bool isWhitelist = MerkleProof.verify(_proof, merkleRoot[_tokenIndex], keccak256(abi.encodePacked(_user)));
        return isWhitelist;
    }

    function mint(uint256 _amount, uint256 _tokenId, bytes32[] calldata _proof) public onlyNotPaused {
        uint256 _tokenIndex = _tokenId - 1;
        uint256 _now = block.timestamp;
        require(_tokenIndex < maxTokenId, "Exceeded the token id.");
        require(_amount > 0, "Amount is zero.");
        require(_now > startTime && _now < endTime, "Time out.");
        
        uint256 tokenCount = balanceOf(msg.sender, _tokenId);

        require(tokenCount + _amount <= maxMintPerWallet[_tokenIndex], string(abi.encodePacked('You can only mint ', maxMintPerWallet[_tokenIndex].toString(), ' cards per wallet')));
        require(totalMinted[_tokenIndex] < maxSupply[_tokenIndex], 'This transaction would exceed max supply of queen');

        if(!isPublisSale)
            require(checkWhitelist(msg.sender, _tokenId, _proof), "Address does not exist in whitelist.");

        require(IERC20(paymentTokenAddress).balanceOf(msg.sender) >= mintPrice[_tokenIndex] * _amount, 'Ether value is too low');
        IERC20(paymentTokenAddress).transferFrom(msg.sender, address(this), mintPrice[_tokenIndex] * _amount);

        super._mint(msg.sender, _tokenId, _amount, "");
        totalMinted[_tokenIndex] += _amount;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0 && tokenId <= maxTokenId, "ERC721Metadata: URI query for nonexistent token");

        string memory baseExtension = ".json";
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function withdraw() public onlyOwner {
        require(payable(owner()).send(address(this).balance));
    }

    function withdrawToken() public onlyOwner {
        uint256 _balance = IERC20(paymentTokenAddress).balanceOf(address(this));
        IERC20(paymentTokenAddress).transfer(msg.sender, _balance);
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

    function setPaymentTokenAddress(address _paymentTokenAddress) public onlyOwner {
        paymentTokenAddress = _paymentTokenAddress;
    }
}