// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DigitalDelirium is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct NFT {
        uint256 tokenId;
        string name;
        string description;
        uint256 price;
        bool listed;
        string metadataURI;
    }

    mapping(uint256 => NFT) private _nfts;
    mapping(uint256 => address) private _nftCreators;

    address private _erc20TokenAddress;

    event NFTCreated(uint256 indexed tokenId, address indexed creator);
    event NFTListed(uint256 indexed tokenId, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event NFTBid(uint indexed tokenId, address indexed bidder, uint256 price);

    constructor(address erc20TokenAddress) ERC721("Digital Delirium", "DDLR") {
        _erc20TokenAddress = erc20TokenAddress;
    }

    function createNFT(
        string memory name,
        string memory description,
        string memory ipfsUri,
        uint256 price,
        bool listed
    ) external {
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);

        string memory metadataURI = string(abi.encodePacked(_baseURI(), ipfsUri));
        _nfts[newTokenId] = NFT(newTokenId, name, description, price, listed, metadataURI);
        _nftCreators[newTokenId] = msg.sender;

        _tokenIdCounter.increment();

        emit NFTCreated(newTokenId, msg.sender);

        _setTokenURI(newTokenId, ipfsUri);
    }

    function getNFTDetails(uint256 tokenId)
        external
        view
        returns (
            string memory name,
            string memory description,
            uint256 price,
            bool listed,
            string memory metadataURI
        )
    {
        require(_exists(tokenId), "NFT does not exist");
        NFT storage nft = _nfts[tokenId];
        return (nft.name, nft.description, nft.price, nft.listed, nft.metadataURI);
    }

    function getAllCreatorNFTsDetails(address creator) external view returns (NFT[] memory) {
        uint256 totalNFTs = _tokenIdCounter.current();
        NFT[] memory creatorNFTs = new NFT[](totalNFTs);
        uint256 count = 0;

        for (uint256 i = 0; i < totalNFTs; i++) {
            if (_nftCreators[i] == creator) {
                NFT storage nft = _nfts[i];
                creatorNFTs[count] = NFT(
                    nft.tokenId,
                    nft.name,
                    nft.description,
                    nft.price,
                    nft.listed,
                    nft.metadataURI
                );
                count++;
            }
        }

        NFT[] memory result = new NFT[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = creatorNFTs[i];
        }

        return result;
    }


    function listNFT(uint256 tokenId, uint256 price) external {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the NFT");

        NFT storage nft = _nfts[tokenId];
        require(!nft.listed, "NFT already listed");

        nft.listed = true;
        nft.price = price;

        emit NFTListed(tokenId, price);
    }

    function unlistNFT(uint256 tokenId) external {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the NFT");

        NFT storage nft = _nfts[tokenId];
        require(nft.listed, "NFT not listed for sale");

        nft.listed = false;

        emit NFTUnlisted(tokenId);
    }

    function buyNFT(uint256 tokenId) external payable {
        require(_exists(tokenId), "NFT does not exist");
        NFT storage nft = _nfts[tokenId];
        require(nft.listed, "NFT not listed for sale");
        require(msg.value >= nft.price, "Insufficient payment");

        address seller = ownerOf(tokenId);
        _transfer(seller, msg.sender, tokenId);
        nft.listed = false;

        (bool success, ) = seller.call{value: nft.price}("");
        require(success, "Payment transfer failed");

        emit NFTSold(tokenId, msg.sender, nft.price);
    }

    // TODO: Implement the Bid.
    // function bidNFT(uint256 tokenId, uint256 bidAmount) external {
    //     require(_exists(tokenId), "NFT does not exist");
    //     NFT storage nft = _nfts[tokenId];
    //     require(nft.listed, "NFT not listed for sale");

    //     // Perform bidding actions

    //     // Emit event or perform other actions as required
    // }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function getAllNFTMetadata() external view returns (NFT[] memory) {
        uint256 totalNFTs = _tokenIdCounter.current();
        NFT[] memory allMetadata = new NFT[](totalNFTs);

        for (uint256 i = 0; i < totalNFTs; i++) {
            NFT storage nft = _nfts[i];
            allMetadata[i] = NFT(nft.tokenId, nft.name, nft.description, nft.price, nft.listed, nft.metadataURI);
        }

        return allMetadata;
    }

    function getNumberOfListedItems() external view returns (uint256) {
        uint256 totalNFTs = _tokenIdCounter.current();
        uint256 count = 0;

        for (uint256 i = 0; i < totalNFTs; i++) {
            if (_nfts[i].listed) {
                count++;
            }
        }

        return count;
    }

    function getNumberOfItemsOwners() external view returns (uint256) {
        uint256 totalNFTs = _tokenIdCounter.current();
        uint256 count = 0;
        address lastOwner = address(0);

        for (uint256 i = 0; i < totalNFTs; i++) {
            address currentOwner = ownerOf(i);
            if (currentOwner != address(0) && currentOwner != lastOwner) {
                count++;
                lastOwner = currentOwner;
            }
        }

        return count;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }
}