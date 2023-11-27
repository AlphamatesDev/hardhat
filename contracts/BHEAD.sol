// SPDX-License-Identifier: MIT

/***************************************************************************************************************************************

$$$$$$$\            $$\ $$\ $$\   $$\                           $$\                 $$\       $$\   $$\ $$$$$$$$\ $$$$$$$$\        
$$  __$$\           $$ |$$ |$$ |  $$ |                          $$ |                $$ |      $$$\  $$ |$$  _____|\__$$  __|       
$$ |  $$ |$$\   $$\ $$ |$$ |$$ |  $$ | $$$$$$\   $$$$$$\   $$$$$$$ | $$$$$$\   $$$$$$$ |      $$$$\ $$ |$$ |         $$ | $$$$$$$\ 
$$$$$$$\ |$$ |  $$ |$$ |$$ |$$$$$$$$ |$$  __$$\  \____$$\ $$  __$$ |$$  __$$\ $$  __$$ |      $$ $$\$$ |$$$$$\       $$ |$$  _____|
$$  __$$\ $$ |  $$ |$$ |$$ |$$  __$$ |$$$$$$$$ | $$$$$$$ |$$ /  $$ |$$$$$$$$ |$$ /  $$ |      $$ \$$$$ |$$  __|      $$ |\$$$$$$\  
$$ |  $$ |$$ |  $$ |$$ |$$ |$$ |  $$ |$$   ____|$$  __$$ |$$ |  $$ |$$   ____|$$ |  $$ |      $$ |\$$$ |$$ |         $$ | \____$$\ 
$$$$$$$  |\$$$$$$  |$$ |$$ |$$ |  $$ |\$$$$$$$\ \$$$$$$$ |\$$$$$$$ |\$$$$$$$\ \$$$$$$$ |      $$ | \$$ |$$ |         $$ |$$$$$$$  |
\_______/  \______/ \__|\__|\__|  \__| \_______| \_______| \_______| \_______| \_______|      \__|  \__|\__|         \__|\_______/ 

 **************************************************************************************************************************************/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BHEAD is ERC721Upgradeable, OwnableUpgradeable {
    using Strings for uint256;
    
    string private _baseURIextended;
    string public unrevealURI;
    bool public reveal;
    bool public pauseMint;

    uint256 public constant MAX_NFT_SUPPLY = 2899;

    uint256 public whitelistMintPrice;
    uint256 public publicMintPrice;
    uint256 public whitelistMintStart;
    uint256 public publicMintStart;

    uint256 public ownerEarning;
    
    bytes32 public preSaleMerkleRoot;
    uint256 public mintCounter;

    mapping (address => uint256) public referrerEarning;
    mapping (address => address) private sponsors;

    event MintNFT(address indexed _minter, uint256 _amount, address indexed _referrer);
    event ClaimReferralEarning(address indexed _referrer, uint256 _amount);

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("BullHeaded NFTs", "BHEAD");

        unrevealURI = "https://bullhead.mypinata.cloud/ipfs/Qmd1zs6QkBVKQzzpeFSoS7g9ZLUE338Dm1RTnYMszgMmeL/1";
    }

    function mint(address _receiver, uint256 _quantity, address _referrer) private {
        require(!pauseMint, "Paused!");
        for(uint256 i = 0; i < _quantity; i++) {
            require(mintCounter < MAX_NFT_SUPPLY, "Sale has already ended");
            mintCounter = mintCounter + 1;
            _safeMint(_receiver, mintCounter);
        }

        uint256 referrerFee = 0;
        address referrer = _referrer == address(0) ? sponsors[_receiver] : _referrer;
        if (referrer != address(0)) {
            referrerFee = msg.value / 10;
            referrerEarning[referrer] += referrerFee;
        }
        ownerEarning += (msg.value - referrerFee);

        emit MintNFT(msg.sender, _quantity, referrer);
    }

    function mintNFTForOwner(uint256 _amount) public onlyOwner {
        mint(msg.sender, _amount, address(0));
    }

    function whitelistMint(bytes32[] calldata _proof, uint256 _quantity, address _referrer) public payable {
        require(_referrer != msg.sender, "Invalid referral address");
        require(_quantity > 0, "Invalid mint amount");
        require(whitelistMintPrice * _quantity <= msg.value, "ETH value is not correct");
        require(block.timestamp > whitelistMintStart && block.timestamp < publicMintStart, "Not whitelist time.");
        require(MerkleProof.verify(_proof, preSaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address does not exist in whitelist.");

        mint(msg.sender, _quantity, _referrer);
    }

    function publicMint(uint256 _quantity, address _referrer) public payable {
        require(_referrer != msg.sender, "Invalid referral address");
        require(_quantity > 0, "Invalid mint amount");
        require(publicMintPrice * _quantity <= msg.value, "ETH value is not correct");
        require(block.timestamp > publicMintStart, "Not public time.");

        mint(msg.sender, _quantity, _referrer);
    }

    function withdraw() external onlyOwner() {
        uint256 amount = ownerEarning;
        ownerEarning = 0;
        address payable ownerAddress = payable(msg.sender);
        ownerAddress.transfer(amount);
    }

    function claimRefEarning() external{
        require(referrerEarning[msg.sender] > 0, "No Earning for this address");
        uint256 amount = referrerEarning[msg.sender];
        referrerEarning[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit ClaimReferralEarning(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(!reveal) return unrevealURI;
        return bytes(_baseURIextended).length > 0 ? string(abi.encodePacked(_baseURIextended, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setUnrevealURI(string memory _uri) external onlyOwner() {
        unrevealURI = _uri;
    }

    function Reveal() public onlyOwner() {
        reveal = true;
    }

    function UnReveal() public onlyOwner() {
        reveal = false;
    }

    function setConfig(uint256 _whitelistPrice, uint256 _publicPrice, uint256 _whitelistStart, uint256 _publicStart) external onlyOwner {
        whitelistMintPrice = _whitelistPrice;
        publicMintPrice = _publicPrice;
        whitelistMintStart = _whitelistStart;
        publicMintStart = _publicStart;
    }

    function setMerkleRoot(bytes32 _preSaleMerkleRoot) external onlyOwner {
        preSaleMerkleRoot = _preSaleMerkleRoot;
    }

    function getConfig() public view returns (
        uint256 _whitelistPrice, 
        uint256 _publicPrice, 
        uint256 _whitelistStart, 
        uint256 _publicStart
    ) {
        _whitelistPrice = whitelistMintPrice;
        _publicPrice = publicMintPrice;
        _whitelistStart = whitelistMintStart;
        _publicStart = publicMintStart;
    }

    function pause() public onlyOwner {
        pauseMint = true;
    }

    function unPause() public onlyOwner {
        pauseMint = false;
    }
}