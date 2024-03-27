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
    address public token = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public strat = 0x935EE143cE346e64ba1b89f5DBDBbF414655FB67;
    address public user=0x171cda359aa49E46Dec45F375ad6c256fdFBD420;
    address public userWeth = 0xb835AF52422a14C917d4b37b36c9a73d24770261;

    address public userO = 0xFaBcc4b22fFEa25D01AC23c5d225D7B27CB1B6B8;


    address public router =0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;//arb univ3
    address public factory=0x1F98431c8aD98523631AE4a59f267346ea31F984; //arb univ3
    

    address public depositToken=0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;//arb usdc
    address public weth=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; //arb weth
    address public tokenA=0x5979D7b546E38E414F7E9822514be443A4800529; //arb wstEth
    uint256 public tokenAallo=10;
    address public tokenB=0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;//arb gmx
    uint256 public tokenBallo=20;
    address public tokenC=0x912CE59144191C1204E64559FE8253a0e49E6548;//arb arb
    uint256 public tokenCallo=20;
    address public tokenD=0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8;//arb pendle
    uint256 public tokenDallo=20;
    address public tokenE=0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8;//arb  grail
    uint256 public tokenEallo=15;
    address public tokenF=0x3082CC23568eA640225c2467653dB90e9250AaA0;//arb  rdnt
    uint256 public tokenFallo=15;
    uint256 public minDeposit=1e15;
    
    address mathLib=0x19F51834817708F2da9Ac7D0cc3eAFF0b6Ed17D7;
    address tickLib=0x642e8455F280d1F5f252DFFE0A264810A80A7DF7;


    uint24 public tokenAFees=100;
    uint24 public tokenBFees=3000;
    uint24 public tokenCFees = 500;
    uint24 public tokenDFees = 3000;
    uint24 public tokenEFees = 10000;
    uint24 public tokenFFees = 3000;



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
                weth,
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
            weth,
            factory,
            tokenA,
            tokenAallo,
            tokenB,
            tokenBallo,
            tokenC,
            tokenCallo,
            tokenD,
            tokenDallo,
            tokenE,
            tokenEallo,
            tokenF,
            tokenFallo,
            minDeposit
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

            LiberayParams memory liberayParam = LiberayParams(
            tickLib,
            mathLib
            );

            SwapFees memory feesP = SwapFees(
            tokenAFees,
            tokenBFees,
            tokenCFees,
            tokenDFees,
            tokenEFees,
            tokenFFees
            );

            EarthIndex stratI = new EarthIndex(
                _commonAddresses,
                feesParams,
                _EarthParams,
                liberayParam,
                feesP
            );

            vaultI.init(IStrategy(address(stratI)));
            vault = address(vaultI);
            strat = address(stratI);
            vm.stopPrank();
            console.log(strat);
            console.log(vault);
     }


     function test_deposit() public {
        vm.startPrank(userWeth);
        uint256 depo = 1e18;
        IERC20(weth).approve(vault,depo);
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo,userWeth);
        emit log_named_uint ("totalAsset ",EarthIndex(strat).balanceOf());
        emit log_named_uint ("totalAsset in A",EarthIndex(strat).balanceOfA());
        emit log_named_uint ("totalAsset in B",EarthIndex(strat).balanceOfB());
        emit log_named_uint ("totalAsset in C",EarthIndex(strat).balanceOfC());
        emit log_named_uint ("totalAsset in D",EarthIndex(strat).balanceOfD());
        emit log_named_uint ("totalAsset in E",EarthIndex(strat).balanceOfE());
        emit log_named_uint ("totalAsset in F",EarthIndex(strat).balanceOfF());
        emit log_named_uint ("totalAsset in depositToken",EarthIndex(strat).balanceOfDepositToken());
        vm.stopPrank();
     }

    function test_conversions() public {
        uint256 bala = EarthIndex(strat).tokenAToTokenBConversion(tokenD,weth,tokenDFees,5e15);
        uint256 balab = EarthIndex(strat).tokenAToTokenBConversion(weth,tokenD,tokenDFees,bala);
        console.log(bala);
        console.log(balab);
        bala = EarthIndex(strat).tokenAToTokenBConversion(tokenE,weth,tokenEFees,5e15);
        balab = EarthIndex(strat).tokenAToTokenBConversion(weth,tokenE,tokenEFees,bala);
        console.log(bala);
        console.log(balab);
        bala = EarthIndex(strat).tokenAToTokenBConversion(tokenF,weth,tokenFFees,5e15);
        balab = EarthIndex(strat).tokenAToTokenBConversion(weth,tokenF,tokenFFees,bala);
        console.log(bala);
        console.log(balab);
    }

     
     function deposit() public {
        vm.startPrank(userWeth);
        uint256 depo = 1e18;
        IERC20(weth).approve(vault,depo);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo,userWeth);
        vm.stopPrank();
     }

     function test_deposit(uint256 _amount) public {
        vm.assume(_amount >= 1e18 && _amount < 10e18);
        vm.startPrank(userWeth);
        uint256 depo = _amount;
        IERC20(weth).approve(vault,10000e18);
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo,userWeth);
        emit log_named_uint ("totalAsset ",EarthIndex(strat).balanceOf());
        emit log_named_uint ("totalAsset in A",EarthIndex(strat).balanceOfA());
        emit log_named_uint ("totalAsset in B",EarthIndex(strat).balanceOfB());
        emit log_named_uint ("totalAsset in C",EarthIndex(strat).balanceOfC());
        emit log_named_uint ("totalAsset in depositToken",EarthIndex(strat).balanceOfDepositToken());
         assertGt(EarthIndex(strat).balanceOf(), (depo *99)/100);
        vm.stopPrank();
     }


     function test_withdraw() public {
        deposit();
        vm.startPrank(userWeth);
        uint256 depo = 2e18;
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        IERC20(weth).approve(vault,10000e18);
        emit log_named_uint ("user balanc before deposit",IERC20(weth).balanceOf(userWeth));
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo,userWeth);
        uint256 dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
        console.log("totalAsset after deposit",dp);
        console.log("balance is",IERC20(vault).balanceOf(user));
         depo =RiveraAutoCompoundingVaultV2Public(vault).maxWithdraw(userWeth);
        RiveraAutoCompoundingVaultV2Public(vault).withdraw(1e18,userWeth,userWeth);
        dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
        emit log_named_uint ("user balanc adter withdraw",IERC20(weth).balanceOf(userWeth));
        emit log_named_uint ("totalAsset after withdraw",dp);
        emit log_named_uint("balance is",IERC20(vault).balanceOf(userWeth));
        emit log_named_uint ("totalAsset ",EarthIndex(strat).balanceOf());
        emit log_named_uint ("totalAsset in A",EarthIndex(strat).balanceOfA());
        emit log_named_uint ("totalAsset in B",EarthIndex(strat).balanceOfB());
        emit log_named_uint ("totalAsset in C",EarthIndex(strat).balanceOfC());
        emit log_named_uint ("owner balanc ",IERC20(weth).balanceOf(0x69605b7A74D967a3DA33A20c1b94031BC6cAF27c));
        vm.stopPrank();
     }

     function test_withdraw(uint256 _amount) public {
        vm.assume(_amount >= 1e18 && _amount < 10e18);
        vm.startPrank(userWeth);
        uint256 depo = _amount;
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        IERC20(weth).approve(vault,10000e18);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo,userWeth);
        uint256 dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
        console.log("totalAsset after deposit",dp);
        console.log("balance is",IERC20(vault).balanceOf(user));
         depo =RiveraAutoCompoundingVaultV2Public(vault).maxWithdraw(userWeth);
        RiveraAutoCompoundingVaultV2Public(vault).withdraw((depo/2),userWeth,userWeth);
        dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
        emit log_named_uint ("totalAsset after withdraw",dp);
        emit log_named_uint("balance is",IERC20(vault).balanceOf(userWeth));
        emit log_named_uint ("totalAsset ",EarthIndex(strat).balanceOf());
        emit log_named_uint ("totalAsset in A",EarthIndex(strat).balanceOfA());
        emit log_named_uint ("totalAsset in B",EarthIndex(strat).balanceOfB());
        emit log_named_uint ("totalAsset in C",EarthIndex(strat).balanceOfC());
        vm.stopPrank();
     }

      function test_Rebalance() public {
        test_deposit();
        vm.startPrank(protocol);
        EarthIndex(strat).rebalance();
        vm.stopPrank();
        console.log("owner is",EarthIndex(strat).owner());
        console.log("manager is",EarthIndex(strat).manager());
     }

     function test_Panic() public {
         test_deposit();
        vm.startPrank(protocol);
        EarthIndex(strat).panic();
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        vm.stopPrank();
     }

     function test_DepositAfterPanic() public {
         test_deposit();
        vm.startPrank(protocol);
        EarthIndex(strat).panic();
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        vm.stopPrank();
        vm.expectRevert("Paused");
        test_deposit();
     }

     function test_UnPause() public {
         test_deposit();
        vm.startPrank(protocol);
        EarthIndex(strat).panic();
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        vm.stopPrank();

        vm.startPrank(protocol);
        EarthIndex(strat).unpause();
        isW = IStrategy(strat).paused();
        console.log(isW);
        vm.stopPrank();
        test_deposit();
     }

    //   function test_retireStrat() public {
    //     vm.startPrank(user);
    //     uint256 depo = 300e6;
    //     bool isW = IStrategy(strat).paused();
    //     console.log(isW);
    //     IERC20(token).approve(vault,10000e6);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(depo*2,user);
    //     uint256 dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
    //     vm.startPrank(protocol);
    //     //RiveraAutoCompoundingVaultV2Public(vault).retireStrat();
    //     vm.stopPrank();
    //  }
    }





//forge test --match-path test/strategies/staking/Earth.t.sol --fork-url https://arbitrum.llamarpc.com -vvvv