/// tap.sol -- liquidation engine (see also `vow`)

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain Break <rainbreak@riseup.net>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.4.18;

import "./tub.sol";

contract SaiTap is DSThing {
    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;

    SaiVox   public  vox;
    SaiTub   public  tub;

    uint256  public  gap;  // Boom-Bust Spread
    bool     public  off;  // Cage flag
    uint256  public  fix;  // Cage price

    // Surplus
    function joy() public view returns (uint) {
        return sai.balanceOf(this);
    }
    // Bad debt
    function woe() public view returns (uint) {
        return sin.balanceOf(this);
    }
    // Collateral pending liquidation
    function fog() public view returns (uint) {
        return skr.balanceOf(this);
    }


    function SaiTap(SaiTub tub_) public {
        tub = tub_;

        sai = tub.sai();
        sin = tub.sin();
        skr = tub.skr();

        vox = tub.vox();

        gap = WAD;
    }

    function mold(bytes32 param, uint val) public note auth {
        if (param == 'gap') gap = val;
    }

    // Cancel debt
    function heal() public note { //cancel debt
        if (joy() == 0 || woe() == 0) return;  // optimised
        var wad = min(joy(), woe());
        sai.burn(wad);
        sin.burn(wad);
    }

    // Feed price (sai per skr)
    function s2s() public returns (uint) { //get the skr per sai rate (for boom and bust)
        var tag = tub.tag();    // ref per skr
        var par = vox.par();    // ref per sai
        return rdiv(tag, par);  // sai per skr
    }
    // Boom price (sai per skr)
    function bid(uint wad) public returns (uint) { //get the amount of skr in sai for boom
        return rmul(wad, wmul(s2s(), sub(2 * WAD, gap)));
    }
    // Bust price (sai per skr)
    function ask(uint wad) public returns (uint) { //get the amount of skr in sai for bust
        return rmul(wad, wmul(s2s(), gap));
    }
    function flip(uint wad) internal {
        require(ask(wad) > 0);
        skr.push(msg.sender, wad);
        sai.pull(msg.sender, ask(wad));
        heal();
    }
    function flop(uint wad) internal {
        skr.mint(sub(wad, fog()));
        flip(wad);
        require(joy() == 0);  // can't flop into surplus
    }
    function flap(uint wad) internal {
        heal();
        sai.push(msg.sender, bid(wad));
        skr.burn(msg.sender, wad);
    }

    //sell SKR in return for Sai (decreases fog, increases joy and woe, can increase SKR supply)
    function bust(uint wad) public note {
        require(!off);
        if (wad > fog()) flop(wad); //inflate and sell 
        else flip(wad); //collateral sell off 
    }
    
    //sell Sai in return for SKR (decreases joy and woe, decreases SKR supply)
    function boom(uint wad) public note {
        require(!off);
        flap(wad);
    }

    // Through boom and bust we close the feedback loop on the price of SKR. When there is surplus Sai, SKR is burned, decreasing the SKR supply and increasing per, giving SKR holders more GEM per SKR. 
    //When there is surplus Woe, SKR is inflated, increasing the SKR supply and decreasing per, giving SKR holders less GEM per SKR.
    //Two features of this mechanism:
        //Whilst SKR can be inflated significantly, there is a finite limit on the amount of bad debt the system can absorb - given by the value of the underlying GEM collateral.
        // There is a negative feedback between bust and bite: as SKR is inflated it becomes less valuable, reducing the safety level of CDPs. Some CDPs will become unsafe and be vulnerable to liquidation, creating more bad debt. 
        // In an active market, CDP holders will have to be vigilant about the potential for SKR inflation if they are holding tightly collateralised CDPs.
    //------------------------------------------------------------------

    function cage(uint fix_) public note auth {
        require(!off);
        off = true;
        fix = fix_;
    }
    function cash(uint wad) public note { //cash in sai balance for gems after cage
        require(off);
        sai.burn(msg.sender, wad);
        require(tub.gem().transfer(msg.sender, rmul(wad, fix)));
    }
    function mock(uint wad) public note {
        require(off);
        sai.mint(msg.sender, wad);
        require(tub.gem().transferFrom(msg.sender, this, rmul(wad, fix)));
    }
    function vent() public note { //process a caged tub
        require(off);
        skr.burn(fog());
    }
}
