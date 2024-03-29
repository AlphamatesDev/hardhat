// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PulsePixelCartel is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    string  private _baseURIextended;
    string  private _metadataExtension;
    string  public unrevealURI;
    bool    public reveal;
    
    string  public mintStep;
    bool    public mintPause;
    uint256 public mintPrice;
    bytes32 public merkleRoot;

    uint256 public MAX_NFT_SUPPLY;
    uint256 public MINT_LIMIT_TRANSACTION;

    uint256 public mintCounter;

    address payable public  stakingContract;
    address payable private marketingFee;
    address payable private devFee;

    mapping (address => uint256) public referralMintCount;

    event MintNFT(address indexed _minter, uint256 _amount, address indexed _referrer);

    constructor() ERC721("PulsePixel Cartel", "PPC") {
        mintPrice = 100000000000000000000000;
        MAX_NFT_SUPPLY = 3333;
        MINT_LIMIT_TRANSACTION = 10;

        _baseURIextended = "https://ipfs.io/ipfs/QmTMBP7a9JtqLA23W5RNL7Ruz6sz2VqMhxefuXpKCm86f3/";
        _metadataExtension = ".json";
        unrevealURI = "https://ipfs.io/ipfs/QmTMBP7a9JtqLA23W5RNL7Ruz6sz2VqMhxefuXpKCm86f3/1.json";

        marketingFee = payable(0xb8A492d722ac951a53f59423EFF6C24ACAB71392);
        devFee = payable(0x59790E88301b2376d5c3C421D6B4b6D640D18E8d);
    }

    function mint(address _receiver, uint256 _quantity, address _referrer) private {
        for(uint256 i = 0; i < _quantity; i++) {
            require(mintCounter < MAX_NFT_SUPPLY, "Sale has already ended");
            mintCounter = mintCounter + 1;
            _safeMint(_receiver, mintCounter);
        }

        if (_referrer != address(0)) {
            referralMintCount[_receiver] = referralMintCount[_receiver] + 1;
        }
        emit MintNFT(msg.sender, _quantity, _referrer);
    }

    function mintNFTForOwner(uint256 _amount) public onlyOwner {
        mint(msg.sender, _amount, address(0));
    }

    function mintNFT(bytes32[] calldata _proof, uint256 _quantity, address _referrer) public payable {
        require(_referrer != msg.sender, "Invalid referral address");
        require(_quantity > 0, "Invalid mint amount");
        require(_quantity <= MINT_LIMIT_TRANSACTION, "Exceed mint limit per transaction");
        require(mintPrice * _quantity <= msg.value, "ETH value is not correct");
        require(!mintPause, "Mint Paused.");
        if(merkleRoot != 0x0) {
            require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address does not exist in whitelist.");
        }

        payable(owner()).transfer(msg.value * 75 / 100);
        stakingContract.transfer(msg.value * 10 / 100);
        marketingFee.transfer(msg.value * 15 / 2 / 100);
        devFee.transfer(msg.value * 15 / 2 / 100);

        mint(msg.sender, _quantity, _referrer);
    }

    function withdraw() external onlyOwner() {
        address payable ownerAddress = payable(msg.sender);
        ownerAddress.transfer(address(this).balance);
    }

    function getReferralMintCount(address _user) external view returns (uint256) {
        return referralMintCount[_user];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(!reveal) return unrevealURI;
        return bytes(_baseURIextended).length > 0 ? string(abi.encodePacked(_baseURIextended, tokenId.toString(), _metadataExtension)) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setMetadataExtension(string memory extension_) external onlyOwner() {
        _metadataExtension = extension_;
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

    function setMintState(string memory _mintStep, uint256 _mintPrice, bytes32 _merkleRoot, bool _startNow) external onlyOwner {
        mintStep = _mintStep;
        mintPrice = _mintPrice;
        merkleRoot = _merkleRoot;
        mintPause = !_startNow;
    }
    
    function getMintState() public view returns (
        string memory _mintStep, 
        bool _mintPause, 
        uint256 _mintPrice,
        bytes32 _merkleRoot
    ) {
        _mintStep = mintStep;
        _mintPause = mintPause;
        _mintPrice = mintPrice;
        _merkleRoot = merkleRoot;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        MAX_NFT_SUPPLY = _maxSupply;
    }

    function setMintLimitTransaction(uint256 _mintLimitTransaction) public onlyOwner {
        MINT_LIMIT_TRANSACTION = _mintLimitTransaction;
    }

    function pause() public onlyOwner {
        mintPause = true;
    }

    function unPause() public onlyOwner {
        mintPause = false;
    }

    function setStakingContract(address _stakingContract) public onlyOwner {
        stakingContract = payable(_stakingContract);
    }
}