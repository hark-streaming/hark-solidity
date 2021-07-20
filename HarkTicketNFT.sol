//SPDX-License-Identifier: Attribution Assurance License
pragma solidity ^0.8.4;

import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract HarkTicketNFT is IERC721Metadata, ERC721Enumerable {
    
    uint public nextTokenId;
    address public owner;
    string public uri;
    
    constructor(string memory newURI) ERC721("Hark Ticket NFT", "HRK-TKT")
    {
        owner = msg.sender;
        uri = newURI;
    }
    
    // Lets the owner (Hark) generate a ticket for a specific address.
    function mint(address to) external returns(uint recentlyMintedTokenId) {
        require(msg.sender == owner, 'Only Hark can mint this for you.');
        recentlyMintedTokenId = nextTokenId;
        _safeMint(to, recentlyMintedTokenId);
        nextTokenId++;
    }

    function batchMint(address[] memory to) external returns(uint[] memory recentlyMintedTokenIds) {
        require(msg.sender == owner, 'Only Hark can mint this for you.');
        for(uint i = 0; i < to.length; i++) {
            recentlyMintedTokenIds[i] = nextTokenId;
            _safeMint(to[i], recentlyMintedTokenIds[i]);
            nextTokenId++;
        }
        return recentlyMintedTokenIds;
    }
    
    //#region Setters
    
    // Sets the URI of each token. (centralized images)
    function setURI(string memory newURI) public {
        require(msg.sender == owner, 'Only Hark can change their server URI.');
        uri = newURI;
    }
    
    //#endregion
    
    
    
    //#region Hooks
    
    // sets the metadata of the token
    function _baseURI() internal view override returns (string memory) {
        return uri;
    }
    
    //#endregion
}