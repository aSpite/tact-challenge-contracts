# Tact Challenge

There are my solutions for the [Tact Challenge](https://github.com/ton-community/tact-challenge).

## Hacks

Some hacks are used in the solutions. 

### Major hacks

- Storing the address as uint256 since Tact uses tact_verify_address every time an address is received, which consumes a lot of gas.

- Using commit (c4 and c5 saving) and throw(0) to abruptly exit the function when you only need to send a message without changing storage.

- nativeSendMessage, nativeRandomizeLt, nativeRandomInterval, nativeReserve.

- Combining many numbers (storeUint + storeCoins) into one. For example, storing "NFT is still locked" as a number.

- The correct order of data storage in the storage. It is important to understand how Tact works with storage. It depends on which value will be the first on the stack. With the correct sequence of values used and their location in the storage, a significant improvement in gas can be achieved.

- Storing a numeric value in seed in tasks where possible and reducing its bitness.

### Minor hacks

- Changing the opcodes of messages, where possible, to values less than 10 for PUSHING to spend 18 units of gas instead of 26.

- Reducing bitness in structures where possible due to inaccurate tests. 

- Ignoring certain conditions due to inaccurate tests. For example, nativeThrowUnless, with a small value to save gas instead of require, gives a value greater than 63. In this case, using the opcode is more expensive.

- Small optimizations. For example, using preloadUint instead of loadUint if the slice is no longer needed, using numbers directly in the code instead of storing in a variable, incomplete clearing of the storage (in task 4 with seed = 0 means that there is no owner and nft, so they can not be reset).

## Evaluation Results 🏆

| Task ID | Compiled | Tests Passed | Points | Gas Used | Compilation Error |
|---------|:--------:|:------------:|:------:|:----------------------:|:-----------------:|
| 1 | ✅ | ✅ 8/8 | 5.3702 | 72,013,280 |  |
| 2 | ✅ | ✅ 6/6 | 5.3764 | 1,031,567,332 |  |
| 3 | ✅ | ✅ 10/10 | 5.4740 | 293,135,719 |  |
| 4 | ✅ | ✅ 5/5 | 5.4738 | 81,308,741 |  |
| 5 | ✅ | ✅ 11/11 | 5.4481 | 11,319,182,738 |  |

## Some moment related to the tests

- In task 3, it was possible not to process the condition under which division by 0 could occur. At the same time, when exchanging B -> A, it was possible not to use decimals in calculations.

- In task 5, it was possible to fake a random and save a lot of gas.

However, these optimizations were not included in the solutions for reasons of honesty.