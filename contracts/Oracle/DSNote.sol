pragma solidity ^0.5.0;


contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 bar,
        uint wad,
        bytes fax
    );

    modifier note {
        bytes32 foo;
        bytes32 bar;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(
            msg.sig,
            msg.sender,
            foo,
            bar,
            msg.value,
            msg.data
        );

        _;
    }
}
