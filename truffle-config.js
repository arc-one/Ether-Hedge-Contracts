const HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "mobile occur used fine audit online tent ethics shine enact conduct memory";




module.exports = {
  // Uncommenting the defaults below
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!

  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gas: 6700000
    },
    test: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gas: 6700000
    },
    kovan_infura: {
      provider: () => new HDWalletProvider(mnemonic, "https://kovan.infura.io/v3/18d43f3c5df04995b631924d5203aec7"),
      network_id: 42,
      gas: 6700000
    },
    ropsten_infura: {
      provider: () => new HDWalletProvider(mnemonic, "https://ropsten.infura.io/v3/18d43f3c5df04995b631924d5203aec7"),
      network_id: 3,
      gas: 6700000
    },
/*
    ropsten: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 3,
      gas: 1000000
    },
*/
  },
  mocha: {
    enableTimeouts: false
  }
};
