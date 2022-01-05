pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    // uint256 private constant MULTIPLIER = 1.5;

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

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }
    mapping(bytes32 => Flight) private flights;
    string[] public flightsList;

    struct Insurance {
        uint256 amount;
        bytes32 flightKey;
        bool isCredited;
        bool isBought;
        bool forPayment;
    }

    struct Passenger {
        mapping(bytes32 => Insurance) insurances;
        bool isRegistered;
        uint256 balance;
    }

    mapping(address => Passenger) passengers;
    address[] private passengersList;

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
        return votes[_address].voters[_voter];
    }

    function isRegisteredFlight(
        string _flightName,
        uint256 _timestamp,
        address _airline
    ) external view returns (bool) {
        bytes32 flightKey = getFlightKey(_airline, _flightName, _timestamp);
        return flights[flightKey].isRegistered;
    }

    function isRegisteredPassenger(address _passenger)
        public
        view
        returns (bool)
    {
        return passengers[_passenger].isRegistered;
    }

    function hasBoughtInsurance(bytes32 _flightKey, address _passenger)
        public
        view
        returns (bool)
    {
        return passengers[_passenger].insurances[_flightKey].isBought;
    }

    function getInsurance(
        address _airline,
        string _flightName,
        uint256 _timestamp,
        address _passenger
    )
        public
        view
        returns (
            uint256 amount,
            bool isCredited,
            bool isBought,
            bytes32 flightKey,
            bool isRegistered,
            bool forPayment
        )
    {
        isRegistered = passengers[_passenger].isRegistered;

        Passenger passenger = passengers[_passenger];

        bytes32 _flightKey = getFlightKey(_airline, _flightName, _timestamp);

        Insurance memory insurance = passenger.insurances[_flightKey];
        amount = insurance.amount;
        isCredited = insurance.isCredited;
        isBought = insurance.isBought;
        flightKey = insurance.flightKey;
        forPayment = insurance.forPayment;
    }

    function getFlightStatus(
        address _airline,
        string _flightName,
        uint256 _timestamp
    ) external view returns (uint8 status) {
        bytes32 _flightKey = getFlightKey(_airline, _flightName, _timestamp);

        status = flights[_flightKey].statusCode;
    }

    function getFlightsList() external view returns (string[]) {
        return flightsList;
    }

    function getAccountBalance(address _passenger)
        external
        view
        returns (uint256)
    {
        return passengers[_passenger].balance;
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
            Candidate storage freshCandidate;
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

    function registerFlight(
        string _flightName,
        uint8 _statusCode,
        uint256 _updatedTimestamp,
        address _airline
    ) external {
        // require(!flights[_flightName].isRegistered, "Flight already exists.");

        bytes32 flightKey = getFlightKey(
            _airline,
            _flightName,
            _updatedTimestamp
        );

        Flight memory flight = Flight({
            isRegistered: true,
            statusCode: _statusCode,
            updatedTimestamp: _updatedTimestamp,
            airline: _airline
        });

        flights[flightKey] = flight;
        flightsList.push(_flightName);
    }

    // TODO: only allow selected contracts to call this
    function updateFlight(
        string _flightName,
        uint8 _statusCode,
        uint256 _updatedTimestamp,
        address _airline
    ) external {
        bytes32 flightKey = getFlightKey(
            _airline,
            _flightName,
            _updatedTimestamp
        );

        flights[flightKey].statusCode = _statusCode;

        // this is a side-effect, should be called by the App

        if (
            _statusCode != STATUS_CODE_UNKNOWN &&
            _statusCode != STATUS_CODE_ON_TIME
        ) {
            updatePassengerInsurances(
                _flightName,
                _statusCode,
                _updatedTimestamp,
                _airline
            );
        }
    }

    function updatePassengerInsurances(
        string _flightName,
        uint8 _statusCode,
        uint256 _updatedTimestamp,
        address _airline
    ) internal {
        if (passengersList.length > 0) {
            bytes32 flightKey = getFlightKey(
                _airline,
                _flightName,
                _updatedTimestamp
            );
            for (uint256 i = 0; i < passengersList.length; i++) {
                address passenger = passengersList[i];
                if (
                    passengers[passenger].insurances[flightKey].isBought && // passenger has the insurance
                    !passengers[passenger].insurances[flightKey].forPayment // prevents double payment
                ) {
                    creditInsurees(
                        _airline,
                        _flightName,
                        _updatedTimestamp,
                        passenger
                    );
                }
            }
        }
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy(
        address _airline,
        string _flightName,
        uint256 _timestamp,
        uint256 _amount,
        address _passenger
    ) external payable {
        bytes32 _flightKey = getFlightKey(_airline, _flightName, _timestamp);

        Insurance memory insurance;
        insurance.amount = _amount;
        insurance.flightKey = _flightKey;
        insurance.isBought = true;
        insurance.isCredited = false;
        insurance.forPayment = false;

        // check if passenger has bought insurance
        if (isRegisteredPassenger(_passenger)) {
            passengers[_passenger].insurances[_flightKey] = insurance;
        } else {
            Passenger memory passenger;
            passenger.isRegistered = true;
            passenger.balance = 0;
            passengers[_passenger] = passenger;
            passengers[_passenger].insurances[_flightKey] = insurance;

            passengersList.push(_passenger);
            // passenger.insurances[_flightKey] = insurance;
        }
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(
        address _airline,
        string _flightName,
        uint256 _timestamp,
        address _passenger
    ) internal {
        bytes32 _flightKey = getFlightKey(_airline, _flightName, _timestamp);
        Passenger storage passenger = passengers[_passenger];
        uint256 value = passenger.insurances[_flightKey].amount.mul(3).div(2);

        passenger.insurances[_flightKey].isCredited = true;
        passenger.insurances[_flightKey].forPayment = true;

        passenger.balance = passenger.balance.add(value);
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay(address _passenger, uint256 amount) external {
        require(isRegisteredPassenger(_passenger), "Should be a passenger");
        require(passengers[_passenger].balance > 0, "Should have balance");
        require(passengers[_passenger].balance >= amount, "Not enough balance");

        passengers[_passenger].balance = passengers[_passenger].balance.sub(
            amount
        );

        _passenger.transfer(amount);

        // TODO: delete the passeger from the list and mapping if there are no more insurance
    }

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
