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
        
    }
}