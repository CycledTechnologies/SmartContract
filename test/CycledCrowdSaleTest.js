require('./helpers/spec_helper.js');
var CycledToken = artifacts.require("./CycledToken.sol");
var CycledCrowdsale = artifacts.require("./CycledCrowdsale.sol");
var Whitelist = artifacts.require("./Whitelist.sol");


contract('CycledCrowdsale', function ([owner, acc]) {
    let whitelist;
    let token; 
    let crowdsale;
    let fundWallet = "0xad2718380f4f95a4636088606eddd66dd56b517f";
    let recyclingIncentivesWallet = "0x41407962c3a18edbcaa98a5cc071433111b66ccc";
    let cycledTechnologiesWallet = "0xfb51ebe7b377f11d5d38112979ed7ffd27cc26fc";
    let foundersWallet = "0xa9207175a2a8425db5c496e120b2ec28ba0a39e4";
    let bountyWallet = "0x33ec7ecf1a5aaebdf97a8603dcf3f04127d21035";

    beforeEach(async function () {
        whitelist = await Whitelist.new({from: owner});
        // address _recyclingIncentivesWallet, address _cycledTechnologiesWallet, address _foundersWallet, address _bountyWallet
        token = await CycledToken.new(recyclingIncentivesWallet, cycledTechnologiesWallet, foundersWallet, bountyWallet, {from: owner});

        //address _tokenAddress, address _whitelistAddress, address _fundWallet
        crowdsale = await CycledCrowdsale.new(token.address, whitelist.address, fundWallet,  {from: owner});
    });

    describe("Sale check", function () {
        it('Sale Hard Cap', async function () {
            let expectedPreSaleHarCap = new BigNumber(web3.toWei('200000000', 'ether'));
            const PreSaleHarCap = await crowdsale.PRE_SALE_HARD_CAP();
            expect(PreSaleHarCap).to.be.bignumber.equal(expectedPreSaleHarCap);

            let expectedMainSaleHarCap = new BigNumber(web3.toWei('300000000', 'ether'));
            const MainSaleHarCap = await crowdsale.MAIN_SALE_HARD_CAP();
            expect(MainSaleHarCap).to.be.bignumber.equal(expectedMainSaleHarCap);
        });    
    });
  
  
  });
  