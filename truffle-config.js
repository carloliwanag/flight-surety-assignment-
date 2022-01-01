var HDWalletProvider = require('truffle-hdwallet-provider');
var mnemonic =
  'render bachelor above exact flash cloth license wine guard edit sugar enhance';

module.exports = {
  networks: {
    development: {
      provider: function () {
        return new HDWalletProvider(mnemonic, 'http://127.0.0.1:8545/', 0, 50);
      },
      network_id: '*',
      gas: 6000000,
      gasPrice: 0,
    },
  },
  compilers: {
    solc: {
      version: '^0.4.24',
    },
  },
};
