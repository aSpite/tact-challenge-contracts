import "@stdlib/deploy";

/*
  TASK 2 - Proxy
  Create a contract that forwards all received TONs
  to the admin contract (whose address is set in init_store).
  Message from this proxy contract to the admin contract should contain:
    - Address of user who sent original message (should be stored in the outcoming body's data/bits)
    - Original message that proxy smart contract received from user (should be stored in the outcoming body's first ref)
  Also, if admin contract decides to reject message (if it sends to the proxy "Refund" message with opcode=0x44),
  proxy contract needs to forward all TONs (attached to Refund message) back to the user.
  User address will be provided in Refund message body as "sender".
  In refund transaction, it is important to have a check that the refund message came from the admin address
*/

message(0x44) Bounced {
  queryId: Int as uint64;
  sender: Address;
}

contract Task2 with Deployable {
  admin: Int as uint256;

  init(admin: Address) {
    let a: Slice = admin.asSlice();
    a.skipBits(11);
    self.admin = a.preloadUint(256);
  }

  receive(msg: Bounced) {
    let addr: Slice = sender().asSlice();
    addr.skipBits(11);
    nativeThrowUnless(55, addr.preloadUint(256) == self.admin);
    nativeSendMessage(beginCell()
        .storeUint(0x10, 6)
        .storeSlice(msg.sender.asSlice())
        .storeUint(0, 111)
        .endCell(), 64);
    commit();
    throw(0);
  }

  receive(msg: Slice) {
    nativeSendMessage(beginCell()
        .storeUint(33792, 17)
        .storeUint(self.admin, 256)
        .storeUint(0, 111)
        .storeSlice(sender().asSlice())
        .storeRef(msg.asCell())
        .endCell(), 64);
    commit();
    throw(0);
  }
}
