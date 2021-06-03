# hark-solidity
Solidity code for HarkTV.  
Building to the Theta network is difficult through Truffle, which is why at the moment the code is currently written within the Remix IDE in mind.  
Creates a platform token that pools a tax from minting governance tokens.  

## NFTs
Non-Fungible tokens, or ERC721, will be central to the next updates of Hark.

## Tokens
The initial conception of Hark.TV had tokens as one of the main blockchain applications. This may or may not be the case in the future. Based off ERC20.

### Hark Platform Token
The platform that taxes all of the donations made through Hark Governance Token.  
Can have elections that send TFuel to a winning Hark Governance Tokens. Tokens must be nominated before they can be voted for.  

### Hark Governance Token
The Custom Tokens of the platform. Must be created with the Hark Platform Token so that taxation can take place. Is based off of OpenZepplin's payment splitter, though that file has been edited for our own purposes.

### Goverance Election
Just a simple election. Metadata must be kept in an outside database. No functionality other than timed elections.
