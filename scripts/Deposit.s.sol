// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";


contract Deposit is Script{
    address vault = 0x33e47Fe37FeF6AB1d83e54AAD6c8D01C048171E1;
    address token = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address strat=0x8a1b62c438B7b1d73A7a323C6b685fEc021610aC;
    address public userWeth = 0xb835AF52422a14C917d4b37b36c9a73d24770261;

    function setUp() public {}

    function run() public {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        // vm.startBroadcast(privateKey);
        vm.startPrank(userWeth);
        uint256 depo = 1e18;
        IERC20(token).approve(vault,10000e18);
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo,userWeth);
        console.log("balance is",IERC20(vault).balanceOf(userWeth));
        console.log("total asset is",RiveraAutoCompoundingVaultV2Public(vault).totalAssets());

        depo =RiveraAutoCompoundingVaultV2Public(vault).maxWithdraw(userWeth);
        RiveraAutoCompoundingVaultV2Public(vault).withdraw((depo*99/100),acc,userWeth);
        uint256 tB = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
        console.log("total Assets",tB);
        console.log("balance is in vault",IERC20(vault).balanceOf(userWeth));
        console.log("balance is of user",IERC20(token).balanceOf(acc));
        
    }


}
//  forge script scripts/Deposit.s.sol:Deposit --rpc-url http://127.0.0.1:8545/ --broadcast -vvv --legacy --slow
