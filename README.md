# Not So Static

Transient `uint256` that can be mutated **within `STATICCALL`s**. This is unlike `SSTORE` & `TSTORE`
which will cause a revert when used in a `STATICCALL` context.

## Usage

```solidity
import {suint256} from "not-so-static/staticstate.sol";

contract MyContract {
    suint256 internal x;

    function writeX(uint256 newX) public view {
        x.set(newX);
    }

    function getX() public view returns (uint256) {
        return x.get();
    }
}

```

## Gas Cost

|Operation|Est. Cost|
|---------|---------|
|`.get`| ~600k |
|`.set`| ~250k |

## How?

While side effects are generally disallowed in `STATICCALL` contexts gas observability & "read-only"
operations are not.

Operations like `SLOAD` have observable side-effects as they may "warm" slots, changing the cost.
Conceptually this lets us create a simple write-once, read-once 1-bit store:

### write-once, read-once 1-bit store

To store a `0` you simply do nothing (default value), to store a `1` you `SLOAD` a given slot.

To read the value you `SLOAD` the same slot measuring the gas used. Gas use of less than 2,100 gas
indicates a arm read meaning the value is `1`, >2,100 indicates a cold read and therefore `0`.

Note that because _writing_ relies on `SLOAD`-ing, _reading a bit_ is a one-time, destructive operation,
effectively overwriting the previous value with `1`.

### A fully mutable store.

To create a repeatedly readable & writable value from this primitive we need to recognize a key
fact: destructive reads are still useful because we can just re-write the read value to a new
location.

This creates a second problem however, how do we keep track of the location if it changes with every
read & write?

We can create a simple incrementing counter that doesn't have to change its location:

```
Counter:
    slot 0:   1-bit
    slot 1:   1-bit
    slot 2:   1-bit
    slot 3:   1-bit
    ...

Interpretation
    0000... => 0
    1000... => 1
    1100... => 2
    1110... => 3
```

We read the counter by walking through the slots until we read a non-zero value, this inherently
increases the counter by one every-time we read but it gives what we need: a mutable, fixed location
value.

Combining the two we now have an arbitrary mutable & readable value. Our counter stores the index
where the current value lives:
- to write a value:
    1. We read (and therefore increment) the counter to get the location where we can store a value
    2. We write the bits of our value in sequence starting from the given slot.
- to read a value:
    1. We read (and therefore increment) the counter to get the slot
    2. We destructively read the from the current slot saving the value
    3. We re-write the retrieved value in `slot+1`
