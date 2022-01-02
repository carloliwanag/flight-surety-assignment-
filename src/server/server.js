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

const oracleFee = web3.utils.toWei('1.1', 'ether');
// const gasLimit = web3.utils.toWei('0.000000001', 'ether');
const gasLimit = 6721975;
const { registerOracle, getMyIndexes } = flightSuretyApp.methods;

const noOfOracles = 25;

let oracles = [];

web3.eth.defaultAccount = web3.eth.accounts[0];

// register oracle
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

registerOracles(noOfOracles, 20)
  .then((indexes) => {
    oracles = indexes;
    // console.log('oracles: ', oracles);
  })
  .catch((error) => console.log(error));

// end register oracle

flightSuretyApp.events.OracleRequest(
  {
    fromBlock: 0,
  },
  function (error, event) {
    if (error) console.log(error);
    console.log(event);
  }
);

const app = express();
app.get('/api', (req, res) => {
  res.send({
    message: 'An API for use with your Dapp!',
  });
});

export default app;
