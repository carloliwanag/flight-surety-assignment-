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
`truffle test ./test/oracles.js`

## Deploy

To build dapp for prod:
`npm run dapp:prod`

Deploy the contents of the ./dapp folder


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
Airline[] private registeredAirlines;

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