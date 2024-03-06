# Index Vault

Index Vault is a cryptocurrency investment platform that facilitates automated diversification of your funds across multiple assets within the crypto market. This platform operates similarly to traditional index funds, allowing users to invest in a single cryptocurrency while automatically distributing their investment across a carefully selected basket of cryptocurrencies. The goal is to provide users with a convenient and efficient way to achieve portfolio diversification without the need to individually manage each asset.

# Functions

## Deposit

The deposit function performs the following steps

1. **Minimum Deposit Check:** Compares the balance with the specified `minDeposit` threshold to determine whether the contract has enough deposit tokens to initiate the allocation process.

2. **Asset Allocation:** If the balance exceeds the minimum deposit requirement, the function calculates the allocation amounts for different assets (`tokenA`, `tokenB`, `tokenC`, etc.) based on predefined percentages (`allocations`). These allocations determine how the deposit tokens will be distributed among the specified assets.

3. **Asset Swapping:** Calls the `_swapV2` function to exchange a portion of the deposit tokens for each asset according to their allocated percentages. This step ensures that the deposit tokens are distributed as intended across the specified assets.

## Earn

The Earn function performs the following steps

1. Earn function calls the EarnTokenA,EarnTokenB,EarnTokenC funtions and deposit all three tokens in aave to earn interest

## Withdraw

The withdraw function performs the following steps

1. **Withdrawal Amount Check:** Compares the requested withdrawal amount (`_amount`) with the available balance. If the requested amount is greater than the current balance, it calls the `withdrawRatio` function to adjust the withdrawal based on predefined ratios.

2. **Adjusted Withdrawal Amount:** Rechecks the updated balance after calling `withdrawRatio` and sets the withdrawal amount to the available balance if it is still greater than the updated balance.

3. **Transfer:** Transfers the calculated withdrawal amount of deposit tokens to the designated vault address.

## WithdrawRatio

The withdraw function performs the following steps

1. **Withdrawal Calculation:** Calculates the withdrawal amount for each asset (`tokenA`, `tokenB`, `tokenC`, etc.) based on their allocated percentages. This calculation ensures that the withdrawal is proportionate to the predefined ratios.

2. **Token Conversion:** Calls the `tokenAToTokenBConversion` function to convert the deposit tokens into each specific asset based on the calculated withdrawal amounts.

3. **Asset Swapping:** Calls the `_swapV2` function to execute the swapping of deposit tokens for each specific asset, completing the withdrawal process.

## CloseAll

The CloseAll function performs the following steps

1. **Balance Checks:** Retrieves the current balances of each asset (`tokenA`, `tokenB`, `tokenC`, etc.) using the `IERC20` interface.

2. **Asset Swapping:** Calls the `_swapV2` function to exchange the entire balance of each asset for deposit tokens. This effectively closes all positions and converts the assets back into the original deposit token.

## reBalance

The `rebalance` function is an external function within the contract that is designed to rebalance the portfolio by performing the following actions: closing all existing positions and then depositing the resulting funds back into the contract. This function is typically intended to be called by a manager or an authorized entity.

1. **Manager Permission Check:** Ensures that only the designated manager or authorized entity can call this function using the `onlyManager` modifier.

2. **Close All Positions:** Calls the `closeAll` function to liquidate all existing positions and convert them into the original deposit token.

3. **Deposit:** Calls the `_deposit` function to allocate the resulting deposit tokens into a diversified portfolio based on predefined allocations.
