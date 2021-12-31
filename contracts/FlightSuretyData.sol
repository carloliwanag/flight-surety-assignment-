pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false

    struct Airline {
        bool isRegistered;
        bool isFunded;
        address airlineAddress;
        string name;
    }

    struct Candidate {
        mapping(address => bool) voters;
        uint256 noOfVotes;
        bool exist;
    }

    address[] private registeredAirlines;
    mapping(address => Airline) registeredAirlinesMapping;
    mapping(address => Candidate) votes;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor(address _firstAirline) public {
        contractOwner = msg.sender;

        // deploy the first airline
        registeredAirlinesMapping[_firstAirline] = Airline({
            isRegistered: true,
            isFunded: false,
            airlineAddress: _firstAirline,
            name: "First Airline"
        });
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() external view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    function isRegisteredAirline(address _address)
        external
        view
        returns (bool)
    {
        return registeredAirlinesMapping[_address].isRegistered;
    }

    function isFundedAirline(address _address) external view returns (bool) {
        return registeredAirlinesMapping[_address].isFunded;
    }

    function getVotesOfAirline(address _address)
        external
        view
        returns (uint256)
    {
        return votes[_address].noOfVotes;
    }

    function hasVotedAirline(address _address, address _voter)
        external
        view
        returns (bool)
    {
        votes[_address].voters[_voter];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(
        string _name,
        bool _isFunded,
        bool _isRegistered,
        address _address
    ) external {
        Airline memory newAirline = Airline({
            name: _name,
            isRegistered: _isRegistered,
            isFunded: _isFunded,
            airlineAddress: _address
        });

        // this should be called when the airline has paid the ante
        //registeredAirlines.push(newAirline);
        registeredAirlinesMapping[_address] = newAirline;
    }

    function getNumberOfRegiseteredAirlines() external view returns (uint256) {
        return registeredAirlines.length;
    }

    function voteAirline(address _address, address _voter) external {
        if (votes[_address].exist) {
            Candidate storage candidate = votes[_address];
            candidate.voters[_voter] = true;
            candidate.noOfVotes = candidate.noOfVotes.add(1);
        } else {
            Candidate freshCandidate;
            freshCandidate.voters[_voter] = true;
            freshCandidate.noOfVotes = 1;
            freshCandidate.exist = true;
            votes[_address] = freshCandidate;
        }
    }

    function payAnte(address _airline) external payable {
        //require(registeredAirlinesMapping[msg.sender], "Not registered");
        //require(msg.value >= 10 ether, "Airline does not have enough ethers");

        registeredAirlinesMapping[_airline].isFunded = true;
        registeredAirlines.push(_airline);
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy() external payable {}

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees() external pure {}

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay() external pure {}

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund() public payable {}

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function() external payable {
        fund();
    }
}
