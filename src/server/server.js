import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import express from 'express';

import Web3 from 'web3';

let config = Config['localhost'];
let web3 = new Web3(
  new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws'))
);

let flightSuretyApp = new web3.eth.Contract(
  FlightSuretyApp.abi,
  config.appAddress
);

let accountsAddresses = [];
const oracleFee = web3.utils.toWei('1.1', 'ether');
// const gasLimit = web3.utils.toWei('0.000000001', 'ether');
const gasLimit = 6721975;

// contract methods
const {
  registerOracle,
  getMyIndexes,
  submitOracleResponse,
  fundAirlineAnte,
  registerFlight,
} = flightSuretyApp.methods;

const noOfOracles = 25;
const startingAccountsIndex = 20;

let oracles = [];

web3.eth.defaultAccount = web3.eth.accounts[0];

// start register oracle
function registerOracles(noOfOracles, startingAccountsIndex) {
  const registerOneOracle = (account) => {
    return registerOracle().send({
      from: account,
      value: oracleFee,
      gas: gasLimit,
    });
  };

  return web3.eth.getAccounts().then((accounts) => {
    //console.log(accounts);
    accountsAddresses = accounts;
    let promises = [];

    for (let i = 0; i < noOfOracles; i++) {
      const response = registerOneOracle(accounts[i + startingAccountsIndex]);
      promises.push(response);
    }

    return new Promise((resolve, reject) => {
      Promise.all(promises)
        .then(() => {
          const indexesPromises = [];

          for (let i = 0; i < noOfOracles; i++) {
            const response = getMyIndexes().call({
              from: accounts[i + startingAccountsIndex],
            });
            indexesPromises.push(response);
          }

          Promise.all(indexesPromises)
            .then((resp) => {
              // console.log('response: ', resp);
              resolve([...resp]);
            })
            .catch((error) => reject(error));
        })
        .catch((err) => reject(err));
    });
  });
}

registerOracles(noOfOracles, startingAccountsIndex)
  .then((indexes) => {
    oracles = indexes.map((value, index) => {
      return {
        address: accountsAddresses[index + startingAccountsIndex],
        indexes: value,
      };
    });

    // oracles = indexes;
    // console.log('oracles: ', oracles);
  })
  .catch((error) => console.log(error));

// end register oracle

// start generate flight status response

function generateRandomResponse(oracles, values) {
  const STATUS_CODE_UNKNOWN = 0;
  const STATUS_CODE_ON_TIME = 10;
  const STATUS_CODE_LATE_AIRLINE = 20;
  const STATUS_CODE_LATE_WEATHER = 30;
  const STATUS_CODE_LATE_TECHNICAL = 40;
  const STATUS_CODE_LATE_OTHER = 50;

  const responseArr = [
    STATUS_CODE_UNKNOWN,
    STATUS_CODE_ON_TIME,
    STATUS_CODE_LATE_AIRLINE,
    STATUS_CODE_LATE_WEATHER,
    STATUS_CODE_LATE_TECHNICAL,
    STATUS_CODE_LATE_OTHER,
  ];

  const len = oracles.length;
  const good = len / 2 + 1;
  let resp = STATUS_CODE_ON_TIME;
  oracles.forEach((oracle, index) => {
    if (index > good) {
      resp = responseArr[Math.floor(Math.random() * responseArr.length)];
    }

    console.log(
      `sendind this response for oracle address ${oracle.address}:  ${resp}`
    );

    submitOracleResponse(
      values.index,
      values.airline,
      values.flight,
      +values.timestamp,
      resp
    ).send({
      from: oracle.address,
      gas: gasLimit,
    });
  });
}

// initialize airline and flights

function initializeAirlinesFlights() {
  web3.eth.getAccounts().then((accounts) => {
    let antePrice = web3.utils.toWei('10', 'ether');

    fundAirlineAnte().send({
      from: accounts[1],
      value: antePrice,
      gas: gasLimit,
    });

    let flightName1 = 'POED-5934';
    let timestamp1 = Date.now();
    registerFlight(flightName1, timestamp1).send({
      from: accounts[1],
      gas: gasLimit,
    });

    let flightName2 = 'BDEY-2239';
    let timestamp2 = Date.now();
    registerFlight(flightName2, timestamp2).send({
      from: accounts[1],
      gas: gasLimit,
    });

    let flightName3 = 'KCQA-0953';
    let timestamp3 = Date.now();
    registerFlight(flightName3, timestamp3).send({
      from: accounts[1],
      gas: gasLimit,
    });
  });
}

initializeAirlinesFlights();

// end generate flight status response
flightSuretyApp.events.OracleRequest(
  {
    fromBlock: 0,
  },
  function (error, event) {
    if (error) console.log(error);
    // console.log(event);

    const { returnValues } = event;

    // console.log(oracles);
    // console.log(returnValues);

    // this is a bit weird..
    let eventValues = JSON.stringify(returnValues);
    eventValues = JSON.parse(eventValues);

    console.log('OracleRequest event values:', eventValues);

    const matchedOracles = oracles.filter(
      (oracle) => oracle.indexes.indexOf(eventValues.index) !== -1
    );

    console.log('matched oracles for the sent index: ', matchedOracles);

    generateRandomResponse(matchedOracles, eventValues);
  }
);

const app = express();
app.get('/api', (req, res) => {
  res.send({
    message: 'An API for use with your Dapp!',
  });
});

export default app;
