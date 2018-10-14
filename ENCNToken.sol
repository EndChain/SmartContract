Apragma solidity ^0.4.21;

import "./SafeMath.sol";
import "./StandardToken.sol";
import "./Ownable.sol";

import "./MintableToken.sol";
import "./BurnableToken.sol";

contract ENCNToken is MintableToken, BurnableToken{
    using SafeMath for uint256;

    string public name = "ENCN";
    string public symbol = "ENCN";
    uint8 constant public decimals = 18;

    uint256 constant public MAX_TOTAL_SUPPLY = 135576931 * (10 ** uint256(decimals));

    struct LockParams {
        uint256 TIME;
        uint256 AMOUNT;
    }

    mapping(address => LockParams[]) public holdAmounts;

    function isValidAddress(address _address) public view returns (bool) {
        return (_address != 0x0 && _address != address(0) && _address != 0 && _address != address(this));
    }

    modifier validAddress(address _address) {
        require(isValidAddress(_address));
        _;
    }

    function mint(address _to, uint256 _amount) public validAddress(_to) onlyOwner canMint returns (bool) {
        if (totalSupply_.add(_amount) > MAX_TOTAL_SUPPLY) {
            return false;
        }
        return super.mint(_to, _amount);
    }

    function transfer(address _to, uint256 _value) public validAddress(_to) returns (bool){
        require(!isMinting || msg.sender == owner);
        require(checkAvailableAmount(msg.sender, _value));

        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public validAddress(_to) returns (bool) {
        require(!isMinting || msg.sender == owner);
        require(checkAvailableAmount(_from, _value));

        return super.transferFrom(_from, _to, _value);
    }

    function setHoldAmount(address _address, uint256 _amount, uint256 _time) public onlyOwner {
        require(balanceOf(_address) >= _amount);

        LockParams memory lockdata;
        if (lockCountingFromTime == 0) {
            lockdata.TIME = _time;
        } else {
            lockdata.TIME = now.sub(lockCountingFromTime).add(_time);
        }
        lockdata.AMOUNT = _amount;

        holdAmounts[_address].push(lockdata);
    }

    function getTotalHoldAmount(address _address) public view returns(uint256) {
        uint256 totalHold = 0;
        LockParams[] storage locks = holdAmounts[_address];
        for (uint i = 0; i < locks.length; i++) {
            if (lockCountingFromTime == 0 || lockCountingFromTime.add(locks[i].TIME) >= now) {
                totalHold = totalHold.add(locks[i].AMOUNT);
            }
        }
        return totalHold;
    }

    function getAvailableBalance(address _address) public view returns(uint256) {
        return balanceOf(_address).sub(getTotalHoldAmount(_address));
    }

    function checkAvailableAmount(address _address, uint256 _amount) public view returns (bool) {
        return _amount <= getAvailableBalance(_address);
    }

    function removeHoldByAddress(address _address) public onlyOwner {
        delete holdAmounts[_address];
    }

    function removeHoldByAddressIndex(address _address, uint256 _index) public onlyOwner {
        delete holdAmounts[_address][_index];
    }

    function changeHoldByAddressIndex(address _address, uint256 _index, uint256 _amount, uint256 _time) public onlyOwner {
        if (_amount > 0) {
            holdAmounts[_address][_index].AMOUNT = _amount;
        }
        if (_time > 0) {
            if (lockCountingFromTime == 0) {
                holdAmounts[_address][_index].TIME = _time;
            } else {
                holdAmounts[_address][_index].TIME = now.sub(lockCountingFromTime).add(_time);
            }
        }
    }

    function burnMintFrom(address _from, uint256 _amount) public onlyOwner canMint{
        super._burn(_from, _amount);
    }

    function burnFrom(address from, uint256 value) public{
        require(!isMinting);
        require(checkAvailableAmount(from, value));
        super.burnFrom(from, value);
    }

    function burn(uint256 value) public{
        require(!isMinting);
        require(checkAvailableAmount(msg.sender, value));
        super.burn(value);
    }

}
