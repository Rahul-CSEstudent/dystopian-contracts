// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    IERC721Enumerable private nftContract;
    uint256 private listingFee;
    uint256 private marketplaceFee;
    uint256 private escrowPeriod; // In blocks

    enum ListingStatus { Listed, Sold, Canceled }

    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 price;
        uint256 startTime;
        ListingStatus status;
    }

    mapping(uint256 => Listing) private listings;
    mapping(uint256 => uint256) private tokenIdToListingId;

    event NFTListed(uint256 indexed listingId, address indexed seller, uint256 indexed tokenId, uint256 price);
    event NFTSold(uint256 indexed listingId, address indexed buyer, uint256 indexed tokenId, uint256 price);
    event ListingCanceled(uint256 indexed listingId);

    constructor(address _nftContractAddress, uint256 _listingFee, uint256 _marketplaceFee, uint256 _escrowPeriod) {
        nftContract = IERC721Enumerable(_nftContractAddress);
        listingFee = _listingFee;
        marketplaceFee = _marketplaceFee;
        escrowPeriod = _escrowPeriod;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Not the owner of the NFT");
        _;
    }

    function setListingFee(uint256 _newListingFee) external onlyOwner {
        listingFee = _newListingFee;
    }

    function setMarketplaceFee(uint256 _newMarketplaceFee) external onlyOwner {
        marketplaceFee = _newMarketplaceFee;
    }

    function setEscrowPeriod(uint256 _newEscrowPeriod) external onlyOwner {
        escrowPeriod = _newEscrowPeriod;
    }

    function listNFTForSale(uint256 _tokenId, uint256 _price) external onlyNFTOwner(_tokenId) {
        require(_price > 0, "Price must be greater than zero");
        require(tokenIdToListingId[_tokenId] == 0, "NFT is already listed");

        // Transfer the NFT to the marketplace contract
        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        // Calculate the expiration time for escrow
        uint256 expirationTime = block.number + escrowPeriod;

        // Create a new listing
        uint256 listingId = uint256(keccak256(abi.encodePacked(block.number, msg.sender, _tokenId, _price)));
        listings[listingId] = Listing({
            seller: msg.sender,
            tokenId: _tokenId,
            price: _price,
            startTime: block.number,
            status: ListingStatus.Listed
        });
        tokenIdToListingId[_tokenId] = listingId;

        emit NFTListed(listingId, msg.sender, _tokenId, _price);
    }

    function buyNFT(uint256 _listingId) external payable {
        Listing storage listing = listings[_listingId];
        require(listing.status == ListingStatus.Listed, "Listing not available");
        require(msg.value >= listing.price, "Insufficient payment");

        // Calculate marketplace fee
        uint256 marketplaceFeeAmount = (listing.price * marketplaceFee) / 10000;
        uint256 sellerAmount = listing.price - marketplaceFeeAmount;

        // Transfer payment to the seller and marketplace fee to the contract owner
        payable(listing.seller).transfer(sellerAmount);
        payable(owner()).transfer(marketplaceFeeAmount);

        // Transfer the NFT to the buyer
        nftContract.transferFrom(address(this), msg.sender, listing.tokenId);

        // Mark the listing as sold
        listing.status = ListingStatus.Sold;

        emit NFTSold(_listingId, msg.sender, listing.tokenId, listing.price);
    }

    function cancelListing(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        require(listing.status == ListingStatus.Listed, "Listing not available");
        require(msg.sender == listing.seller, "Only the seller can cancel the listing");

        // Transfer the NFT back to the seller
        nftContract.transferFrom(address(this), msg.sender, listing.tokenId);

        // Mark the listing as canceled
        listing.status = ListingStatus.Canceled;

        emit ListingCanceled(_listingId);
    }

    function getListing(uint256 _listingId) external view returns (Listing memory) {
        return listings[_listingId];
    }

    function getTokenIdListingId(uint256 _tokenId) external view returns (uint256) {
        return tokenIdToListingId[_tokenId];
    }
}
