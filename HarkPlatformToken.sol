//SPDX-License-Identifier: Attribution Assurance License
pragma solidity ^0.8.3;
import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/governance/TimelockController.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./HarkGovernanceToken.sol";

/**
 * @dev A token contract that implements ERC20, and is "owned"/managed by one party.
 * 
 * Custom tokens for organizations on the Hark platform.
 */
contract HarkPlatformToken is Ownable, ERC20Pausable {
    
    //#region --- DATA, MODIFIERS, CONSTRUCTOR ---

    uint16 public tax;                             // platform tax (100% = 10,000)
    uint16 public minimumSupplyForNomination;      // the minimum minted HarkGovernanceTokens for it to be eligible for a vote
    uint32 internal numElections = 0;              // current election count
    mapping(uint => Election) public elections;    // where elections are stored

    /**
     * Creates a new (HARK) HarkPlatformToken.
     * _tax - the starting tax rate (100% = 10,000).
     */
    constructor(uint16 _tax) ERC20("Hark Platform Token", "HARK") {
        tax = _tax;
        minimumSupplyForNomination = 5000;
        _mint(msg.sender, 1000000000);
    }
    
    //#endregion
    
    
    
    //#region --- STRUCTS ---
    
    // represents a user's vote
    struct RegisteredVote {
        bool hasVoted;                 // whether or not the user has voted
        HarkGovernanceToken option;    // the governance token that the user voted for
        uint32 tokenVote;              // the number of tokens that the user voted with at time of voting
    }
    
    // represents a candidate
    struct Candidate {
        bool candidateHasBeenAdded;      // true if this is a proper candidate
        HarkGovernanceToken nominee;     // the hark governance token
        uint64 tokenVote;                // how many tokens have been dedicated
    }
    
    // represents an election for the body
    struct Election {
        uint32 nomineeCount;                                // number of vote options
        mapping(uint32 => Candidate) nominees;              // list of this elections' nominees
        mapping(HarkGovernanceToken => uint32) ids;         // the ids of the tokens
        uint deadline;                                      // the end of the election
        mapping(address => RegisteredVote) voteRegister;    // the people who have voted
        bool winningsDisbursed;                             // if winnings have already been disbursed
    }
    
    //#endregion
    

    
    //#region --- SETTERS ---
    
    // sets the tax rate
    function setTax(uint16 _tax) public onlyOwner {
        require(tax <= 10000);
        tax = _tax;
    }
    
    // sets the minimum governance coins generated to be eligible for a vote
    function setMinimumSupplyForNomination(uint16 _minimum) public onlyOwner {
        minimumSupplyForNomination = _minimum;
    }
    
    // sets transactions paused or not paused
    function setTransactionPause(bool _paused) public onlyOwner returns(bool) {
        if(paused() && !_paused) _unpause();
        else if (!paused() && _paused) _pause();
        
        return paused();
    }
    
    //#endregion

    
    
    //#region --- GETTERS ---
    
    // returns the number of elections published so far
    function getElectionCount() public view returns(uint) { return numElections; }
    
    // returns true if election has ended, false if not
    function electionHasEnded(uint _electId) public view returns(bool) { 
        require(_electId < numElections);
        return elections[_electId].deadline < block.timestamp; 
    }
    
    // returns the number of options based on the election
    function getNomineeCount(uint _electId) public view returns(uint32) {
        require(_electId < getElectionCount());
        return elections[_electId].nomineeCount;
    }
    
    // gets the number of tokens allocated per option
    function getVotesToken(uint _electId, HarkGovernanceToken _token) public view returns(uint) {
        require(_electId < getElectionCount());
        return elections[_electId].nominees[elections[_electId].ids[_token]].tokenVote;
    }
    
    //#endregion
    
    
    
    //#region --- FUNCTIONALITY ---
    
    // throws back tfuel if someone tries to directly send it here
    fallback () external { revert("Contract doesn't take gas directly."); }
    
    // adds or changes a user's vote in a specific election
    function vote(HarkGovernanceToken _nominee, uint _electId) public {
        require(_electId < getElectionCount(), "Bad election ID.");
        require(elections[_electId].nominees[elections[_electId].ids[_nominee]].candidateHasBeenAdded, "Bad vote option.");
        require(!electionHasEnded(_electId), "Election has ended.");

        // retrieves the token amount of the voter
        uint32 voterTokens = uint32(balanceOf(msg.sender));
        
        // changes if the user has already voted
        if(elections[_electId].voteRegister[msg.sender].hasVoted) {
            // removes previous vote values
            HarkGovernanceToken previousNominee = elections[_electId].voteRegister[msg.sender].option;
            uint32 prevOptId = elections[_electId].ids[previousNominee];
            elections[_electId].nominees[prevOptId].tokenVote -= elections[_electId].voteRegister[msg.sender].tokenVote;
        }
        
        // adds voter record
        elections[_electId].voteRegister[msg.sender] = RegisteredVote(true, _nominee, voterTokens);

        // adds to total sum
        elections[_electId].nominees[elections[_electId].ids[_nominee]] .tokenVote += voterTokens;
    }
    
    // creates a new election & returns its id
    function createVote(uint _deadline) onlyOwner public returns(uint) {
        uint _electId = getElectionCount() - 1;
        if(!elections[_electId].winningsDisbursed) {
            sendWinnings(_electId);
        }

        elections[numElections].deadline = _deadline;
        numElections += 1;
        return getElectionCount() - 1;
    }
    
    // attempts to add a nominee to the options
    function nominate(uint _electId, HarkGovernanceToken _nominee) public {
        require(_nominee.totalSupply() >= minimumSupplyForNomination);
        require(!electionHasEnded(_electId));
        require(!elections[_electId].nominees[elections[_electId].ids[_nominee]].candidateHasBeenAdded);
        require(balanceOf(msg.sender) > 0);
        
        uint32 nomNum = elections[_electId].ids[_nominee];
        elections[_electId].nominees[nomNum] = Candidate(true, _nominee, 0);
        elections[_electId].nomineeCount += 1;
    }
    
    // sends winnings to a certain election
    function sendWinnings(uint _electId) onlyOwner public {
        require(electionHasEnded(_electId));
        require(!elections[_electId].winningsDisbursed);
        require(elections[_electId].nomineeCount > 0);
        
        Candidate memory greatestNominee = elections[_electId].nominees[0];
        for(uint32 i = 1; i < elections[_electId].nomineeCount; i++) {
            if(greatestNominee.tokenVote < elections[_electId].nominees[i].tokenVote) {
                greatestNominee = elections[_electId].nominees[i];
            }
        }
        
        payable(greatestNominee.nominee).transfer(address(this).balance);
    }
    
    // kills the contract to free up space
    function kill() onlyOwner public { selfdestruct(payable(owner())); }
    
    //#endregion
}
