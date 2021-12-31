var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {
  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    // await config.flightSuretyData.authorizeCaller(
    //   config.flightSuretyApp.address
    // );
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {
    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, 'Incorrect initial operating status value');
  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {
    // Ensure that access is denied for non-Contract Owner account
    let accessDenied = false;
    try {
      await config.flightSuretyData.setOperatingStatus(false, {
        from: config.testAddresses[2],
      });
    } catch (e) {
      accessDenied = true;
    }
    assert.equal(accessDenied, true, 'Access not restricted to Contract Owner');
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {
    // Ensure that access is allowed for Contract Owner account
    let accessDenied = false;
    try {
      await config.flightSuretyData.setOperatingStatus(false);
    } catch (e) {
      accessDenied = true;
    }
    assert.equal(
      accessDenied,
      false,
      'Access not restricted to Contract Owner'
    );
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {
    await config.flightSuretyData.setOperatingStatus(false);

    let reverted = false;
    try {
      await config.flightSurety.setTestingMode(true);
    } catch (e) {
      reverted = true;
    }
    assert.equal(reverted, true, 'Access not blocked for requireIsOperational');

    // Set it back for other tests to work
    await config.flightSuretyData.setOperatingStatus(true);
  });

  it('Should have an initial airline', async function () {
    let firstAirline = '0x8775cefc4557b31d15df9da724cf6652e1cd1a73'; // second account

    const registered = await config.flightSuretyApp.isRegisteredAirline.call(
      firstAirline
    );
    assert.ok(registered);
  });

  it('Should allow airlines to pay the ante', async () => {
    let firstAirline = '0x8775cefc4557b31d15df9da724cf6652e1cd1a73'; // second account
    let antePrice = web3.utils.toWei('10', 'ether');
    await config.flightSuretyApp.fundAirlineAnte({
      from: firstAirline,
      value: antePrice,
    });
    const isFunded = await config.flightSuretyApp.isFundedAirline(firstAirline);
    assert.ok(isFunded);
  });

  it('Should allow initial airline to register 3 other airlines', async () => {
    let firstAirline = '0x8775cefc4557b31d15df9da724cf6652e1cd1a73'; // second account
    let secondAirline = '0xb122e9837790dec2602b3a2e80c9317ebf4edd23';
    let thirdAirline = '0x3e6d35d10d3f6a81e2c51d48940a2afdda574e66';
    let fourthAirline = '0xb2c3935fc40dc92bb625d648724498f1fadccc86';

    await config.flightSuretyApp.registerAirline(
      secondAirline,
      'Second Airline',
      {
        from: firstAirline,
      }
    );
    await config.flightSuretyApp.registerAirline(
      thirdAirline,
      'Third Airline',
      {
        from: firstAirline,
      }
    );
    await config.flightSuretyApp.registerAirline(
      fourthAirline,
      'Fourth Airline',
      {
        from: firstAirline,
      }
    );

    let isRegistered = await config.flightSuretyApp.isRegisteredAirline.call(
      secondAirline
    );
    assert.ok(isRegistered);

    isRegistered = await config.flightSuretyApp.isRegisteredAirline.call(
      thirdAirline
    );
    assert.ok(isRegistered);

    isRegistered = await config.flightSuretyApp.isRegisteredAirline.call(
      fourthAirline
    );
    assert.ok(isRegistered);
  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    // ARRANGE
    let secondAirline = '0xb122e9837790dec2602b3a2e80c9317ebf4edd23';
    let fifthAirline = '0x5a351fc02094747aa5430fb69a651fb57c8922d5';

    // ACT
    try {
      await config.flightSuretyApp.registerAirline(fifthAirline, {
        from: secondAirline,
      });
    } catch (e) {}
    let result = await config.flightSuretyData.isRegisteredAirline.call(
      fifthAirline
    );

    // ASSERT
    assert.equal(
      result,
      false,
      "Airline should not be able to register another airline if it hasn't provided funding"
    );
  });

  it('should demonstrate multiparty consensus in registering airline', async () => {
    let secondAirline = '0xb122e9837790dec2602b3a2e80c9317ebf4edd23';
    let thirdAirline = '0x3e6d35d10d3f6a81e2c51d48940a2afdda574e66';
    let fourthAirline = '0xb2c3935fc40dc92bb625d648724498f1fadccc86';

    let antePrice = web3.utils.toWei('10', 'ether');
    await config.flightSuretyApp.fundAirlineAnte({
      from: secondAirline,
      value: antePrice,
    });

    await config.flightSuretyApp.fundAirlineAnte({
      from: thirdAirline,
      value: antePrice,
    });

    await config.flightSuretyApp.fundAirlineAnte({
      from: fourthAirline,
      value: antePrice,
    });

    let fifthAirline = '0x5a351fc02094747aa5430fb69a651fb57c8922d5';

    await config.flightSuretyApp.registerAirline(
      fifthAirline,
      'Fifth Airline',
      {
        from: secondAirline,
      }
    );

    let isRegistered = await config.flightSuretyData.isRegisteredAirline.call(
      fifthAirline
    );
    assert.ok(!isRegistered);

    await config.flightSuretyApp.registerAirline(
      fifthAirline,
      'Fifth Airline',
      {
        from: thirdAirline,
      }
    );

    isRegistered = await config.flightSuretyData.isRegisteredAirline.call(
      fifthAirline
    );
    assert.ok(isRegistered);
  });
});
