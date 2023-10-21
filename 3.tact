import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.

  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Token prices must be decimalized for accuracy, so it is the prices that must be adjusted to decimal 1e9.
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  Example formula for amountOfAJettonToSend in B->A swap will be
  (amountOfJettonAOnContract * decimal / amountOfJettonBOnContract) * amountOfTokenBToSwap / decimal

  If smart contract pool doesn't have enough jettons to trade,
  then it should send incoming jettons back to the user. For a clearer explanation,
  let's look at the example we described above (smart contract has 10 of jetton A and 2 of jetton B).
  If user will send 3 jettons B, smart contract should reject the message (because contract does not have 3 * 5 = 15 jettons A)
  and send 3 jettons B back to the user.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).

  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

contract Task3 with Deployable {
  owner: Int as uint256;
  jAddressA: Int as uint256;
  jAddressB: Int as uint256;
  a: Int;
  b: Int;

  init(admin: Address, newJAddressA: Address, newJAddressB: Address) {
    let addr: Slice = newJAddressA.asSlice();
    addr.skipBits(11);
    self.jAddressA = addr.preloadUint(256);
    addr = newJAddressB.asSlice();
    addr.skipBits(11);
    self.jAddressB = addr.preloadUint(256);
    addr = admin.asSlice();
    addr.skipBits(11);
    self.owner = addr.preloadUint(256);
    self.a = 0;
    self.b = 0;
  }

  receive(msg: TokenNotification) {
    let addr: Slice = sender().asSlice();
    addr.skipBits(11);
    let bits: Int = addr.preloadUint(256);
    nativeThrowUnless(41, bits == self.jAddressA || bits == self.jAddressB);
    addr = msg.from.asSlice();
    addr.skipBits(11);
    let bits2: Int = addr.preloadUint(256);
    if(bits2 == self.owner) {
      if(bits == self.jAddressA) {
        self.a = self.a + msg.amount;
        return;
      }
      self.b = self.b + msg.amount;
      return;
    }
    if(bits == self.jAddressB) {
      if(self.a == 0) {
        nativeSendMessage(beginCell()
        .storeUint(33792, 17)
        .storeUint(bits, 256)
        .storeUint(1, 111)
        .storeRef(beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(msg.queryId, 64)
            .storeCoins(msg.amount)
            .storeSlice(msg.from.asSlice())
            .storeSlice(myAddress().asSlice())
            .storeUint(60331648, 29)
            .endCell())
        .endCell(), 64);
        commit();
        throw(0);
      }
      let tokensToSend: Int = self.a * 1000000000 / self.b * msg.amount / 1000000000;
      if(tokensToSend > self.a) {
        nativeSendMessage(beginCell()
        .storeUint(33792, 17)
        .storeUint(bits, 256)
        .storeUint(1, 111)
        .storeRef(beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(msg.queryId, 64)
            .storeCoins(msg.amount)
            .storeSlice(msg.from.asSlice())
            .storeSlice(myAddress().asSlice())
            .storeUint(60331648, 29)
            .endCell())
        .endCell(), 64);
        commit();
        throw(0);
      } else {
        nativeSendMessage(beginCell()
        .storeUint(33792, 17)
        .storeUint(self.jAddressA, 256)
        .storeUint(1, 111)
        .storeRef(beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(msg.queryId, 64)
            .storeCoins(tokensToSend)
            .storeSlice(msg.from.asSlice())
            .storeSlice(myAddress().asSlice())
            .storeUint(60331648, 29)
            .endCell())
        .endCell(), 64);
        self.b = self.b + msg.amount;
        self.a = self.a - tokensToSend;
      }

    } else {
      if(self.b == 0) {
        nativeSendMessage(beginCell()
        .storeUint(33792, 17)
        .storeUint(bits, 256)
        .storeUint(1, 111)
        .storeRef(beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(msg.queryId, 64)
            .storeCoins(msg.amount)
            .storeSlice(msg.from.asSlice())
            .storeSlice(myAddress().asSlice())
            .storeUint(60331648, 29)
            .endCell())
        .endCell(), 64);
        commit();
        throw(0);
      }
      let tokensToSend: Int = self.b * 1000000000 / self.a * msg.amount / 1000000000;
      if(tokensToSend > self.b) {
        nativeSendMessage(beginCell()
        .storeUint(33792, 17)
        .storeUint(bits, 256)
        .storeUint(1, 111)
        .storeRef(beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(msg.queryId, 64)
            .storeCoins(msg.amount)
            .storeSlice(msg.from.asSlice())
            .storeSlice(myAddress().asSlice())
            .storeUint(60331648, 29)
            .endCell())
        .endCell(), 64);
        commit();
        throw(0);
      } else {
        nativeSendMessage(beginCell()
        .storeUint(33792, 17)
        .storeUint(self.jAddressB, 256)
        .storeUint(1, 111)
        .storeRef(beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(msg.queryId, 64)
            .storeCoins(tokensToSend)
            .storeSlice(msg.from.asSlice())
            .storeSlice(myAddress().asSlice())
            .storeUint(60331648, 29)
            .endCell())
        .endCell(), 64);
        self.a = self.a + msg.amount;
        self.b = self.b - tokensToSend;
      }
    }
  }

  get fun price(token: Address): Int {
    let addr: Slice = token.asSlice();
    addr.skipBits(11);
    if(addr.preloadUint(256) == self.jAddressA) {
      if(self.a == 0) {
        return 0;
      }
      return self.b * 1000000000 / self.a;
    } else {
        if(self.b == 0) {
            return 0;
        }
      return self.a * 1000000000 / self.b;
    }
  }

  get fun balance(token: Address): Int {
    let addr: Slice = token.asSlice();
    addr.skipBits(11);
    if(addr.preloadUint(256) == self.jAddressA) {
      return self.a;
    } else {
      return self.b;
    }
  }
}