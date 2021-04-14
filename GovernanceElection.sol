pragma solidity ^0.8.3;

import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @dev A token contract that implements ERC20, and is "owned"/managed by one party.
 * 
 * Custom tokens for organizations on the Hark platform.
 */
contract HarkGovernanceToken is ERC20 {

    //#region --- DATA, MODIFIERS, CONSTRUCTOR ---
    
    // required for donating
    address public _owner = address(0x0);

    // creates the hark governance token
    constructor(string memory name, string memory symbolAppdx, address owner/*, HarkPlatformToken _platform*/) 
        ERC20(string(abi.encodePacked(name, " Hark Governance")), string(abi.encodePacked(symbolAppdx, "-HARK"))) {
        _owner = owner;
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
    fallback () external { revert("Contract doesn't take gas directly."); }

    /*
    // approves and then calls the receiving contract
    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData) public returns (bool success) {
        approve(_spender, _value);
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
    */
    
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
