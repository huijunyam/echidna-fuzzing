pragma solidity ^0.6.0;

import "./setup.sol";
import '../libraries/Math.sol';

contract EchidnaUniV2Test is Setup {
    using SafeMath for uint;
    event logUints(uint val1, uint val2, uint val3);
    function testProvideLiquidityInvariants(uint amount1, uint amount2) public {
        //preconditions
        amount1 = _between(amount1, 1000, uint(-1));
        amount2 = _between(amount2, 1000, uint(-1));
        if(!complete) {
            _init(amount1,amount2);
        }
        uint pairBalanceBefore = testPair.balanceOf(address(user));
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(token1), address(token2));
        uint kBefore = reserve1Before * reserve2Before;
        uint pairTotalSupplyBefore = testPair.totalSupply();
        //Action  
        (bool success, ) = user.proxy(address(router),abi.encodeWithSelector(router.addLiquidity.selector, address(token1), address(token2), amount1, amount2, 0, 0, address(user), uint(-1)));
        
        //postconditions
        if (success) {
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(token1), address(token2));
            uint pairBalanceAfter = testPair.balanceOf(address(user));
            uint kAfter = reserve1After*reserve2After;
            uint pairTotalSupplyAfter = testPair.totalSupply();
            assert(kBefore < kAfter);
            assert(pairBalanceBefore < pairBalanceAfter);
            assert(pairTotalSupplyBefore < pairTotalSupplyAfter);
            assert(reserve1Before < reserve1After);
            assert(reserve2Before < reserve2After);
            if (pairTotalSupplyBefore == 0) {
                uint val = amount1.mul(amount2);
                assert(testPair.balanceOf(address(user))== Math.sqrt(val).sub(10**3));
            }
        } 
    }

    function testRemoveLiquidityInvariants(uint amount) public {
        //preconditions
        require(testPair.balanceOf(address(user)) > 0);
        amount = _between(amount, 0, testPair.balanceOf(address(user)));
        uint pairBalanceBefore = testPair.balanceOf(address(user));
        uint token1Before = token1.balanceOf(address(user));
        uint token2Before = token2.balanceOf(address(user));
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(token1), address(token2));
        uint kBefore = reserve1Before * reserve2Before;
        uint pairTotalSupplyBefore = testPair.totalSupply();

        //Action
        (bool success, ) = user.proxy(address(testPair),abi.encodeWithSelector(testPair.approve.selector, address(router), uint(-1)));
        require(success);
        (bool success1, ) = user.proxy(address(router),abi.encodeWithSelector(router.removeLiquidity.selector, address(token1), address(token2), amount, 0, 0, address(user), uint(-1)));

        //postconditions
        if (success1) {
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(token1), address(token2));
            uint pairBalanceAfter = testPair.balanceOf(address(user));
            uint kAfter = reserve1After*reserve2After;
            uint pairTotalSupplyAfter = testPair.totalSupply();
            uint token1After = token1.balanceOf(address(user));
            uint token2After = token2.balanceOf(address(user));
            assert(kAfter < kBefore);
            assert(reserve1After < reserve1Before);
            assert(reserve2After < reserve2Before);
            assert(pairTotalSupplyAfter < pairTotalSupplyBefore);
            assert(token1Before < token1After);
            assert(token2Before < token2After);
        }
    }

    function testSwapTokens(uint amount) public {
        //preconditions
        if (!complete) {
            _init(amount, amount);
        }
        address[] memory path = new address[](2);
        path[0] = address(token1);
        path[1] = address(token2);

        uint token1BalanceBefore = UniswapV2ERC20(path[0]).balanceOf(address(user));
        uint token2BalanceBefore = UniswapV2ERC20(path[1]).balanceOf(address(user));
        require(token1BalanceBefore > 0);
        amount = _between(amount, 1, token1BalanceBefore);
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(token1), address(token2));
        uint kBefore = reserve1Before * reserve2Before;
        //Action
        (bool success, ) = user.proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, amount,0,path,address(user),uint(-1)));

        //postconditions
        if (success) {
            uint token1BalanceAfter = UniswapV2ERC20(path[0]).balanceOf(address(user));
            uint token2BalanceAfter = UniswapV2ERC20(path[1]).balanceOf(address(user));
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(token1), address(token2));
            uint kAfter = reserve1After * reserve2After;
            assert(kBefore <= kAfter);
            assert(token1BalanceBefore > token1BalanceAfter);
            assert(token2BalanceBefore < token2BalanceAfter);
        }
    }

    function testSwapZeroTokens(uint amount) public {
        //preconditions
        if (!complete) {
            _init(amount, amount);
        }
        address[] memory path = new address[](2);
        path[0] = address(token1);
        path[1] = address(token2);

        uint token1BalanceBefore = UniswapV2ERC20(path[0]).balanceOf(address(user));
        uint token2BalanceBefore = UniswapV2ERC20(path[1]).balanceOf(address(user));
        require(token1BalanceBefore > 0);
        amount = _between(amount, 1, token1BalanceBefore);
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(token1), address(token2));
        uint kBefore = reserve1Before * reserve2Before;
        //Action
        (bool success, ) = user.proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, 0,0,path,address(user),uint(-1)));

        //postconditions
        if (!success) {
            uint token1BalanceAfter = UniswapV2ERC20(path[0]).balanceOf(address(user));
            uint token2BalanceAfter = UniswapV2ERC20(path[1]).balanceOf(address(user));
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(token1), address(token2));
            uint kAfter = reserve1After * reserve2After;
            assert(kBefore == kAfter);
            assert(token1BalanceBefore == token1BalanceAfter);
            assert(token2BalanceBefore == token2BalanceAfter);
        }
    }

    /*
    Swapping x of testToken1 for y token of testToken2 and back should (roughly) give user x of testToken1.
    The following function checks this condition by assessing that the resulting x is no more than 3% from the original x.
    */
    function testPathIndependenceForSwaps(uint x) public {
        //preconditions
        if (!complete) {
            _init(1_000_000_000, 1_000_000_000);
        }

        (uint reserve1, uint reserve2) = UniswapV2Library.getReserves(address(factory), address(token1), address(token2));
        // if either reserve <= 1, swap is not possible
        require(reserve1 > 1);
        require(reserve2 > 1); 
        
        uint MINIMUM_AMOUNT = 100;
        uint user1Balance = token1.balanceOf(address(user));
        require(user1Balance > MINIMUM_AMOUNT);

        x = _between(x, MINIMUM_AMOUNT, user1Balance);
        {
            uint yOut = getAmountOut(x, reserve1, reserve2);
            if (yOut == 0) {
                yOut = 1;
            }
            x = getAmountIn(yOut, reserve1, reserve2);
        }
        address[] memory path12 = new address[](2);
        path12[0] = address(token1);
        path12[1] = address(token2);
        address[] memory path21 = new address[](2);
        path21[0] = address(token2);
        path21[1] = address(token1);

        //Action
        bool success;
        bytes memory returnData;
        uint[] memory amounts;
        uint xOut;
        uint y;

        (success, returnData) = user.proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, x, 0, path12, address(user), uint(-1)));
        if (!success)
            return;
        amounts = abi.decode(returnData, (uint[]));
        // y should be the same as yOut computed previously
        y = amounts[1];
        (success, returnData) = user.proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, y, 0, path21, address(user), uint(-1)));
        if (!success)
            return;
        amounts = abi.decode(returnData, (uint[]));
        xOut = amounts[1];

        //postconditions
        assert(x > xOut); // user cannot get more than he gave
        assert((x - xOut) * 100 <= 3 * x); // (x - xOut) / x <= 0.03; no more than 3% loss of funds
    }

    /*
    Helper function, copied from UniswapV2Library, needed in testPathIndependenceForSwaps.
    */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) 
    {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    /*
    Helper function, copied from UniswapV2Library, needed in testPathIndependenceForSwaps.
    */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) 
    {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

}