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

    
    // creator of the token
    // platform tax
    int16 public tax; // 100% = 10,000
    
    // the minimum minted required to be eligible for a vote
    uint16 public minimumSupplyForNomination;
    
    // election info
    uint numElections;
    mapping(uint => Election) public elections;
    
    // voting
    uint32 electionNum = 0; // current election

    constructor(int16 _tax) ERC20("Hark Platform Token", "HARK") {
        tax = _tax;
        minimumSupplyForNomination = 5000;
    }
    
    // governing entity info
    HarkGovernanceToken public token;

    
    //#endregion
    


    //#region --- STRUCTS ---
    
    // represents a user's vote
    struct RegisteredVote {
        // whether or not the user has voted
        bool hasVoted;
        
        // the option that the user voted for
        HarkGovernanceToken option;
        
        // the number of tokens that the user voted with at time of voting
        uint32 tokenVote;
    }
    
    // represents a candidate
    struct Candidate {
        bool candidateHasBeenAdded;
        HarkGovernanceToken nominee;
        uint64 tokenVote;
    }
    
    // represents an election for the body
    struct Election {
        // number of vote options
        uint32 nomineeCount;
        mapping(uint32 => Candidate) nominees;
        mapping(HarkGovernanceToken => uint32) ids;

        // the end of the election
        uint deadline;
        
        // the people who have voted
        mapping(address => RegisteredVote) voteRegister;
        
        // if winnings have been finished
        bool winningsDisbursed;
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
        uint32 voterTokens = uint32(token.balanceOf(msg.sender));
        
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
