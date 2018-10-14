pragma solidity ^0.4.21;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ENCNToken.sol";

contract Withdrawable is Ownable {
    using SafeMath for uint256;

    event Withdraw(address indexed to, uint256 amount);

    function _withdrawal(address _to, uint256 _amount) internal {
        require(_amount > 0);
        require(_to.send(_amount));
        emit Withdraw(_to, _amount);
    }
}

contract ENCNCrowdsale is Withdrawable {
    using SafeMath for uint256;

    uint256 public totalSale_ = 0;
    uint256 constant public MAX_TOTAL_SALE = 74567312 * (10 ** 18);

    uint256 public totalAffiliateTokens_ = 0;
    uint256 constant public MAX_TOTAL_AFFILIATE_TOKENS = 61009619 * (10 ** 18);

    uint256 public startSaleTime = 0;
    uint256 public endSaleTime = 0;

    uint256 public minValue = 1 * (10 ** 18); // 1 ether
    uint256 public minTokenCount = 5000 * (10 ** 18);
    uint256 public buyPrice = 0.001066667 * 1 ether;
    uint public sale_bonuses = 0;

    uint256 monthvalue = 2592000;

    ENCNToken public token;

    bool public IS_SALE_OPEN = false;
    bool public IS_MINT_OPEN = false;

    function totalSale() public view returns (uint256) {
        return totalSale_;
    }

    function totalAffiliateTokens() public view returns (uint256) {
        return totalAffiliateTokens_;
    }

    function buyTokens(address _beneficiary) public payable {
        require(IS_SALE_OPEN);
        require(now >= startSaleTime && now < endSaleTime);
        require(msg.sender == _beneficiary);
        require(msg.value >= minValue);
        uint256 amount = msg.value.div(buyPrice).mul(10**18);
        require(amount >= minTokenCount);

        uint256 _bonuses = 0;
        if (sale_bonuses > 0) {
            _bonuses = amount.mul(sale_bonuses).div(100);
        }

        _mintSaleWithLock(_beneficiary, amount, _bonuses);
    }

    function() public payable {
        buyTokens(msg.sender);
    }

    function setSaleBonus(uint _sale_bonuses) public onlyOwner {
        sale_bonuses = _sale_bonuses;
    }

    function withdrawal(address _to) public onlyOwner {
        super._withdrawal(_to, address(this).balance);
    }

    function mintSale(address _to, uint256 _amount, uint256 _bonuses) public onlyOwner {
        _mintSale(_to, _amount.add(_bonuses));
    }

    function mintSaleWithLock(address _to, uint256 _amount, uint256 _bonuses) public onlyOwner{
        _mintSaleWithLock(_to, _amount, _bonuses);
    }

    function mintSaleMulty(address[] _to, uint[] _amount, uint[] _bonuses) public onlyOwner {
        require(_to.length != 0);
        require(_to.length == _amount.length);
        for (uint i = 0; i < _to.length; i++) {
            _mintSale(_to[i], _amount[i].add(_bonuses[i]));
        }
    }

    function mintSaleWithLockMulty(address[] _to, uint[] _amount, uint[] _bonuses) public onlyOwner {
        require(_to.length != 0);
        require(_to.length == _amount.length);
        require(_to.length == _bonuses.length);
        for (uint i = 0; i < _to.length; i++) {
            _mintSaleWithLock(_to[i], _amount[i], _bonuses[i]);
        }
    }

    function _mintSale(address _to, uint256 _amount) internal {
        require(IS_MINT_OPEN);
        require(_amount > 0);
        require(totalSale().add(_amount) <= MAX_TOTAL_SALE);
        totalSale_ = totalSale().add(_amount);
        require(token.mint(_to, _amount));
    }



    // ############################################################

    function _mintSaleWithLock(address _to, uint256 _amount, uint256 _bonuses) internal {
        require(IS_MINT_OPEN);

        uint256 to_mint = _amount.add(_bonuses);

        require(to_mint > 0);
        require(totalSale().add(to_mint) <= MAX_TOTAL_SALE);

        totalSale_ = totalSale().add(to_mint);

        require(token.mint(_to, to_mint));

        _lockMintSale(_to, _amount, _bonuses);

    }

    function _lockMintSale(address _to, uint256 _amount, uint256 _bonuses) internal{
        uint256 to_mint = _amount.add(_bonuses);

        if (to_mint > 0) {
            uint256 p10_amount = to_mint.div(10);
            for (uint m = 1; m <= 10; m++) {
                token.setHoldAmount(_to, p10_amount, monthvalue.mul(m));
            }
        }
    }

    function rebuildSaleLock(address _address) public onlyOwner{
        uint256 amount = token.balanceOf(_address);
        removeHoldByAddress(_address);
        _lockMintSale(_address, amount, 0);
    }

    // ############################################################

    // Fund for bus dev
    function mintFundForBusDev(address _to, uint256 _amount) public onlyOwner {
        mintAffiliate(_to, _amount);
        _lockMintFundForBusDev(_to, _amount);
    }

    function _lockMintFundForBusDev(address _to, uint256 _amount) internal{
        uint256 p2_amount = _amount.mul(2).div(100);
        uint256 p3_amount = _amount.mul(3).div(100);
        uint256 p4_amount = _amount.mul(4).div(100);
        uint256 p5_amount = _amount.mul(5).div(100);

        uint m;

        /* from 1st to 10th month */
        for (m = 1; m <= 10; m++) {
            token.setHoldAmount(_to, p2_amount, monthvalue.mul(m));
        }

        // 11th
        m = 11;
        token.setHoldAmount(_to, p3_amount, monthvalue.mul(m));

        // 12th
        m = 12;
        token.setHoldAmount(_to, p3_amount, monthvalue.mul(m));

        /* from 13th to 26th month */
        for (m = 13; m <= 26; m++) {
            token.setHoldAmount(_to, p5_amount, monthvalue.mul(m));
        }

        // 27th
        m = 27;
        token.setHoldAmount(_to, p4_amount, monthvalue.mul(m));
    }

    function rebuildMintFundForBusDevLock(address _address) public onlyOwner{
        uint256 amount = token.balanceOf(_address);
        removeHoldByAddress(_address);
        _lockMintFundForBusDev(_address, amount);
    }

    // ############################################################

    //Partners and advisors
    function mintPartnersAndAdvisors(address _to, uint256 _amount) public onlyOwner {
        mintAffiliate(_to, _amount);
        _lockMintPartnersAndAdvisors(_to, _amount);
    }

    function _lockMintPartnersAndAdvisors(address _to, uint256 _amount) internal{
        uint256 p10_amount = _amount.div(10);
        uint256 p5_amount = _amount.mul(5).div(100);

        uint m;

        for (m = 13; m <= 18; m++) {
            token.setHoldAmount(_to, p10_amount, monthvalue.mul(m));
        }

        for (m = 19; m <= 26; m++) {
            token.setHoldAmount(_to, p5_amount, monthvalue.mul(m));
        }
    }

    function rebuildMintPartnersAndAdvisorsLock(address _address) public onlyOwner{
        uint256 amount = token.balanceOf(_address);
        removeHoldByAddress(_address);
        _lockMintPartnersAndAdvisors(_address, amount);
    }

    // ############################################################

    // Team and early backers
    function mintTeamAndEarlyBackers(address _to, uint256 _amount) public onlyOwner {
        mintAffiliate(_to, _amount);
        _lockMintTeamAndEarlyBackers(_to, _amount);
    }

    function _lockMintTeamAndEarlyBackers(address _to, uint256 _amount) internal{

        uint256 p2_amount = _amount.mul(2).div(100);
        uint256 p3_amount = _amount.mul(3).div(100);

        uint m;

        for (m = 1; m <= 14; m++) {
            token.setHoldAmount(_to, p2_amount, monthvalue.mul(m));
        }

        for(m = 15; m <= 24; m++) {
            token.setHoldAmount(_to, p3_amount, monthvalue.mul(m));
        }

        for(m = 25; m <= 45; m++) {
            token.setHoldAmount(_to, p2_amount, monthvalue.mul(m));
        }
    }

    function rebuildMintTeamAndEarlyBackersLock(address _address) public onlyOwner{
        uint256 amount = token.balanceOf(_address);
        removeHoldByAddress(_address);
        _lockMintTeamAndEarlyBackers(_address, amount);
    }

    // ############################################################

    // Incentives for Retail
    function mintIncentivesForRetail(address _to, uint256 _amount) public onlyOwner {
        mintAffiliate(_to, _amount);
        _lockMintIncentivesForRetail(_to, _amount);
    }

    function _lockMintIncentivesForRetail(address _to, uint256 _amount) internal {
        uint256 p1_amount = _amount.div(100);

        uint m;

        for (m = 4; m <= 12; m++) {
            token.setHoldAmount(_to, p1_amount, monthvalue.mul(m));
        }
    }

    function rebuildMintIncentivesForRetailLock(address _address) public onlyOwner{
        uint256 amount = token.balanceOf(_address);
        removeHoldByAddress(_address);
        _lockMintIncentivesForRetail(_address, amount);
    }

    // ############################################################

    // Incentives  Data Science
    function mintIncentivesDataScience(address _to, uint256 _amount) public onlyOwner {
        mintAffiliate(_to, _amount);
        _lockMintIncentivesDataScience(_to, _amount);
    }

    function _lockMintIncentivesDataScience(address _to, uint256 _amount) internal{
        uint256 p1_amount = _amount.div(100); // 1%
        uint m;
        for (m = 1; m <= 12; m++) {
            token.setHoldAmount(_to, p1_amount, monthvalue.mul(m));
        }
    }

    function rebuildMintIncentivesDataScienceLock(address _address) public onlyOwner{
        uint256 amount = token.balanceOf(_address);
        removeHoldByAddress(_address);
        _lockMintIncentivesDataScience(_address, amount);
    }

    // ############################################################

    // Incentives Blockchain
    function mintIncentivesBlockchain(address _to, uint256 _amount) public onlyOwner {
        mintAffiliate(_to, _amount);
        _lockMintIncentivesBlockchain(_to, _amount);
    }

    function _lockMintIncentivesBlockchain(address _to, uint256 _amount) internal {
        uint256 p1_amount = _amount.div(100); // 1%

        uint m;

        for (m = 1; m <= 12; m++) {
            token.setHoldAmount(_to, p1_amount, monthvalue.mul(m));
        }
    }

    function rebuildMintIncentivesBlockchainLock(address _address) public onlyOwner{
        uint256 amount = token.balanceOf(_address);
        removeHoldByAddress(_address);
        _lockMintIncentivesBlockchain(_address, amount);
    }

    // ############################################################

    // Incentives for legal support
    function mintIncentivesForLegalSupport(address _to, uint256 _amount) public onlyOwner {
        mintAffiliate(_to, _amount);
        _lockMintIncentivesForLegalSupport(_to, _amount);
    }

    function _lockMintIncentivesForLegalSupport(address _to, uint256 _amount) internal {
        uint256 p1_amount = _amount.div(100); // 1%

        uint m;

        for (m = 4; m <= 15; m++) {
            token.setHoldAmount(_to, p1_amount, monthvalue.mul(m));
        }
    }

    function rebuildMintIncentivesForLegalSupportLock(address _address) public onlyOwner{
        uint256 amount = token.balanceOf(_address);
        removeHoldByAddress(_address);
        _lockMintIncentivesForLegalSupport(_address, amount);
    }

    // ############################################################

    // Bounty
    function mintBounty(address _to, uint256 _amount) public onlyOwner {
        mintAffiliate(_to, _amount);
        _lockMintBounty(_to, _amount);
    }

    function _lockMintBounty(address _to, uint256 _amount) internal {
        uint256 p3_amount = _amount.mul(3).div(100); // 3%
        uint256 p4_amount = _amount.mul(4).div(100); // 4%
        uint256 p5_amount = _amount.mul(5).div(100); // 5%

        uint m;

        for (m = 4; m <= 12; m++) {
            token.setHoldAmount(_to, p3_amount, monthvalue.mul(m));
        }

        for (m = 13; m <= 22; m++) {
            token.setHoldAmount(_to, p5_amount, monthvalue.mul(m));
        }

        // 23th
        m = 23;
        token.setHoldAmount(_to, p4_amount, monthvalue.mul(m));

        for (m = 24; m <= 26; m++) {
            token.setHoldAmount(_to, p3_amount, monthvalue.mul(m));
        }
    }

    function rebuildMintBountyLock(address _address) public onlyOwner{
        uint256 amount = token.balanceOf(_address);
        removeHoldByAddress(_address);
        _lockMintBounty(_address, amount);
    }

    // ############################################################

    function mintAffiliateWithLock(address _to, uint256 _amount, uint256 _locktime) public onlyOwner {
        mintAffiliate(_to, _amount);
        token.setHoldAmount(_to, _amount, _locktime);
    }

    function rebuildMintAffiliateLock(address _address, uint256 _locktime) public onlyOwner {
        uint256 amount = token.balanceOf(_address);
        removeHoldByAddress(_address);
        token.setHoldAmount(_address, amount, _locktime);
    }

    // ############################################################

    function mintAffiliate(address _to, uint256 _amount) public onlyOwner {
        require(IS_MINT_OPEN);
        require(totalAffiliateTokens().add(_amount) <= MAX_TOTAL_AFFILIATE_TOKENS);
        totalAffiliateTokens_ = totalAffiliateTokens().add(_amount);
        require(token.mint(_to, _amount));
    }

    function _burn(address _from, uint256 _amount) internal {
        require(IS_MINT_OPEN);
        token.burnMintFrom(_from, _amount);
    }

    function burnSale(address _from, uint256 _amount) public onlyOwner {
        require(totalSale().sub(_amount) >= 0);
        require(_amount > 0);
        _burn(_from, _amount);
        totalSale_ = totalSale().sub(_amount);
    }

    function burnAffiliate(address _from, uint256 _amount) public onlyOwner {
        require(totalAffiliateTokens().sub(_amount) >= 0);
        require(_amount > 0);
        _burn(_from, _amount);
        totalAffiliateTokens_ = totalAffiliateTokens().sub(_amount);
    }

    function lock(address _to, uint256 _amount, uint256 _time) public onlyOwner{
        token.setHoldAmount(_to, _amount, _time);
    }

    function finalizeCrowdsale() public onlyOwner {
        require(IS_MINT_OPEN);

        IS_MINT_OPEN = false;
        token.finishMinting();
    }

    function setToken(address _token) public onlyOwner {
        require(totalSale() == 0);
        require(totalAffiliateTokens() == 0);

        token = ENCNToken(_token);
        IS_MINT_OPEN = true;
    }

    function startSale(uint256 limitSaleTime) public onlyOwner {
        setStartSaleTime(now);
        setEndSaleTime(now.add(limitSaleTime.mul(24).mul(3600)));
        IS_SALE_OPEN = true;
    }

    function endSale() public onlyOwner {
        require(IS_SALE_OPEN);
        setEndSaleTime(now);
        IS_SALE_OPEN = false;
    }

    function transferTokenOwnership(address newOwner) public onlyOwner {
        token.transferOwnership(newOwner);
    }

    function setStartSaleTime(uint256 newStartSaleTime) public onlyOwner {
        startSaleTime = newStartSaleTime;
    }

    function setEndSaleTime(uint256 newEndSaleTime) public onlyOwner {
        endSaleTime = newEndSaleTime;
    }

    function setPrice(uint256 newBuyPrice) public onlyOwner {
        buyPrice = newBuyPrice;
    }


    function removeHoldByAddress(address _address) public onlyOwner {
        token.removeHoldByAddress(_address);
    }

    function removeHoldByAddressIndex(address _address, uint256 _index) public onlyOwner {
        token.removeHoldByAddressIndex(_address, _index);
    }

    function changeHoldByAddressIndex(address _address, uint256 _index, uint256 _amount, uint256 _time) public onlyOwner {
        token.changeHoldByAddressIndex(_address, _index, _amount, _time);
    }

}
