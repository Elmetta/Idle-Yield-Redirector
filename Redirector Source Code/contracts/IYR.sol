pragma solidity ^0.6.12;

import './BEP20Token.sol';

// interface to Syrup Pools

interface InterfaceSyrupPool {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function pendingReward(address _user) external view returns (uint256);
    //function initialize(IBEP20 _stakedToken, IBEP20 _rewardToken, uint256 _rewardPerBlock, uint256 _startBlock, uint256 _bonusEndBlock, uint256 _poolLimitPerUser, address _admin) external;
    //function emergencyWithdraw() external;
    //function emergencyRewardWithdraw(uint256 _amount) external;
    //function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external;
    //function stopReward() external;
    //function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external;
    //function updateRewardPerBlock(uint256 _rewardPerBlock) external;
    //function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external;
    //function _updatePool() internal;
    //function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256);
}


// interface to Beefy Vaults

interface InterfaceBeefy {
    function beefIn (uint256 tokenInAmount) external;
    function beefOut(uint256 tokenOutAmount) external;
}


// Idle Yield Redirector

contract Redirector {

    using SafeMath for uint256;

    uint shareTokenSupplyNew = 0;
    uint shareTokenSupplyOld = 0;

    uint256 rewardTokenSupply;
    uint stakedCakeAll;
    
    address cakeAddress = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address rewardTokenAddress = 0x8519EA49c997f50cefFa444d240fB655e89248Aa;
    address _rewardPoolAddress;
    address _beefyVaultAddress;
    address[] public stakers;

    IBEP20 cakeToken = IBEP20(cakeAddress);
    IBEP20 rewardToken = IBEP20(rewardTokenAddress);
    IBEP20 _shareToken;

    mapping(address => uint) public user_reward_earned;
    mapping(address => uint) public user_stakedcake;
    mapping (address => bool) public Wallets;


    constructor(address shareToken_, address drain_, address source_) public {
        _beefyVaultAddress = drain_;
        _rewardPoolAddress = source_;
        _shareToken = IBEP20(shareToken_);
    }

    function setWallet(address _wallet) public{
        Wallets[_wallet] = true;
    }

    function alreadyStaked(address _wallet) public returns (bool){
        return Wallets[_wallet];
    }


    modifier CakeApprovedTransferred (uint _amountCake){
        // transfers users principle to optimizer
        require(cakeToken.transferFrom(address(msg.sender), address(this), _amountCake), "Transfer CAKE from User failed");
        
        // gives allowance to yield source to take funds from optimizer
        require(cakeToken.approve(_rewardPoolAddress, _amountCake), "Approve CAKE for Syrup Pool failed");
        _;
    }


   function _updateRewards() internal {
        // used to find out how much of the newly share token belongs to whom
        uint to_split;
        
        shareTokenSupplyNew = _shareToken.balanceOf(address(this));
        to_split = shareTokenSupplyNew - shareTokenSupplyOld;
        shareTokenSupplyOld = shareTokenSupplyNew;

        // get amount of share token belonging to each user depending on yield (therefore on principle)
        for(uint i = 0; i < stakers.length; i++) {
            user_reward_earned[stakers[i]] += (to_split * (user_stakedcake[stakers[i]] * 1000 / stakedCakeAll) / 1000);
        }
    }

    
    function depositIntoOptimizer(uint _amountCake) external CakeApprovedTransferred(_amountCake){
        // deposit into Syrup Pool
        InterfaceSyrupPool(_rewardPoolAddress).deposit(_amountCake);
        
        if (stakedCakeAll > 0) {
            // stake earned rewards to Beefy Vault after approval
            rewardTokenSupply = rewardToken.balanceOf(address(this));
            require(rewardToken.approve(_beefyVaultAddress, rewardTokenSupply), "Approve CAKE for Beefy Vault failed");
            InterfaceBeefy(_beefyVaultAddress).beefIn(rewardTokenSupply);
            // update share tokens per user count
            _updateRewards();
        }
        
        stakedCakeAll += _amountCake;
        user_stakedcake[msg.sender] += _amountCake;

        if(!alreadyStaked(msg.sender)){
            setWallet(msg.sender);
            stakers.push(msg.sender);
        }
    }


    function withdrawFromOptimizer(uint _amount) public {
        require((user_stakedcake[msg.sender] - _amount) >= 0, "You can only withdraw as much CAKE as you have initially deposited");
        InterfaceSyrupPool(_rewardPoolAddress).withdraw(_amount);
        require(cakeToken.transfer(msg.sender, _amount), "Transfer RAMP to user failed");

        rewardTokenSupply = rewardToken.balanceOf(address(this));
        require(rewardToken.approve(_beefyVaultAddress, rewardTokenSupply), "Approve RAMP for Beefy Vault failed");
        InterfaceBeefy(_beefyVaultAddress).beefIn(rewardTokenSupply);
        _updateRewards();
        InterfaceBeefy(_beefyVaultAddress).beefOut(user_reward_earned[msg.sender]);
        
        rewardTokenSupply = rewardToken.balanceOf(address(this));
        require(rewardToken.transfer(msg.sender, rewardTokenSupply), "Transfer RAMP to user failed");

        shareTokenSupplyOld -= user_reward_earned[msg.sender];
        user_reward_earned[msg.sender] = 0;
        user_stakedcake[msg.sender] -= _amount;
        stakedCakeAll -= _amount;
    }

    // returns earned share tokens per user
     function getUserShare(address asd) external view returns (uint256) {
        return user_reward_earned[asd];
    }

    // returns staked CAKE per user
    function getUserStakedCake(address asd) external view returns (uint256) {
        return user_stakedcake[asd];
    }
}
