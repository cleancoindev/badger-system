//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "deps/@openzeppelin/contracts-upgradeable/token/ERC20/TokenTimelockUpgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract SimpleTimelock is TokenTimelockUpgradeable {
    using SafeMathUpgradeable for uint256;

    function initialize(
        IERC20Upgradeable token,
        address beneficiary,
        uint256 releaseTime
    ) public initializer {
        __TokenTimelock_init(token, beneficiary, releaseTime);
    }

    function release() public override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");
        require(msg.sender == 0xB65cef03b9B89f99517643226d76e286ee999e77);

        address recipient = 0x8dE82C4C968663a0284b01069DDE6EF231D0Ef9B;

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(recipient, amount);

        require(token().balanceOf(beneficiary()) >= 7350000 ether);
    }
}
