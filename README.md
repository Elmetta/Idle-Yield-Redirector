This document contains all information needed for manual testing of the Idle Yield Redirector code.
To create a local BSC mainnet fork, use:

ganache-cli --fork https://speedy-nodes-nyc.moralis.io/23c877ba1c636019bb26c90a/bsc/mainnet/archive --unlock 0x7C8DA84c4a4b4ba9BDad65332C6Fd46BBB04b884 --unlock 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82 --unlock 0xD6216fC19DB775Df9774a6E33526131dA7D19a2c --unlock 0xF977814e90dA44bFA03b6295A0616a897441aceC --networkId 56


Afterwards compile the contracts with: 
truffle migrate --reset --network bscForkedMainnet
and use the truffle console for manual testing:
truffle console --network bscForkedMainnet

We used the ramp token arbitraily as our REWARD token. Note that we needed to unlock specific user accounts that hold funds from the mainnet. If the balance on the mainnet changes, the balance on the forked mainnet changes aswell and the given accounts in this README need to be replaced by others.

--------------------------Test Commands Syrup Pool--------------------------


1. define interactable user addresses (unlocked by ganache) to access funds

mone = '0x7C8DA84c4a4b4ba9BDad65332C6Fd46BBB04b884'
rampWhale = '0xF977814e90dA44bFA03b6295A0616a897441aceC'
cakeWhale = '0xD6216fC19DB775Df9774a6E33526131dA7D19a2c'

2. define interactable tokens
cake = await IBEP20.at('0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82')
ramp = await IBEP20.at('0x8519EA49c997f50cefFa444d240fB655e89248Aa')



3. deploy IYR & Syrup Pool
we = await Aggregator.deployed()
ramppool = await SmartChefInitializable.deployed()




4. Show reward balance of optimizer and user before deposit and withdraw
bal1 = await ramp.balanceOf(we.address)
bal1.toString()
bal2 = await ramp.balanceOf(cakeWhale)
bal2.toString()



5. Initialize Syrup Pool

Use the function initialize with following parameter:
Schema:
 function initialize(
        IBEP20 _stakedToken,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        address _admin
    )
Command:
await ramppool.initialize('0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82', '0x8519EA49c997f50cefFa444d240fB655e89248Aa', 1000, 13934970, 16592383, 5000000000, accounts[0])

6. Transfer rewards to the Syrup Pool
await ramp.transfer(ramppool.address, 100000000, {from: rampWhale})
7. Give needed approvals
await cake.approve(we.address, 10000, {from: mone})
await cake.approve(we.address, 10000, {from: cakeWhale})

8. Can user deposit into and withdraw from Syrup Pool?

await we.withdrawPool(5,ramppool.address, {from:cakeWhale})
await we.withdrawPool(5,ramppool.address, {from:mone})

9. Can user deposit into and withdraw from IYR?

await we.depositIntoOptimizer(5000, {from:cakeWhale})
await we.depositIntoOptimizer(2500, {from:mone})
await we.withdrawFromOptimizer(5000, {from:cakeWhale})

10.  Show reward balance of optimizer and user after deposit and withdraw
bal11 = await ramp.balanceOf(we.address)
bal11.toString()
bal22 = await ramp.balanceOf(cakeWhale)
bal22.toString()




-----------------------Imitate Beefy Vault---------------------------
1. define interactable user addresses (unlocked by ganache) to access funds
mone = '0x7C8DA84c4a4b4ba9BDad65332C6Fd46BBB04b884'
rampWhale = '0xF977814e90dA44bFA03b6295A0616a897441aceC'
cakeWhale = '0xD6216fC19DB775Df9774a6E33526131dA7D19a2c'

2. define interactable tokens
moo = await MooToken.deployed()
cake = await IBEP20.at('0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82')
ramp = await IBEP20.at('0x8519EA49c997f50cefFa444d240fB655e89248Aa')
3. deploy Beefy Imitation
drain = await SimpleGenerator2.deployed()
5. Transfer rewards to the Syrup Pool and needed users
await ramp.transfer(drain.address, 100000000, {from: rampWhale})
await ramp.transfer(cakeWhale, 100000000, {from: rampWhale})
6. Give needed approvals
await ramp.approve(drain.address, 100, {from: cakeWhale})
7. Save balance of REWARD into var
balb4 = await ramp.balanceOf(cakeWhale)
7. deposit into Beefy Vault
await drain.beefIn(100, {from:cakeWhale})
8. see if share token is issued
sharebal = await moo.balanceOf(cakeWhale)
sharebal.toString()
8. withdraw from Beefy Vault
await drain.beefOut(100, {from:cakeWhale})
8. compare balances before and after usage fo beefy vault
 asd2 = await moo.balanceOf(cakeWhale)

------------------------all together-----------------------------
1. define interactable user addresses (unlocked by ganache) to access funds
mone = '0x7C8DA84c4a4b4ba9BDad65332C6Fd46BBB04b884'
rampWhale = '0xF977814e90dA44bFA03b6295A0616a897441aceC'
cakeWhale = '0xD6216fC19DB775Df9774a6E33526131dA7D19a2c'
2. define interactable tokens
cake = await IBEP20.at('0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82')
ramp = await IBEP20.at('0x8519EA49c997f50cefFa444d240fB655e89248Aa')
share = await ShareToken.deployed()
3. deploy Beefy Imitation, IYR and Syrup Pool
drain = await SimpleAggregator.deployed()
we = await Redirector.deployed()
ramppool = await SmartChefInitializable.deployed()
4. Initialize Syrup Pool
await ramppool.initialize('0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82', '0x8519EA49c997f50cefFa444d240fB655e89248Aa', 1000, 13934970, 16592383, 5000000000, accounts[0])
5. Transfer rewards to the Syrup Pool and needed users
await ramp.transfer(ramppool.address, 100000000, {from: rampWhale})
await ramp.transfer(drain.address, 100000000, {from: rampWhale})
6. Give needed approvals
await cake.approve(we.address, 10000, {from: mone})
await cake.approve(we.address, 10000, {from: cakeWhale})
7. measure balances of users before usage of optimizer
bal1 = await share.balanceOf(we.address)
bal2 = await ramp.balanceOf(we.address)
bal3 = await ramp.balanceOf(cakeWhale)
8. deposit and withdraw from optimizer
await we.depositIntoOptimizer(2500, {from:mone})
await we.depositIntoOptimizer(5000, {from:cakeWhale})
await we.depositIntoOptimizer(2500, {from:mone})
await we.withdrawFromOptimizer(2500, {from:cakeWhale})
9. measure balances of users after usage of optimizer
bal11 = await share.balanceOf(we.address)
bal22 = await ramp.balanceOf(we.address)
bal33 = await ramp.balanceOf(cakeWhale)
10. get user amount of staked cake or rewards earned
asd1 = await we.getUserStakedCake(mone)
asd2 = await we.getUserShare(mone)

