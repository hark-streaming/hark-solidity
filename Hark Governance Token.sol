pragma solidity ^0.4.24;

contract Token {

    /// @return total amount of tokens
    function totalSupply() public constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}



contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        //if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}



contract HarkGovernanceToken is StandardToken {

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

        owner = _owner;                                  // creator gets the token
        totalSupply = 1000000000000;                     // Update total supply
        balances[_owner] = 1000000000000;                // Give the creator no initial tokens
    }
    
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }
    
    
    //#endregion
    
    
    
    //#region -- SETTERS

    // throws back tfuel if someone tries to directly send it here
    function () public { revert("Contract doesn't take gas directly."); }

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
        
        bool balanceAllowed = balances[owner] >= tokenAmount && balances[owner] > 0;
        
        require(balanceAllowed);
        if (balanceAllowed) {
            // transfers token to the purchaser
            balances[msg.sender] += tokenAmount;
            balances[owner] -= tokenAmount;
            emit Transfer(owner, msg.sender, tokenAmount);
            return true;
        } else { return false; }
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
