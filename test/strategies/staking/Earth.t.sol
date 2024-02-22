// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../../../src/strategies/staking/EarthIndex.sol";
import "../../../src/strategies/common/interfaces/IStrategy.sol";

contract EarthT is Test{
    address public vault = 0xcc08992d3E52FdfA79826E442910865E663fd710;
    address public token = 0xBC3FCA55ABA295605830E25c7F5Ba9C58Ce0167C;
    address public strat = 0x935EE143cE346e64ba1b89f5DBDBbF414655FB67;

    address public user = 0xFaBcc4b22fFEa25D01AC23c5d225D7B27CB1B6B8;


    address public router =0xdd9501781fa1c77584B0c55e0e68607AF3c35840;
    address public factory=0xE63D69fFdB211dD747ad8970544043fADE7d20f5;

    address public depositToken=0xBC3FCA55ABA295605830E25c7F5Ba9C58Ce0167C;
    address public tokenA=0xa38e9508368a823249b7eF291156F93CDcB8E66E;
    uint256 public tokenAallo=40;
    address public tokenB=0x98308Df644D91B78a797493C184dF7A731ecb530;
    uint256 public tokenBallo=30;
    address public tokenC=0xC23470d6A96BB96461789b032905e7CE8634d163;
    uint256 public tokenCallo=15;
    address public tokenD=0x989686C23206b121DcFA70C0042B8Fc29d7770a7;
    uint256 public tokenDallo=15;



    address protocol = 0x69605b7A74D967a3DA33A20c1b94031BC6cAF27c;
    address partner = 0x69605b7A74D967a3DA33A20c1b94031BC6cAF27c;
    uint256 partnerFee = 0;
    uint256 protocolFee = 0;
    uint256 fundManagerFee = 0;
    uint256 withdrawFee = 1;
    uint256 withdrawFeeDecimals = 100;
    uint256 feeDecimals = 100;



    
    uint256 stratUpdateDelay = 172800;
    uint256 vaultTvlCap = 10000e18;

    function setUp() public {
         uint privateKey = vm.envUint("PRIVATE_KEY");
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        vm.startPrank(acc);

          RiveraAutoCompoundingVaultV2Public vaultI = new RiveraAutoCompoundingVaultV2Public(
                depositToken,
                "Earth-USDC-Index-Vault",
                "Earth-USDC-Index-Vault",
                stratUpdateDelay,
                vaultTvlCap
            );
        CommonAddresses memory _commonAddresses = CommonAddresses(
            address(vaultI),
            router
        );


        EarthIndexParams memory _EarthParams =  EarthIndexParams(
            depositToken,
            factory,
            tokenA,
            tokenAallo,
            tokenB,
            tokenBallo,
            tokenC,
            tokenCallo
            // tokenD,
            // tokenDallo
        );


          EarthFeesParams memory feesParams = EarthFeesParams(
            protocol,
            partner,
            partnerFee,
            protocolFee,
            fundManagerFee,
            feeDecimals,
            withdrawFee,
            withdrawFeeDecimals
            );

            EarthIndex stratI = new EarthIndex(
                _commonAddresses,
                feesParams,
                _EarthParams
            );

            vaultI.init(IStrategy(address(stratI)));
            vault = address(vaultI);
            strat = address(stratI);
            vm.stopPrank();
     }


    //  function test_deposit() public {
    //     vm.startPrank(user);
    //     uint256 depo = 10e6;
    //     IERC20(token).approve(vault,10000e6);
    //     bool isW = IStrategy(strat).paused();
    //     console.log(isW);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(depo,user);
    //     console.log("balance is",IERC20(vault).balanceOf(user));
    //     vm.stopPrank();
    //  }


     function test_withdraw() public {
        vm.startPrank(user);
        uint256 depo = 101e6;
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        IERC20(token).approve(vault,10000e6);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo*2,user);
        uint256 dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
        console.log("totalAsset after deposit",dp);
         depo =RiveraAutoCompoundingVaultV2Public(vault).maxWithdraw(user);
        RiveraAutoCompoundingVaultV2Public(vault).withdraw(depo,user,user);
        dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
        console.log("totalAsset after withdraw",dp);
        console.log("balance is",IERC20(vault).balanceOf(user));
        vm.stopPrank();
     }
    }





//forge test --match-path test/strategies/staking/Earth.t.sol --fork-url https://sepolia.blast.io -vvvv