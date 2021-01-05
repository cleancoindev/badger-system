// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "deps/@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";

import "interfaces/digg/IDigg.sol";
/**
    ===== Digg Rewards Faucet =====
    Allow a specified recipient to withdraw DIGG rewards at a rate specified configurable by the admin.
    Define or modify the rate of distribution as: X DIGG shares over Y time
    Adequate DIGG shares must be provided for the distribution

 */
contract DiggRewardsFaucet is Initializable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable public rewardsToken;
    IDigg public digg;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    address public recipient;

    function initialize(address _admin, address _digg) public initializer whenNotPaused {
        __AccessControl_init();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        rewardsToken = IERC20Upgradeable(_digg);
        digg = IDigg(_digg);

        rewardsDuration = 7 days;
    }

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, periodFinish);
    }

    function earned() public view returns (uint256) {
        uint256 timeSinceLastUpdate = lastTimeRewardApplicable().sub(lastUpdateTime);
        return timeSinceLastUpdate.mul(rewardRate);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getReward() public nonReentrant whenNotPaused {
        _onlyRecipient();
        uint256 reward = earned();
        if (reward > 0) {
            digg.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 startTimestamp, uint256 _rewardsDuration, uint256 reward) external whenNotPaused {
        _onlyAdmin();
        rewardsDuration = _rewardsDuration;
        rewardRate = reward.div(rewardsDuration);

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = digg.balanceOf(address(this));
        emit NotifyRewardsAmount(rewardRate, startTimestamp, balance, reward, rewardsDuration);
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = startTimestamp;
        periodFinish = startTimestamp.add(rewardsDuration);
        emit RewardAdded(reward);
        emit RewardsDurationUpdated(rewardsDuration);

    }

    function initializeRecipient(address _recipient) external whenNotPaused {
        _onlyAdmin();
        require(recipient == address(0), "Recipient already set");
        recipient = _recipient;
    }

    function pause() external {
        _onlyAdmin();
        _pause();
    }

    function unpause() external {
        _onlyAdmin();
        _unpause();
    }

    /* ========== MODIFIERS ========== */
    function _onlyAdmin() internal {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "onlyAdmin");
    }

    function _onlyRecipient() internal {
        require(msg.sender == recipient, "onlyRecipient");
    }

    /* ========== EVENTS ========== */
    event NotifyRewardsAmount(uint256 rate, uint256 start, uint256 balance, uint256 reward, uint256 duration);

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
