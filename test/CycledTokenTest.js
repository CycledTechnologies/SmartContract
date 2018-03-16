require('./helpers/spec_helper.js');
var CycledToken = artifacts.require("./CycledToken.sol");

contract('CycledToken', function ([owner, acc]) {
  let token;
  let ownerTokenBalance;
  let recyclingIncentivesWallet = "0x41407962c3a18edbcaa98a5cc071433111b66ccc";
  let cycledTechnologiesWallet = "0xfb51ebe7b377f11d5d38112979ed7ffd27cc26fc";
  let foundersWallet = "0xa9207175a2a8425db5c496e120b2ec28ba0a39e4";
  let bountyWallet = "0x33ec7ecf1a5aaebdf97a8603dcf3f04127d21035";

  beforeEach(async function () {
    // address _recyclingIncentivesWallet, address _cycledTechnologiesWallet, address _foundersWallet, address _bountyWallet
    token = await CycledToken.new(recyclingIncentivesWallet, cycledTechnologiesWallet, foundersWallet, 
        bountyWallet, {from: owner});
  });

  describe("Token Distribution", function () {

    it('Sale Token to Owner distributed', async function () {
        let expectedownerBalance = new BigNumber(web3.toWei('500000000', 'ether'));
        const ownerBalance = await token.balanceOf(owner);
        expect(ownerBalance).to.be.bignumber.equal(expectedownerBalance);
    });
   
    it('Recycling Incentives Wallet distributed', async function () {
        let expectedrecyclingIncentivesWalletBalance = new BigNumber(web3.toWei('200000000', 'ether'));
        const recyclingIncentivesWalletBalance = await token.balanceOf(recyclingIncentivesWallet);
        expect(recyclingIncentivesWalletBalance).to.be.bignumber.equal(expectedrecyclingIncentivesWalletBalance);
    });

    it('Cycled Technologies Wallet distributed', async function () {
        let expectedcycledTechnologiesWalletBalance = new BigNumber(web3.toWei('150000000', 'ether'));
        const cycledTechnologiesWalletBalance = await token.balanceOf(cycledTechnologiesWallet);
        expect(cycledTechnologiesWalletBalance).to.be.bignumber.equal(expectedcycledTechnologiesWalletBalance);
    });

    it('Founders Wallet distributed', async function () {
        let expectedfoundersWalletBalance = new BigNumber(web3.toWei('100000000', 'ether'));
        const foundersWalletBalance = await token.balanceOf(foundersWallet);
        expect(foundersWalletBalance).to.be.bignumber.equal(expectedfoundersWalletBalance);
    });

    it('Bounty Wallet distributed', async function () {
        let expectedbountyWalletBalance = new BigNumber(web3.toWei('50000000', 'ether'));
        const bountyWalletBalance = await token.balanceOf(bountyWallet);
        expect(bountyWalletBalance).to.be.bignumber.equal(expectedbountyWalletBalance);
    });

  });

  describe("burnable", function () {
    let expectedTokenSupply;
    let burnAmount = new BigNumber(web3.toWei('5000000', 'ether'));

    beforeEach(async function () {
        let totalSupply = await token.totalSupply();
        ownerTokenBalance = await token.balanceOf(owner);
        expectedTokenSupply = totalSupply.sub(burnAmount);
    });

    it('owner should be able to burn tokens', async function () {
      const {logs} = await token.burn(burnAmount, {from: owner});

      const expectedOwnerBalance = ownerTokenBalance.sub(burnAmount);
      const balance = await token.balanceOf(owner);
      expect(balance).to.be.bignumber.equal(expectedOwnerBalance);

      const totalSupply = await token.totalSupply();
      expect(totalSupply).to.be.bignumber.equal(expectedTokenSupply);

      const event = logs.find(e => e.event === 'Burn');
      expect(event).to.exist;
    });

    it('cannot burn more tokens than your balance', async function () {
      let tooMuchBurn = ownerTokenBalance.add(1);
      try {
        await token.burn(tooMuchBurn, {from: owner})
        assert.fail();
      } catch (error) {
        assertRevert(error);
      }
    });
  });

// /* ------------------------------------------------------------------------------------------------------------------------------------- */

//   describe("pausable", function () {
//     it('should return paused false after construction', async function () {
//       let paused = await token.paused();
//       expect(paused).to.equal(false);
//     });

//     it('should return paused true after pause', async function () {
//       await token.pause();
//       let paused = await token.paused();

//       expect(paused).to.equal(true);
//     });

//     it('should return paused false after pause and unpause', async function () {
//       await token.pause();
//       await token.unpause();
//       let paused = await token.paused();

//       expect(paused).to.equal(false);
//     });

//     it('should be able to transfer if transfers are unpaused', async function () {
//       await token.approve(owner, amount);
//       let balance0 = await token.balanceOf(owner);
//       await token.transferFrom(owner, acc, amount);
//       let balance0AfterTransfer = await token.balanceOf(owner);
//       expect(balance0AfterTransfer).to.bignumber.equal(balance0.sub(amount));

//       let balance1 = await token.balanceOf(acc);
//       expect(balance1).to.bignumber.equal(amount);
//     });

//     it('should be able to transfer after transfers are paused and unpaused', async function () {
//       await token.pause();
//       await token.unpause();

//       let balance0 = await token.balanceOf(owner);

//       await token.transfer(acc, amount);

//       let balance0AfterTransfer = await token.balanceOf(owner);

//       expect(balance0AfterTransfer).to.bignumber.equal(balance0.sub(amount));

//       let balance1 = await token.balanceOf(acc);
//       expect(balance1).to.bignumber.equal(amount);
//     });

//     it('should throw an error trying to transfer while transactions are paused', async function () {
//       await token.pause();
//       try {
//         await token.transfer(acc, amount);
//         assert.fail('should have thrown before');
//       } catch (error) {
//         assertRevert(error);
//       }
//     });

//     it('should throw an error trying to transfer from another account while transactions are paused', async function () {
//       await token.pause();
//       try {
//         await token.transferFrom(owner, acc, amount);
//         assert.fail('should have thrown before');
//       } catch (error) {
//         assertRevert(error);
//       }
//     });
//   });

});
