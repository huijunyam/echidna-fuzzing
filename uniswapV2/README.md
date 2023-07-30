Uniswap V2

invariants
LP invariants

1. Providing liquidity increase invariant, increasing X and Y will increase K
2. LP tokens are minted either:
   - proportional to the pool share (if there is liquidity already)
   - proportional to the sqrt of the token amounts(if creating a pool)
3. Providing and removing liquidity should give you starting amounts
4. Removing liquidity decrease invariant
5. Removing liquidity decrease LP token balance
6. LP token balance should be monotonically increasing

Swap invariants

1. Swap 0 tokens should give you 0 tokens out
2. Swap decreases and increases token balance appropriately
3. Swap x of token A for y token B and back should give you x of token A
   called path independence
   in practice not necessarily true because of fee, rounding
4. pool invariant stay constant during swaps
