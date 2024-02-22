pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/Pausable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";

import "@pancakeswap-v2-exchange-protocol/interfaces/IPancakeRouter02.sol";
import "@pancakeswap-v2-core/interfaces/IPancakePair.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/ICommonStrat.sol";

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
    EarthIndexParams memory _EarthIndexParams
    )AbstractStrategy(_commonAddresses){
        depositToken = _EarthIndexParams.depositToken;
        factory = _EarthIndexParams.factory;

        tokenA = _EarthIndexParams.tokenA;
        allocations[tokenA] = _EarthIndexParams.tokenAallo;
        tokenB = _EarthIndexParams.tokenB;
        allocations[tokenB] = _EarthIndexParams.tokenBallo;
        tokenC = _EarthIndexParams.tokenC;
        allocations[tokenC] = _EarthIndexParams.tokenCallo;
        // tokenD = _EarthIndexParams.tokenD;
        // allocations[tokenD] = _EarthIndexParams.tokenDallo;

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
        if(balance > 100e6){
        uint256 depoA = (balance * (allocations[tokenA]))/100;
        _swapV2(depositToken,tokenA,depoA);
        uint256 depoB = (balance * (allocations[tokenB]))/100;
        _swapV2(depositToken,tokenB,depoB);
        uint256 depoC = (balance * (allocations[tokenC]))/100;
        _swapV2(depositToken,tokenC,depoC);
        // uint256 depoD = (balance * (allocations[tokenD]))/100;
        // _swapV2(depositToken,tokenD,depoD);
        }
    }

    function withdraw(uint256 _amount) public nonReentrant {
        onlyVault();
        clossAll();
        uint256 balanceD = IERC20(depositToken).balanceOf(address(this));
        if(_amount > balanceD){
            _amount = balanceD;
        }
        IERC20(depositToken).safeTransfer(vault,_amount);
        _deposit();
    }


    function clossAll() internal {
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        if(balanceA >0){
        _swapV2(tokenA,depositToken,balanceA);
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        _swapV2(tokenB,depositToken,balanceB);
        uint256 balanceC = IERC20(tokenC).balanceOf(address(this));
        _swapV2(tokenC,depositToken,balanceC);
        // uint256 balanceD = IERC20(tokenD).balanceOf(address(this));
        // _swapV2(tokenD,depositToken,balanceD);
        }
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


    function retireStrat() external {
        onlyVault();
    }

    function harvest() public {}

    function balanceOf() public view returns(uint256){
        uint256 balT = IERC20(depositToken).balanceOf(address(this));
        uint256 balA = IERC20(tokenA).balanceOf(address(this));
        uint256 balB = IERC20(tokenB).balanceOf(address(this));
        uint256 balC = IERC20(tokenC).balanceOf(address(this));
        //uint256 balD = IERC20(tokenD).balanceOf(address(this));
        balA = tokenAToTokenBConversion(tokenA,depositToken,balA);
        balB = tokenAToTokenBConversion(tokenB,depositToken,balB);
        balC = tokenAToTokenBConversion(tokenC,depositToken,balC);
       // balD = tokenAToTokenBConversion(tokenD,depositToken,balD);
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
    //IERC20(tokenD).approve(router,type(uint256).max);
    }

    function _removeAllowances() internal virtual {
    IERC20(depositToken).approve(router,0);
    IERC20(tokenA).approve(router,0);
    IERC20(tokenB).approve(router,0);
    IERC20(tokenC).approve(router,0);
    //IERC20(tokenD).approve(router,0);
    }


}