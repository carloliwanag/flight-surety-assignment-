import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
// import Web3 from 'web3';

export default class Contract {
  constructor(network, callback) {
    let config = Config[network];
    this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
    this.flightSuretyApp = new this.web3.eth.Contract(
      FlightSuretyApp.abi,
      config.appAddress
    );
    this.initialize(callback);
    this.owner = null;
    this.airlines = [];
    this.passengers = [];
  }

  initialize(callback) {
    this.web3.eth.getAccounts((error, accts) => {
      this.owner = accts[0];

      let counter = 1;

      while (this.airlines.length < 5) {
        this.airlines.push(accts[counter++]);
      }

      while (this.passengers.length < 5) {
        this.passengers.push(accts[counter++]);
      }

      callback();
    });
  }

  // @deprecated
  fetchFlightsList() {
    let self = this;
    return new Promise((resolve, reject) => {
      self.flightSuretyApp.methods
        .getFlightsList()
        .call({ from: self.owner })
        .then((data) => resolve(data));
    });
  }

  buyInsurance(airline, flight, timestamp) {
    let self = this;
    return new Promise((resolve, reject) => {
      self.flightSuretyApp.methods
        .buyInsurance(airline, flight, timestamp)
        .send({
          from: '0xD1170d805aF984AB95f7ded8E579B560eA3E8472',
          value: this.web3.utils.toWei('1', 'ether'),
          gas: 6721975,
        })
        .then((data) => {
          console.log(data);
          resolve('ok');
        })
        .catch((err) => reject(err));
    });
  }

  isOperational(callback) {
    let self = this;
    self.flightSuretyApp.methods
      .isOperational()
      .call({ from: self.owner }, callback);
  }

  // calls fetchFlight status to trigger oracles
  getFlightStatus(airline, flight, timestamp) {
    let self = this;

    return new Promise((resolve, reject) => {
      self.flightSuretyApp.methods
        .fetchFlightStatus(airline, flight, timestamp)
        .send({ from: self.owner })
        .then((results) => {
          // console.log(results);

          resolve(results);
        })
        .catch((err) => reject(err));
    });
  }

  // calls the smart contract to fetch status code of flight
  getFlightStatusCode(airline, flight, timestamp) {
    let self = this;

    return new Promise((resolve, reject) => {
      self.flightSuretyApp.methods
        .getFlightStatus(airline, flight, timestamp)
        .call({ from: self.owner })
        .then((result) => resolve(result))
        .catch((err) => reject(err));
    });
  }

  fetchFlightStatus(flight, callback) {
    let self = this;
    let payload = {
      airline: self.airlines[0],
      flight: flight,
      timestamp: Math.floor(Date.now() / 1000),
    };
    self.flightSuretyApp.methods
      .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
      .send({ from: self.owner }, (error, result) => {
        callback(error, payload);
      });
  }
}
