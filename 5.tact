import "@stdlib/deploy";

/*
  TASK 5 - NFT random swap 
  The smart contract contains a bunch of different NFTs.
  A user brings his NFT (sends it to the smart contract), with 2.1 TON (2 for admin's profit, 0.1 for gas) in attachment (as fee for swap).
  The smart contract randomly chooses some NFT from the available NFTs (including the newly incoming one) and gives it to the user in exchange for the brought NFT (but occasionally just returns user's NFT in some cases).
  Admin can deposit NFTs without swap logic. Any NFT received from the admin is considered deposited. Admin can't swap.
  Admin can withdraw all NFTs at once, and also all TONs collected from users as fees.
  Implement getter that will return NFT addresses held by the smart contract.
  Implement getter that will return the amount of admin`s profit collected.

  In details, the smart contract (later: SC) should have this logic:
  Messages
  * AdminWithdrawalProfit 
   - SC should check that sender is the admin / otherwise throw "Insufficient privelegies"
   - SC should send all collected fees to admin except 0.1 TON (use AdminFetchProfit message as body)
     In other words: after each such operation, the contract's balance should be equal to 0.1 TON (which are reserved for storage) and the rest should be sent to the admin
  * AdminWithdrawalAllNFTs
   - SC should check that incoming tx TON value is enough for NFT withdrawal. Specifically, at least: (1 + totalNftsHeld * 0.08) TONs. Otherwise throw "Insufficent funds"
   - SC should check that sender is the admin, throw "Invalid sender" otherwise
   - If all checks pass, SC should send NFTs one by one to the admin 
   - SC should be able to withdraw all NFTs by a single message from admin
  * OwnershipAssigned 
   - if prevOwner is the owner's (admin) address, then add NFT to the collection
   - if value of TON attached is less then 2.1 TON then stop execution and return NFT back,
     but only in case that TON attached is enough to process refund without losing TONs on the SC's balance
   - randomly select NFT to send from all the NFTs that smart contract has
   - send the selected NFT to the sender with all remaining balance (except for admin profit = fees collected from this and other swaps)
     In other words: the contract's balance should increase by exactly 2 TON, some incoming TONs will be consumed for gas and the remainings of the incoming TONs should be refunded to the sender
  
  Getters
  * profit
   - returns how much collected fees is available to withdraw for the admin (all fees minus 0.1 TON)
  * nfts
   - returns dict of held NFTs with NFT indexes (sequential numbers from 0, 1, 2 ... and up to 'totalNftsHeld-1') as keys and NFT address as values 
     the order of NFTs in this dictionary doesn't matter
*/

message AdminWithdrawalProfit {
  queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
  queryId: Int as uint64;
}

message AdminFetchProfit {
  queryId: Int as uint64;
}

message ContinueWithdrawal {
  body: Cell;
}

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}

message(0x5fcc3d14) Transfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

contract Task5 with Deployable {
  owner: Int as uint256;
  seed: Int as uint16;
  nfts: map<Int as uint16, Address>;

  init(seed: Int, owner: Address) {
    let addr: Slice = owner.asSlice();
    addr.skipBits(11);
    self.owner = addr.preloadUint(256);
    self.seed = 0; // needed to deploy multiple smart contracts copies from one admin address
  }

  receive(msg: OwnershipAssigned) {
    let addr: Slice = msg.prevOwner.asSlice();
    addr.skipBits(11);
    if(addr.preloadUint(256) == self.owner) {
      self.nfts.set(self.seed, sender());
      self.seed = self.seed + 1;
      return;
    }
    if(context().value >= 2100000000) {
      nativeReserve(2000000000, 4);
      nativeRandomizeLt();
      let x: Int = nativeRandomInterval(self.seed + 1);
      if(x == self.seed + 1) {
        nativeSendMessage(beginCell()
          .storeUint(0x10, 6)
          .storeSlice(sender().asSlice())
          .storeUint(1607220500, 143)
          .storeUint(msg.queryId, 64)
          .storeSlice(msg.prevOwner.asSlice())
          .storeSlice(msg.prevOwner.asSlice())
          .storeUint(0, 5)
          .endCell(), 128);
        commit();
        throw(0);
      }
      let nft: Address = self.nfts.get(x)!!;
      nativeSendMessage(beginCell()
          .storeUint(0x10, 6)
          .storeSlice(nft.asSlice())
          .storeUint(1607220500, 143)
          .storeUint(msg.queryId, 64)
          .storeSlice(msg.prevOwner.asSlice())
          .storeSlice(msg.prevOwner.asSlice())
          .storeUint(0, 5)
          .endCell(), 128);
      self.nfts.set(x, sender());
      return;
    }
      nativeSendMessage(beginCell()
        .storeUint(0x10, 6)
        .storeSlice(sender().asSlice())
        .storeUint(1607220500, 143)
        .storeUint(msg.queryId, 64)
        .storeSlice(msg.prevOwner.asSlice())
        .storeSlice(msg.prevOwner.asSlice())
        .storeUint(0, 5)
        .endCell(), 64);
      commit();
      throw(0);
  }

  receive(msg: AdminWithdrawalProfit) {
    let addr: Slice = sender().asSlice();
    addr.skipBits(11);
    let bits: Int = addr.preloadUint(256);
    nativeThrowUnless(41, bits == self.owner);
    nativeReserve(100000000, 0);
    nativeSendMessage(beginCell()
        .storeUint(33792, 17)
        .storeUint(bits, 256)
        .storeUint(4255419257, 143)
        .storeUint(msg.queryId, 64)
        .endCell(), 128);
    commit();
    throw(0);
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    nativeThrowUnless(42, (self.seed * 80000000) <= context().value);
    let addr: Slice = sender().asSlice();
    addr.skipBits(11);
    nativeThrowUnless(43, addr.preloadUint(256) == self.owner);
    let body: Cell = beginCell()
          .storeUint(1607220500, 32)
          .storeUint(msg.queryId, 64)
          .storeUint(1024, 11)
          .storeUint(self.owner, 256)
          .storeUint(1024, 11)
          .storeUint(self.owner, 256)
          .storeUint(0, 5)
          .endCell();
    repeat(min(250, self.seed)) {
      self.seed = self.seed - 1;
      nativeSendMessage(beginCell()
        .storeUint(0x10, 6)
        .storeSlice((self.nfts.get(self.seed)!!).asSlice())
        .storeUint(2797328706426080694495459464698332868247553, 143)
        .storeRef(body)
        .endCell(), 0);
    }
    if(self.seed > 0) {
      nativeSendMessage(beginCell()
        .storeUint(0x10, 6)
        .storeSlice(myAddress().asSlice())
        .storeUint(0, 111)
        .storeSlice(body.beginParse())
        .endCell(), 128);
    }
  }

  receive(msg: Slice) {
    nativeThrowUnless(44, myAddress() == sender());
    let body: Cell = msg.asCell();
    repeat(min(100, self.seed)) {
      self.seed = self.seed - 1;
      nativeSendMessage(beginCell()
        .storeUint(0x10, 6)
        .storeSlice((self.nfts.get(self.seed)!!).asSlice())
        .storeUint(2797328706426080694495459464698332868247553, 143)
        .storeRef(body)
        .endCell(), 0);
    }

    if(self.seed > 0) {
      nativeSendMessage(beginCell()
        .storeUint(0x10, 6)
        .storeSlice(myAddress().asSlice())
        .storeUint(2797328706426080694495459464698332868247552, 143)
        .storeSlice(msg)
        .endCell(), 128);
    } else {
      self.nfts = emptyMap();
    }
  }

  get fun profit(): Int {
    return myBalance() - 100000000;
  }

  get fun nfts(): map<Int as uint16, Address> {
    return self.nfts;
  }
}