require('./helpers/spec_helper.js');

const Whitelist = artifacts.require("./Whitelist.sol");
const NULL_ADDRESS = "0x0";

contract('Whitelist', function([_, owner, wallet, purchaser]) {

  let whitelist;

  beforeEach(async function () {
    this.acc = "0x07434ecd895a7b3dac9c46c49e1c6e49f1638f74";
    this.acc2 = "0x8975163345444b18fc239e81ebc52ffc07596aaf";

    whitelist = await Whitelist.new();
  });


  it('is empty when first created', function () {
    expect(whitelist.isWhitelisted(this.acc)).to.eventually.equal(false);
  });


  it('adding an account makes it whitelisted', async function () {
    await whitelist.addInvestor(this.acc);
    expect(whitelist.isWhitelisted(this.acc)).to.eventually.equal(true);
  });


  it('adding a null address is not allowed', async function () {
    try {
      await whitelist.addInvestor(NULL_ADDRESS);
      assert.fail();
    } catch(error) {
      assertRevert(error);
    }
  });


  it('adding from a non curator address is not allowed', async function () {
    try {
      await whitelist.addInvestor(this.acc, { from: this.acc2 });
      assert.fail();
    } catch(error) {
      assertRevert(error);
    }
  });


  it('removing an account makes it not whitelisted anymore', async function () {
    await whitelist.addInvestor(this.acc);
    await whitelist.removeInvestor(this.acc);
    expect(whitelist.isWhitelisted(this.acc)).to.eventually.equal(false);
  });


  it('removing a null address is not allowed', async function () {
    try {
      await whitelist.removeInvestor(NULL_ADDRESS);
      assert.fail();
    } catch(error) {
      assertRevert(error);
    }
  });


  it('removing from a non curator address is not allowed', async function () {
    try {
      await whitelist.removeInvestor(this.acc, { from: this.acc2 });
      assert.fail();
    } catch(error) {
      assertRevert(error);
    }
  });


  it('non-curator can check whether an account is whitelisted', async function () {
    try {
      await whitelist.isWhitelisted(this.acc, { from: this.acc2 });
    } catch(error) {
      assert.fail();
    }
  });

});
