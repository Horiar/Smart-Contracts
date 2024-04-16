// SPDX-License-Identifier: MIT


pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract HORIAR is ERC20, Ownable {

    
    address feeTakerAddress = 0x1ff5E2D732454eeaA3e4bc25676183f298D31D3e;
    address contractOwner = 0x1749F69Cee85bd26F099F9DD8d1247F3049eBe6A;


    uint public hardCap = 1_000_000_000;
    uint private _totalSupply;


    
    uint24 buyTax = 10;
    uint24 sellTax = 50;

    mapping(address account => uint256) private _balances;

    constructor()
        ERC20("HORIAR", "HORIAR")
        Ownable(contractOwner)
    {
        _mint(contractOwner, hardCap * 10 ** decimals());
    }




    // Info Functions

    function balanceOf(address account) public override view returns(uint amount){
        return _balances[account];
    }

    function totalSupply() public override view returns (uint supply){
        return _totalSupply;
    }


    //FEE FUNCTTIONS

    address [] public RouterAddresses;

    //Lets you insert an address list of Router Addresses.
    function insertRouterAddresses(address [] memory newAddresses) public onlyOwner {
        for(uint i=0; i < RouterAddresses.length;i++){
            RouterAddresses.pop();
        }
        RouterAddresses = newAddresses;
    }


    //This function checks if the user is swapping or it's a normal transaction.
    function checkAddress(address _address) private view returns(bool isExist){
        for (uint i = 0; i < RouterAddresses.length; i++) {
            if (RouterAddresses[i] == _address) {
            return true;
            }
        }
        return false;
    }



    // Tax on DEX transfers (Swaps)(Override of _transfer through _update)
    function _update(address from, address to, uint256 value) internal virtual override {

        uint tax = calculateTaxAmount(value, from, to);

        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {               
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {               
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += (value - tax);
                _balances[feeTakerAddress] += tax;
            }
        }

        emit Transfer(from, to, (value-tax));

    }


    // TAXING

    // Calculates the amount of tax on the function
    function calculateTaxAmount(uint value, address from, address to) internal view returns(uint _taxAmount){
        uint taxAmount;
        if(checkAddress(from)) {
            taxAmount = value * buyTax / 1000; 
            return taxAmount;
        } else if(checkAddress(to)) {
            taxAmount = value * sellTax / 1000; 
            return taxAmount;
        }else {
            return 0;
        }
    }


    // Sets Tax Amounts.
    function setTaxAmounts (uint24 _buyTax, uint24 _sellTax ) public onlyOwner {
        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    function setFeeTaker(address _address) public onlyOwner {
        feeTakerAddress = _address;
    }


}