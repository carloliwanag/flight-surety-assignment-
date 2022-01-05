# FlightSurety

FlightSurety is a sample application project for Udacity's Blockchain course.

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`

## Develop Client

To run truffle tests:

`truffle test ./test/flightSurety.js`
`truffle test ./test/oracles.js`

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`

## Develop Server

`npm run server`


## Running locally for testing:
Needs at least 4 terminals open.

1. (first terminal) - Run start-ganache-cli.sh or copy and paste the command 
```
ganache-cli -m "render bachelor above exact flash cloth license wine guard edit sugar enhance" --accounts=100 -p 8545
```

2. (second terminal) - Deploy the smart contract using the command) `truffle migrate --reset`

3. (third terminal) - Run the server `npm run server`

4. (fourth terminal) - Run the dapp `npm run dapp`


First Airline: 0x8775cEFC4557B31D15Df9DA724cf6652E1CD1A73

Passenger: 0xD1170d805aF984AB95f7ded8E579B560eA3E8472

### Other notes
- server initializes the flights by calling the smart contract and has API for pulling the flights for the DAPP
- the oracles are purposely set to make the flights late, this can be overriden in the method generateRandomResponse(); line 123
- due to the lack of time, I was not able to implement the security for making sure only selected app contract can only invoke the data contract. but since this is not a requirement, I did not finish this.

### Steps for testing
1. Click Show button to see the flights.
2. Buy an insurance for a selected flight, input value in text field. click Buy button.
3. Click Submit to Oracles button to see the flight arrival status.
4. Check balance by clicking Get Balance button.
5. Withdraw by putting value on the amount and then click Withdraw button.

## Resources

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)

## Implementation Details

### Airline Registration

To hold the registered airlines, an Airline struct and a mapping of the Airline struct is created.

```
struct Airline {
        bool isRegistered;
        bool isFunded;
        address airlineAddress;
        string name;
    }

mapping(address => Airline) registeredAirlinesMapping;
```

To handle the business requirement for the consensus, a separate array of registered (paid) airline is maintained to get the current number of registered airlines. And anothe pair of struct and mapping for the voted airline that will be registerd to monitor the number of votes it has received.

```
address[] private registeredAirlines;

struct Candidate {
        mapping(address => bool) voters;
        uint256 noOfVotes;
        bool exist;
    }
mapping(address => Candidate) votes;
```

For an airline to register another airline, the ff modifiers should be met:
```
requireOperational
requireRegisteredAirline(msg.sender)
requireFundedAirline(msg.sender)
```
and it should not be allowed to vote more than twice on the same airline

```
require(!hasVotedAirline(_address, msg.sender), "Caller has already voted for this airline");
```

To facilitate Multiparty consensus, the number of votes an airline has received is compared to the number of registered (paid) airlines array divided by 2. If greater, the airline is registered else, a vote is added onto it.


### Oracle Flight Status

App contract receives the data from the oracles. Once flight status is verified, flight information is updated in the Data contract. 

If flight is late, the Passengers list is traversed to see if they have purchased the insurance for the flight, if yes the balance is updated.


### Withrdawal of insurance
The passenger struct has a balance property that is updated if one of the insurance bought has flight arrived late. 

```
struct Passenger {
        mapping(bytes32 => Insurance) insurances;
        bool isRegistered;
        uint256 balance;
    }

```

