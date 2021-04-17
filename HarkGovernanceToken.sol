pragma solidity ^0.8.3;

import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
//import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol;
import "./HarkPlatformToken.sol";

/**
 * @dev A token contract that implements ERC20, and is "owned"/managed by one party.
 * 
 * Custom tokens for organizations on the Hark platform.
 */
contract HarkGovernanceToken is ERC20 {

    //#region --- DATA, MODIFIERS, CONSTRUCTOR ---
    // token vanities
    //string public name = "Default Hark Governance";
    //uint8 public decimals = 0;
    //string public symbol = "NULL-HARK";
    
    // required for donating
    address public _owner = address(0x0);
    HarkPlatformToken internal _platform;

    // creates the hark governance token
    constructor(string memory name, string memory symbolAppdx, address owner, HarkPlatformToken platform) 
        ERC20(string(abi.encodePacked(name, " Hark Governance")), string(abi.encodePacked(symbolAppdx, "-HARK"))) {
        _owner = owner;
        _platform = platform;
    }
    
    // only going int here. 1 Tfuel = 100 Tokens
    function decimals() public view override returns(uint8) { return 0; }
    
    // functions that are just for the owner of the organization.
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    
    
    //#endregion
    
    
    
    //#region -- FUNCTIONALITY

    // throws back tfuel if someone tries to directly send it here
    fallback() external payable { 
        if(msg.sender != address(_platform)) revert("Contract doesn't take gas directly.");
    }
    
    // normal method of sending tfuel is through the sdk
    // other method of sending tfuel is through a function here, which gives the user tfuel
    function purchaseTokens() public payable returns(bool success) {
        
        require(msg.value > 10 ** 16);
        uint256 tokenAmount = msg.value / (10 ** 16);
    
        // transfers token to the purchaser
        _mint(msg.sender, tokenAmount);
        return true;
    }
    
    // used by the owner to withdraw all of the tfuel in the contract
    function withdraw() public onlyOwner returns(bool success) {
        payable(_owner).transfer(address(this).balance);
        return true;
    }
    
    function owner() public view returns(address) {
        return _owner;
    }
    
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
    }
    
    // kills the contract to free up space
    function kill() onlyOwner public { 
        selfdestruct(payable(_owner)); 
    }
    
    //#endregion
}
