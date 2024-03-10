pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/Pausable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";

import "@pancakeswap-v2-exchange-protocol/interfaces/IPancakeRouter02.sol";
import "@pancakeswap-v2-core/interfaces/IPancakePair.sol";
import "./interfaces/IV3SwapRouter.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/ICommonStrat.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IRivera.sol";

import "../common/AbstractStrategy.sol";
import "../utils/StringUtils.sol";

struct EarthIndexParams{
   address depositToken;
   address factory;
   address tokenA;
   uint256 tokenAallo;
   address tokenB;
   uint256 tokenBallo;
   address tokenC;
   uint256 tokenCallo;
//    address tokenD;
//    uint256 tokenDallo;
   uint256 minDeposit;
}


struct EarthIndexEarn{
    address pool;
    address aTokenA;
    address aTokenB;
    address aTokenC;
}


 struct EarthFeesParams {
    address protocol;
    address partner;
    uint256 protocolFee;
    uint256 partnerFee;
    uint256 fundManagerFee;
    uint256 feeDecimals;
    uint256 withdrawFee;
    uint256 withdrawFeeDecimals;
}

contract EarthIndex is AbstractStrategy,ReentrancyGuard{
    using SafeERC20 for IERC20;

    address public depositToken;
    address public factory;
    
    address public tokenA;
    address public tokenB;
    address public tokenC;
    address public tokenD;

    address public lendingPool;
    address public aTokenA;
    address public aTokenB;
    address public aTokenC;

    uint256 public minDeposit;

  mapping (address => uint) public allocations;

    //Fees Parameters
    address public protocol;
    address public partner;
    uint256 public protocolFee;
    uint256 public partnerFee;
    uint256 public fundManagerFee;
    uint256 public feeDecimals;
    uint256 public withdrawFee;
    uint256 public withdrawFeeDecimals;

    constructor(
    CommonAddresses memory _commonAddresses,
    EarthFeesParams memory _EarthFeesParams,
    EarthIndexParams memory _EarthIndexParams,
    EarthIndexEarn  memory _EarthIndexEarn
    )AbstractStrategy(_commonAddresses){
        depositToken = _EarthIndexParams.depositToken;
        factory = _EarthIndexParams.factory;

        tokenA = _EarthIndexParams.tokenA;
        allocations[tokenA] = _EarthIndexParams.tokenAallo;
        tokenB = _EarthIndexParams.tokenB;
        allocations[tokenB] = _EarthIndexParams.tokenBallo;
        tokenC = _EarthIndexParams.tokenC;
        allocations[tokenC] = _EarthIndexParams.tokenCallo;
        minDeposit = _EarthIndexParams.minDeposit;

        lendingPool = _EarthIndexEarn.pool;
        aTokenA = _EarthIndexEarn.aTokenA;
        aTokenB= _EarthIndexEarn.aTokenB;
        aTokenC =_EarthIndexEarn.aTokenC;


        protocol = _EarthFeesParams.protocol;
        partner = _EarthFeesParams.partner;
        protocolFee = _EarthFeesParams.protocolFee;
        partnerFee = _EarthFeesParams.partnerFee;
        fundManagerFee = _EarthFeesParams.fundManagerFee;
        feeDecimals = _EarthFeesParams.feeDecimals;
        withdrawFee = _EarthFeesParams.withdrawFee;
        withdrawFeeDecimals = _EarthFeesParams.withdrawFeeDecimals;   
        _giveAllowances();
    }

    function deposit() public whenNotPaused nonReentrant {
        onlyVault();
        _deposit();
    }

    function _deposit() internal{
        uint256 balance = IERC20(depositToken).balanceOf(address(this));
        if(balance > minDeposit){
        uint256 depoA = (balance * (allocations[tokenA]))/100;
        _swapV2(depositToken,tokenA,depoA);
        uint256 depoB = (balance * (allocations[tokenB]))/100;
        _swapV2(depositToken,tokenB,depoB);
        uint256 depoC = (balance * (allocations[tokenC]))/100;
        _swapV2(depositToken,tokenC,depoC);
        earn();
        }
        
    }


    function earn() internal{
      earnTokenA();
      earnTokenB();
      earnTokenC();
    }

    function earnTokenA() internal{
        uint256 balance = IERC20(tokenA).balanceOf(address(this));
        ILendingPool(lendingPool).deposit(tokenA, balance, address(this), 0);
    }
    
    function withdrawA(uint256 _amount) internal{
        ILendingPool(lendingPool).withdraw(tokenA,_amount,address(this));
    }


    // function earnTokenB() internal{
    //     uint256 balance = IERC20(tokenB).balanceOf(address(this));
    //     IRivera(riveraVault).deposit(balance, address(this));
    // }
    
    // function withdrawB(uint256 _amount) internal {
    //     IRivera(riveraVault).withdraw(_amount, address(this) ,address(this));
    // }


    function earnTokenB() internal{
        uint256 balance = IERC20(tokenB).balanceOf(address(this));
        ILendingPool(lendingPool).deposit(tokenB, balance, address(this), 0);
    }

     function withdrawB(uint256 _amount) internal {
        ILendingPool(lendingPool).withdraw(tokenB,_amount,address(this));
    }



    function earnTokenC() internal{
        uint256 balance = IERC20(tokenC).balanceOf(address(this));
        ILendingPool(lendingPool).deposit(tokenC, balance, address(this), 0);
    }

     function withdrawC(uint256 _amount) internal {
        ILendingPool(lendingPool).withdraw(tokenC,_amount,address(this));
    }

    function withdraw(uint256 _amount) public nonReentrant {
        onlyVault();
        uint256 balanceD = IERC20(depositToken).balanceOf(address(this));
        if(_amount > balanceD){
        withdrawRatio(_amount);
        swapAll();
        balanceD = IERC20(depositToken).balanceOf(address(this));
        if(balanceD < _amount){
            _amount = balanceD;
        }
        }
        IERC20(depositToken).safeTransfer(vault,_amount);
    }

    function swapAll() internal{
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        _swapV2(tokenA,depositToken,balanceA);
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        _swapV2(tokenB,depositToken,balanceB);
        uint256 balanceC = IERC20(tokenC).balanceOf(address(this));
        _swapV2(tokenC,depositToken,balanceC);
    }


    function withdrawRatio(uint256 _amount) internal {
      uint256 withdrawTokenA =tokenAToTokenBConversion(depositToken,tokenA,(_amount*allocations[tokenA])/100);
      uint256 withdrawTokenB =tokenAToTokenBConversion(depositToken,tokenB,(_amount*allocations[tokenB])/100);
      uint256 withdrawTokenC =tokenAToTokenBConversion(depositToken,tokenC,(_amount*allocations[tokenC])/100);
      withdrawA(withdrawTokenA);
      withdrawB(withdrawTokenB);
      withdrawC(withdrawTokenC);
    }


    function clossAll() internal {
      uint256 balanceA = IERC20(aTokenA).balanceOf(address(this));
      withdrawA(balanceA);
      uint256 balanceB = IERC20(aTokenB).balanceOf(address(this));
      withdrawB(balanceB);
      uint256 balanceC = IERC20(aTokenC).balanceOf(address(this));
      withdrawC(balanceC);
      swapAll();
    }

    function rebalance() external {
        onlyManager();
        clossAll();
        _deposit();
    }



     function _swapV2(address token0, address token1, uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        IPancakeRouter02(router).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp * 2
        );
    }

     function _swapV3In(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 fee
    ) internal returns (uint256 amountOut) {
        amountOut = IV3SwapRouter(router).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                tokenIn,
                tokenOut,
                fee,
                address(this),
                amountIn,
                0,
                0
            )
        );
    }


    function retireStrat() external {
        onlyVault();
    }

    function harvest() public {}

    function balanceOf() public view returns(uint256){
        return balanceOfUnStake() + balanceOfStaked();
    }


    function balanceOfStaked() public view returns(uint256){
        return balanceOfStakedA()+balanceOfStakedB()+balanceOfStakedC();
    }

   function balanceOfStakedA() public view returns(uint256){
    uint256 balanceA = IERC20(aTokenA).balanceOf(address(this));
    return tokenAToTokenBConversion(tokenA,depositToken,balanceA);
   }

//    function balanceOfStakedB() public view returns(uint256){
//     uint256 balanceB = IERC20(riveraVault).balanceOf(address(this));
//             balanceB = IRivera(riveraVault).convertToAssets(balanceB);
//     return tokenAToTokenBConversion(tokenB,depositToken,balanceB);
//    }
   
   function balanceOfStakedB() public view returns(uint256){
    uint256 balanceB = IERC20(aTokenB).balanceOf(address(this));
    return tokenAToTokenBConversion(tokenB,depositToken,balanceB);
   }


   function balanceOfStakedC() public view returns(uint256){
    uint256 balanceC = IERC20(aTokenC).balanceOf(address(this));
    return tokenAToTokenBConversion(tokenC,depositToken,balanceC);
   }


    function balanceOfUnStake() public view returns(uint256){
        uint256 balT = IERC20(depositToken).balanceOf(address(this));
        uint256 balA = IERC20(tokenA).balanceOf(address(this));
        uint256 balB = IERC20(tokenB).balanceOf(address(this));
        uint256 balC = IERC20(tokenC).balanceOf(address(this));
       
        balA = tokenAToTokenBConversion(tokenA,depositToken,balA);
        balB = tokenAToTokenBConversion(tokenB,depositToken,balB);
        balC = tokenAToTokenBConversion(tokenC,depositToken,balC);
        return balA + balB + balC+balT;
    }

    function inCaseTokensGetStuck(address _token) external {
        onlyManager();
        uint256 amount = IERC20(_token).balanceOf(address(this)); //Just finding the balance of this vault contract address in the the passed baseToken and transfers
        IERC20(_token).transfer(msg.sender, amount);
    }


    function _chargeFees(address _token) internal {
        uint256 tokenBal = IERC20(_token).balanceOf(address(this));

        uint256 protocolFeeAmount = (tokenBal * protocolFee) / feeDecimals;
        IERC20(_token).safeTransfer(manager, protocolFeeAmount);

        uint256 fundManagerFeeAmount = (tokenBal * fundManagerFee) /
            feeDecimals;
        IERC20(_token).safeTransfer(owner(), fundManagerFeeAmount);

        uint256 partnerFeeAmount = (tokenBal * partnerFee) / feeDecimals;
        IERC20(_token).safeTransfer(partner, partnerFeeAmount);
    }

    function tokenAToTokenBConversion(
        address tokenX,
        address tokenY,
        uint256 amount
    ) public view returns (uint256) {
        if (tokenX == tokenY) {
            return amount;
        }
        address lpAddress = IPancakeFactory(factory).getPair(tokenX, tokenY);
        (uint112 _reserve0, uint112 _reserve1, ) = IPancakePair(lpAddress)
            .getReserves();
        (address token0, address token1) = arrangeTokens(tokenX, tokenY);
        return
            token0 == tokenX
                ? ((amount * _reserve1) / _reserve0)
                : ((amount * _reserve0) / _reserve1);
    }

       function arrangeTokens(
        address tokenX,
        address tokenY
    ) public pure returns (address, address) {
        return tokenX < tokenY ? (tokenX, tokenY) : (tokenY, tokenX);
    }

     function panic() public {
        onlyManager();
        pause();
    }

    function pause() public {
        onlyManager();
        _pause();

        _removeAllowances();
    }

    function unpause() external {
        onlyManager();
        _unpause();

        _giveAllowances();

        _deposit();
    }

    function _giveAllowances() internal virtual {
    IERC20(depositToken).approve(router,type(uint256).max);
    IERC20(tokenA).approve(router,type(uint256).max);
    IERC20(tokenB).approve(router,type(uint256).max);
    IERC20(tokenC).approve(router,type(uint256).max);

    IERC20(depositToken).approve(lendingPool,type(uint256).max);
    IERC20(tokenA).approve(lendingPool,type(uint256).max);
    IERC20(tokenB).approve(lendingPool,type(uint256).max);
    IERC20(tokenC).approve(lendingPool,type(uint256).max);
    //IERC20(tokenD).approve(router,type(uint256).max);
    }

    function _removeAllowances() internal virtual {
    IERC20(depositToken).approve(router,0);
    IERC20(tokenA).approve(router,0);
    IERC20(tokenB).approve(router,0);
    IERC20(tokenC).approve(router,0);

    IERC20(depositToken).approve(lendingPool,0);
    IERC20(tokenA).approve(lendingPool,0);
    IERC20(tokenB).approve(lendingPool,0);
    IERC20(tokenC).approve(lendingPool,0);
    //IERC20(tokenD).approve(router,0);
    }


}