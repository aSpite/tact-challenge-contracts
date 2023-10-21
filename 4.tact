import "@stdlib/deploy";

/*
  TASK 4 - NFT locker
  Implement a smart contract that will lock NFT for a period of time specified by the owner.
  Smart conrtact should contain logic to process following messages and getters:

  Messages:
  * OwnershipAssigned
   - Recives nft + time (in a forwardPayload message as uint32) for which this nft will be locked + address of the sender of the nft (prevOwner).
   - If the smart contract already holds an nft then return the incoming nft back to the sender
  * NftWithdrawal
   - Request withdrawal of the locked nft
   - If sender is not the owner (that came from OwnershipAssigned as prevOwner address) then throw "Invalid sender"
   - If time has not passed then send message back to the sender with the comment "NFT is still locked" according to the TON's "message with text comment" standard
   - Otherwise (all good) send the locked nft back to the owner with all the remaining TON balance
   Note that the order of checks is important
   (in case: "sender is not the owner" and "time has not passed" at the same time, "Invalid sender" error takes priority)

  Getters:
  * time
   - get how much lock time is left
  * nft
   - get the address of the locked nft
  * owner
   - get the owner of the locked nft (that came from OwnershipAssigned as prevOwner)
*/

message(0x1) OwnershipAssigned {
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

message(0x2) NftWithdrawal {
  queryId: Int as uint64;
  nftAddress: Address;
}

contract Task4 with Deployable {
  owner: Int as uint256 = 0;
  seed: Int as uint32 = 0;
  nft: Int as uint256 = 0;

  init(seed: Int) {
  }

  receive(msg: OwnershipAssigned) {
    if(self.owner == 0) {
        let addr: Slice = msg.prevOwner.asSlice();
        addr.skipBits(11);
        self.owner = addr.preloadUint(256);
        self.seed = msg.forwardPayload.preloadUint(32) + now();
        addr = sender().asSlice();
        addr.skipBits(11);
        self.nft = addr.preloadUint(256);
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

  receive(msg: NftWithdrawal) {
    let addr: Slice = sender().asSlice();
    addr.skipBits(11);
    nativeThrowUnless(49, addr.preloadUint(256) == self.owner);
    if(self.seed > now()) {
      nativeSendMessage(beginCell()
        .storeUint(33792, 17)
        .storeUint(self.owner, 256)
        .storeUint(0, 111)
        .storeUint(1745584612302255264536575227224246465199826276, 184)
        .endCell(), 64);
      commit();
      throw(0);
    }

    self.seed = 0;
    nativeSendMessage(beginCell()
      .storeUint(0x10, 6)
      .storeSlice(msg.nftAddress.asSlice())
      .storeUint(1607220500, 143)
      .storeUint(msg.queryId, 64)
      .storeSlice(sender().asSlice())
      .storeSlice(sender().asSlice())
      .storeUint(0, 5)
      .endCell(), 128);
  }

  get fun time(): Int {
    let time: Int = self.seed - now();
    if(time < 0) {
      return 0;
    }
    return time;
  }

  get fun nft(): Address? {
    if(self.seed == 0) {
      return null;
    }
    let addr: Slice = beginCell().storeUint(1024, 11).storeUint(self.nft, 256).endCell().beginParse();
    return addr.loadAddress();
  }

  get fun owner(): Address? {
    if(self.seed == 0) {
       return null;
    }
    let addr: Slice = beginCell().storeUint(1024, 11).storeUint(self.owner, 256).endCell().beginParse();
    return addr.loadAddress();
  }
}