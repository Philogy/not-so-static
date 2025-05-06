// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct suint256 {
    uint256 __placeholder;
}

using suint256Lib for suint256 global;

/// @author philogy <https://github.com/philogy>
library suint256Lib {
    function get(suint256 storage self) internal view returns (uint256 value) {
        uint256 base_slot = _get_base_slot(self);
        value = _read_destructive(_hash(base_slot));
        _write(_hash(base_slot + 1), value);
    }

    function set(suint256 storage self, uint256 value) internal view {
        uint256 base_slot = _get_base_slot(self);
        _write(_hash(base_slot + 1), value);
    }

    function _get_base_slot(suint256 storage self) internal view returns (uint256 base_slot) {
        assembly {
            base_slot := self.slot
        }
        base_slot = _hash(base_slot);
        unchecked {
            while (_set_and_read_prev(base_slot)) base_slot++;
        }
    }

    function _read_destructive(uint256 value_slot) private view returns (uint256 value) {
        unchecked {
            for (uint256 i = 0; i < 256; i++) {
                if (_set_and_read_prev(value_slot + i)) value += 1 << i;
            }
        }
    }

    function _write(uint256 value_slot, uint256 value) private view {
        unchecked {
            uint256 i = 0;
            while (value != 0) {
                if (value & 1 == 1) _set_and_read_prev(value_slot + i);
                value >>= 1;
                i++;
            }
        }
    }

    function _set_and_read_prev(uint256 slot) private view returns (bool was_on) {
        assembly {
            let gas_before := gas()
            if sload(slot) { revert(0, 0) }
            was_on := lt(sub(gas_before, gas()), 2100)
        }
    }

    function _hash(uint256 slot) private pure returns (uint256 hashed) {
        assembly ("memory-safe") {
            mstore(0x00, slot)
            hashed := keccak256(0x00, 0x20)
        }
    }
}
