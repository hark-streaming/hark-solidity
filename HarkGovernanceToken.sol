//SPDX-License-Identifier: Attribution Assurance License
pragma solidity ^0.8.3;
import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./utils/PaymentSplitter.sol";
import "./HarkPlatformToken.sol";

/**
 * @dev A token contract that implements ERC20, and is "owned"/managed by one party.
 * 
 * Custom tokens for organizations on the Hark platform.
 */
contract HarkGovernanceToken is ERC20, PaymentSplitter {

    //#region --- DATA, MODIFIERS, CONSTRUCTOR ---
    
    // required for donating
    address public _owner = address(0x0);
    HarkPlatformToken internal _platform;

    // creates the hark governance token
    constructor(string memory name, string memory symbolAppdx, address ownerAddress, HarkPlatformToken platform) 
        ERC20(string(abi.encodePacked(name, " Hark Governance")), string(abi.encodePacked(symbolAppdx, "-HARK")))
        PaymentSplitter(new address[](0), new uint256[](0))
    {
        _owner = ownerAddress;
        _platform = platform;
        
        // adds current platform tax
        uint16 _tax = _platform.tax();
        _addPayee(address(_platform), _tax);
        _addPayee(ownerAddress, 10000 - _tax);
    }
    
    // only going int here. 1 Tfuel = 100 Tokens
    function decimals() public pure override returns(uint8) { return 0; }
    
    // functions that are just for the owner of the organization.
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    
    //#endregion
    
    
    
    //#region --- DONATING ---
    
    // adds shares an address
    function editShares(address[] memory payees, uint256[] memory shares_) public onlyOwner {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");
        
        // nullfies everything to 0
        releaseAllAndReset();
        
        // adds back the platform taxation
        uint256 totalShares = 0;
        for(uint256 i = 0; i < payees.length; i++) {
            totalShares += shares_[i];
        }
        uint256 _tax = _platform.tax();

        // applies platform tax
        require(totalShares + _tax == 10000, "The total shares must be equal to 10,000.");
        _addPayee(address(_platform), _tax);
        
        // adds all of the payees
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
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
    
    //#endregion


    
    //#region --- OWNERSHIP ---
    
    // the owner of the token's organization
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
