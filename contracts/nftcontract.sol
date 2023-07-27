// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyGameNFT is ERC721Enumerable, Ownable {
    uint256 private tokenIdCounter;
    string private baseTokenURI;
    mapping(uint256 => string) private tokenMetadata;

    event NFTMinted(address indexed owner, uint256 indexed tokenId, string metadataURI);

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseTokenURI = _baseURI;
        tokenIdCounter = 0;
    }

    function mintNFT(address _to, string memory _metadataURI) external onlyOwner {
        uint256 tokenId = tokenIdCounter;
        tokenIdCounter++;

        _mint(_to, tokenId);
        _setTokenURI(tokenId, _metadataURI);

        emit NFTMinted(_to, tokenId, _metadataURI);
    }

    function transferNFT(address _to, uint256 _tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved or owner");
        _transfer(_msgSender(), _to, _tokenId);
    }

    function totalSupply() public view override returns (uint256) {
        return tokenIdCounter;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _setTokenURI(uint256 _tokenId, string memory _metadataURI) internal {
        require(_exists(_tokenId), "Token ID does not exist");
        tokenMetadata[_tokenId] = _metadataURI;
    }

    function getTokenMetadata(uint256 _tokenId) external view returns (string memory) {
        require(_exists(_tokenId), "Token ID does not exist");
        return tokenMetadata[_tokenId];
    }
}
