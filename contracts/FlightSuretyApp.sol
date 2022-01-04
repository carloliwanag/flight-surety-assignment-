pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    uint8 private constant NO_REGISTERED_AIRLINES_THRESHOLD = 4;

    address private contractOwner; // Account used to deploy contract

    FlightSuretyDataReference flightSuretyData;

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
        // Modify to call data contract's status
        require(isOperational(), "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireRegisteredAirline(address _address) {
        require(
            isRegisteredAirline(_address),
            "Caller is not a registered airline"
        );
        _;
    }

    modifier requiredFundedAirline(address _address) {
        require(isFundedAirline(_address), "Caller is not a funded airline");
        _;
    }

    modifier requiredNotVoted(address _address, address _voter) {
        require(
            !hasVotedAirline(_address, _voter),
            "Caller has already voted for this airline"
        );
        _;
    }

    modifier requiredNotRegisteredFlight(
        string _flightName,
        uint256 _timestamp,
        address _airline
    ) {
        require(
            !isRegisteredFlight(_flightName, _airline, _timestamp),
            "Flight is already registered."
        );
        _;
    }

    modifier requiredRegisteredFlight(
        string _flightName,
        uint256 _timestamp,
        address _airline
    ) {
        require(
            isRegisteredFlight(_flightName, _airline, _timestamp),
            "Flight does not exist."
        );
        _;
    }

    modifier requiredNotBoughtInsurance(
        address _airline,
        string _flightName,
        uint256 _timestamp,
        address _passenger
    ) {
        require(
            !hasBoughtInsurance(_airline, _flightName, _timestamp, _passenger),
            "Passenger has insurance"
        );
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
     * @dev Contract constructor
     *
     */
    constructor(address flightSuretyDataContract) public {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyDataReference(flightSuretyDataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns (bool) {
        // return true; // Modify to call data contract's status
        return flightSuretyData.isOperational();
    }

    function isRegisteredAirline(address _address) public view returns (bool) {
        return flightSuretyData.isRegisteredAirline(_address);
    }

    function isFundedAirline(address _address) public view returns (bool) {
        return flightSuretyData.isFundedAirline(_address);
    }

    function hasVotedAirline(address _address, address _voter)
        public
        view
        returns (bool)
    {
        return flightSuretyData.hasVotedAirline(_address, _voter);
    }

    function isRegisteredFlight(
        string _flightName,
        address _airline,
        uint256 _timestamp
    ) public view returns (bool) {
        return
            flightSuretyData.isRegisteredFlight(
                _flightName,
                _timestamp,
                _airline
            );
    }

    function hasBoughtInsurance(
        address _airline,
        string _flightName,
        uint256 _timestamp,
        address _passenger
    ) public view returns (bool) {
        bytes32 _flightKey = getFlightKey(_airline, _flightName, _timestamp);
        return flightSuretyData.hasBoughtInsurance(_flightKey, _passenger);
    }

    function isRegisteredPassenger(address _passenger)
        public
        view
        returns (bool)
    {
        return flightSuretyData.isRegisteredPassenger(_passenger);
    }

    function getFlightStatus(
        address _airline,
        string _flightName,
        uint256 _timestamp
    ) public view returns (uint8) {
        return
            flightSuretyData.getFlightStatus(_airline, _flightName, _timestamp);
    }

    function getFlightsList() public view returns (string[]) {
        return flightSuretyData.getFlightsList();
    }

    function getAccountBalance(address _passenger)
        public
        view
        returns (uint256)
    {
        return flightSuretyData.getAccountBalance(_passenger);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *
     */
    function registerAirline(address _address, string _name)
        external
        requireIsOperational
        requireRegisteredAirline(msg.sender)
        requiredFundedAirline(msg.sender)
    {
        if (
            flightSuretyData.getNumberOfRegiseteredAirlines() <
            NO_REGISTERED_AIRLINES_THRESHOLD
        ) {
            flightSuretyData.registerAirline(_name, false, true, _address);
        } else {
            require(
                !hasVotedAirline(_address, msg.sender),
                "Caller has already voted for this airline"
            );
            uint256 noOfAirlines = flightSuretyData
                .getNumberOfRegiseteredAirlines();
            uint256 noOfVotes = flightSuretyData.getVotesOfAirline(_address);

            if (noOfVotes.add(1) > noOfAirlines.div(2)) {
                flightSuretyData.registerAirline(_name, false, true, _address);
            } else {
                flightSuretyData.voteAirline(_address, msg.sender);
            }
        }
    }

    function fundAirlineAnte()
        external
        payable
        requireIsOperational
        requireRegisteredAirline(msg.sender)
    {
        require(msg.value >= 10 ether, "Airline does not have enough ethers");
        flightSuretyData.payAnte(msg.sender);
        address(flightSuretyData).transfer(msg.value);
    }

    /**
     * @dev Register a future flight for insuring.
     *
     */
    function registerFlight(string _flightName, uint256 _timestamp)
        external
        requireIsOperational
        requireRegisteredAirline(msg.sender)
        requiredFundedAirline(msg.sender)
        requiredNotRegisteredFlight(_flightName, _timestamp, msg.sender)
    {
        flightSuretyData.registerFlight(
            _flightName,
            STATUS_CODE_UNKNOWN,
            _timestamp,
            msg.sender
        );
    }

    /**
     * @dev Called after oracle has updated flight status
     *
     */
    function processFlightStatus(
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode
    ) internal requireIsOperational {
        flightSuretyData.updateFlight(flight, statusCode, timestamp, airline);
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
        address airline,
        string flight,
        uint256 timestamp
    ) external {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        oracleResponses[key] = ResponseInfo({
            requester: msg.sender,
            isOpen: true
        });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; // Account that requested status
        bool isOpen; // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses; // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    event OracleReport(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp
    );

    // Register an oracle with the contract
    function registerOracle() external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() external view returns (uint8[3]) {
        require(
            oracles[msg.sender].isRegistered,
            "Not registered as an oracle"
        );

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp,
        uint8 statusCode
    ) external {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request"
        );

        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        require(
            oracleResponses[key].isOpen,
            "Flight or timestamp do not match oracle request"
        );

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (
            oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES
        ) {
            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    function buyInsurance(
        address _airline,
        string _flight,
        uint256 _timestamp
    )
        external
        payable
        requireIsOperational
        requiredRegisteredFlight(_flight, _timestamp, _airline)
        requiredNotBoughtInsurance(_airline, _flight, _timestamp, msg.sender)
    {
        require(msg.value > 1 wei, "Insufficient funds");
        require(msg.value <= 1 ether, "Max 1 ether allowed");
        // bytes32 _flightKey = getFlightKey(_airline, _flight, _timestamp);
        flightSuretyData.buy(
            _airline,
            _flight,
            _timestamp,
            msg.value,
            msg.sender
        );
        address(flightSuretyData).transfer(msg.value);
    }

    function getFlightKey(
        address airline,
        string flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns (uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - nonce++), account)
                )
            ) % maxValue
        );

        if (nonce > 250) {
            nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    // endregion
}

// Data Reference/Interface

contract FlightSuretyDataReference {
    function isOperational() external view returns (bool);

    function registerAirline(
        string _name,
        bool _isFunded,
        bool _isRegistered,
        address _address
    ) external;

    function getNumberOfRegiseteredAirlines() external view returns (uint256);

    function isRegisteredAirline(address _address) external view returns (bool);

    function isFundedAirline(address _address) external view returns (bool);

    function getVotesOfAirline(address _address)
        external
        view
        returns (uint256);

    function hasVotedAirline(address _address, address _voter)
        external
        view
        returns (bool);

    function voteAirline(address _address, address _voter) external;

    function payAnte(address _airline) external payable;

    function isRegisteredFlight(
        string _flightName,
        uint256 _timestamp,
        address _airline
    ) external view returns (bool);

    function registerFlight(
        string _flightName,
        uint8 _statusCode,
        uint256 _updatedTimestamp,
        address _airline
    ) external;

    function buy(
        address _airline,
        string _flightName,
        uint256 _timestamp,
        uint256 _amount,
        address _passenger
    ) external payable;

    function hasBoughtInsurance(bytes32 _flightKey, address _passenger)
        public
        view
        returns (bool);

    function isRegisteredPassenger(address _passenger)
        public
        view
        returns (bool);

    function updateFlight(
        string _flightName,
        uint8 _statusCode,
        uint256 _updatedTimestamp,
        address _airline
    ) external;

    function getFlightStatus(
        address _airline,
        string _flightName,
        uint256 _timestamp
    ) external view returns (uint8 status);

    function getFlightsList() external view returns (string[]);

    function getAccountBalance(address _passenger)
        external
        view
        returns (uint256);
}
