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

web3.eth.defaultAccount = web3.eth.accounts[0];

// web3.eth.personal.newAccount().then((account) => {
//   console.log('account: ', account);
// });

console.log(oracleFee);

// register oracle
function registerOneOracle(account) {
  return registerOracle().send({
    from: account,
    value: oracleFee,
    gas: gasLimit,
  });
}

web3.eth.getAccounts().then((accounts) => {
  //console.log(accounts);

  const noOfGoodOracles = 15;
  const noOfBadOracles = 5;

  const goodOracles = [];
  const badOracles = [];

  let promises = [];

  const response = registerOneOracle(accounts[21]);

  console.log(response);
  promises.push(response);

  // for (let i = 0; i < 1; i++) {
  //   const response = registerOneOracle(accounts[i + 20]);
  //   promises.push(response);
  // }

  Promise.all(promises)
    .then(() => {
      getMyIndexes()
        .call({ from: accounts[21] })
        .then((indexes) => {
          console.log(indexes);
        });
      // goodOracles.concat([...res]);
      // console.log('goodOracles: ', goodOracles);
    })
    .catch((err) => console.log(err));
});

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
