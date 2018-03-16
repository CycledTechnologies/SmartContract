require('dotenv').load();
require('babel-register');
require('babel-polyfill');

var Web3 = require("web3");
var TrezorProvider = require("@daonomic/trezor-wallet-provider");
var ProviderEngine = require("web3-provider-engine");
var FiltersSubprovider = require('web3-provider-engine/subproviders/filters.js');
var Web3Subprovider = require("web3-provider-engine/subproviders/web3.js");
var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "oil prefer pole pottery ginger stem blood hold profit inject giraffe echo";
var path = "m/44'/1'/0'/0/0";
//var provider_url = "https://rinkeby.infura.io/jkYJLm4yhJuFJqGAVvMe";
var provider_url = "http://localhost:8545";

var engine = new ProviderEngine();
engine.addProvider(new TrezorProvider(path));
engine.addProvider(new FiltersSubprovider());
engine.addProvider(new Web3Subprovider(new Web3.providers.HttpProvider(provider_url)));
engine.start();



module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*' // Match any network id
    },
    hDWallet: {
      network_id: 4,    
      provider: new HDWalletProvider(mnemonic, provider_url, 0),// 
    },
    trezor: {
      network_id: 4,    
      provider: engine,
      from: '0x33Be6b989C0dd56721404C6495f5B50eF64B70c0'
    }
  }
}
