// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";


contract Deposit is Script{
    address vault = 0xcc08992d3E52FdfA79826E442910865E663fd710;
    address token = 0xBC3FCA55ABA295605830E25c7F5Ba9C58Ce0167C;
    address strat=0x935EE143cE346e64ba1b89f5DBDBbF414655FB67;

    function setUp() public {}

    function run() public {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        vm.startBroadcast(privateKey);
        
        uint256 depo = 10e6;
        IERC20(token).approve(vault,10000e6);
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo,acc);
        console.log("balance is",IERC20(vault).balanceOf(acc));
        
    }


}
//  forge script scripts/Deposit.s.sol:Deposit --rpc-url http://127.0.0.1:8545/ --broadcast -vvv --legacy --slow
