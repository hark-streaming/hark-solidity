pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HarkGovernanceToken is ERC20 {

    //#region --- DATA, MODIFIERS, CONSTRUCTOR ---
    
    // token vanities
    string public name = "Default Hark Governance";
    uint8 public decimals = 0;
    string public symbol = "NULL-HARK";
    
    // required for donating
    address public owner = address(0x0);
    
    // creates the hark governance token
    constructor(string _name, string _symbolAppdx, address _owner) public {
        name = _name;
        name = string(abi.encodePacked(_name, " Hark Governance"));
        symbol = string(abi.encodePacked(_symbolAppdx, "-HARK"));

        owner = _owner;                                    // creator is the owner
        //balances[_owner] = 1000000000000;                // Give the creator no initial tokens
    }
    
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }
    
    
    //#endregion
    
    
    
    //#region -- SETTERS

    // throws back tfuel if someone tries to directly send it here
    function () external { revert("Contract doesn't take gas directly."); }

    // approves and then calls the receiving contract
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
    
    // normal method of sending tfuel is through the sdk
    // other method of sending tfuel is through a function here, which gives the user tfuel
    function purchaseTokens() public payable returns(bool success) {
        
        require(msg.value > 10 ** 16);
        uint256 tokenAmount = msg.value / (10 ** 16);
        
        //bool balanceAllowed = balances[owner] >= tokenAmount && balances[owner] > 0;
        //require(balanceAllowed);
    
        // transfers token to the purchaser
        balances[msg.sender] += tokenAmount;
        return true;
    }
    
    // used by the owner to withdraw all of the tfuel in the contract
    function withdraw() public ownerOnly returns(bool success) {
        owner.transfer(address(this).balance);
        return true;
    }
    
    // used by the owner to change the donate address and thus ownership
    function transferDonateAddress() public ownerOnly returns(bool success) {
        transfer(msg.sender, balanceOf(owner));
        owner = msg.sender;
        return true;
    }
    
    // kills the contract to free up space
    function kill() ownerOnly public { 
        selfdestruct(owner); 
    }
    
    //#endregion
}
