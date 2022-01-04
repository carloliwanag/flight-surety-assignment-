const FlightSuretyApp = artifacts.require('FlightSuretyApp');
const FlightSuretyData = artifacts.require('FlightSuretyData');
const fs = require('fs');

module.exports = function (deployer) {
  let firstAirline = '0x8775cEFC4557B31D15Df9DA724cf6652E1CD1A73'; // second account
  deployer.deploy(FlightSuretyData, firstAirline).then((result) => {
    return deployer.deploy(FlightSuretyApp, result.address).then(() => {
      let config = {
        localhost: {
          url: 'http://localhost:8545',
          dataAddress: FlightSuretyData.address,
          appAddress: FlightSuretyApp.address,
        },
      };
      fs.writeFileSync(
        __dirname + '/../src/dapp/config.json',
        JSON.stringify(config, null, '\t'),
        'utf-8'
      );
      fs.writeFileSync(
        __dirname + '/../src/server/config.json',
        JSON.stringify(config, null, '\t'),
        'utf-8'
      );
    });
  });
};
