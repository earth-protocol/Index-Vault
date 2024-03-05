// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../../../src/strategies/staking/EarthIndex.sol";
import "../../../src/strategies/common/interfaces/IStrategy.sol";
import "../../../src/strategies/staking/EarthIndex.sol";

contract EarthT is Test{
    address public vault = 0xcc08992d3E52FdfA79826E442910865E663fd710;
    address public token = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public strat = 0x935EE143cE346e64ba1b89f5DBDBbF414655FB67;
    address public user=0xDa9CE944a37d218c3302F6B82a094844C6ECEb17;

    address public userO = 0xFaBcc4b22fFEa25D01AC23c5d225D7B27CB1B6B8;


    address public router =0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//eth univ2
    address public factory=0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; //eth uniFac
    address public pool =0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;//eth aave v2

    address public depositToken=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;//eth usdc
    address public tokenA=0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; //eth wbtc
    address public aTokenA=0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656;
    uint256 public tokenAallo=50;
    address public tokenB=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;//eth weth
    address public aTokenB=0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    uint256 public tokenBallo=30;
    address public tokenC=0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;//eth aave
    address public aTokenC=0xFFC97d72E13E01096502Cb8Eb52dEe56f74DAD7B;
    uint256 public tokenCallo=20;
    address public tokenD=0x989686C23206b121DcFA70C0042B8Fc29d7770a7;
    uint256 public tokenDallo=15;
    uint256 public minDeposit=100e6;



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
            tokenCallo,
            // tokenD,
            // tokenDallo
            minDeposit
        );

        EarthIndexEarn memory _EarthIndexEarn = EarthIndexEarn (
            pool,
            aTokenA,
            aTokenB,
            aTokenC
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
                _EarthParams,
                _EarthIndexEarn
            );

            vaultI.init(IStrategy(address(stratI)));
            vault = address(vaultI);
            strat = address(stratI);
            vm.stopPrank();
            console.log(strat);
            console.log(vault);
     }


     function test_deposit() public {
        vm.startPrank(user);
        uint256 depo = 300e6;
        IERC20(token).approve(vault,10000e6);
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo,user);
        emit log_named_uint ("totalAsset ",EarthIndex(strat).balanceOf());
        emit log_named_uint ("totalAsset in A",EarthIndex(strat).balanceOfStakedA());
        emit log_named_uint ("totalAsset in B",EarthIndex(strat).balanceOfStakedB());
        emit log_named_uint ("totalAsset in C",EarthIndex(strat).balanceOfStakedC());
        vm.stopPrank();
     }


    //  function test_withdraw() public {
    //     vm.startPrank(user);
    //     uint256 depo = 100e6;
    //     bool isW = IStrategy(strat).paused();
    //     console.log(isW);
    //     IERC20(token).approve(vault,10000e6);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(depo*2,user);
    //     uint256 dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
    //     console.log("totalAsset after deposit",dp);
    //     console.log("balance is",IERC20(vault).balanceOf(user));
    //      depo =RiveraAutoCompoundingVaultV2Public(vault).maxWithdraw(user);
    //     RiveraAutoCompoundingVaultV2Public(vault).withdraw((depo/2),user,user);
    //     dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
    //     emit log_named_uint ("totalAsset after withdraw",dp);
    //     emit log_named_uint("balance is",IERC20(vault).balanceOf(user));
    //     vm.stopPrank();
    //  }
    }





//forge test --match-path test/strategies/staking/Earth.t.sol --fork-url https://eth.llamarpc.com -vvvv