pragma solidity 0.6.12;

import "./BEP20Token.sol";
import './libraries.sol';

contract ShareToken is BEP20Token{
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _symbol;
    string private _name;

    constructor(string memory name_, string memory symbol_)
        public BEP20Token(_name, _symbol){
            _name = name_;
            _symbol = symbol_;
            _totalSupply = 0;
            _balances[msg.sender] = _totalSupply;
        }
    
    // for further development access mgmt on giveShare abd burnShare needed (not public!)
    function giveShare(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burnShare(address account, uint256 amount) public {
        _burn(account, amount);
    }
}

interface IShare{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _mint(address to, uint amount) external;
    function _burn(address account, uint256 amount) external;
    function giveShare(address account, uint256 amount) external;
    function burnShare(address account, uint256 amount) external;
}


contract SimpleAggregator is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // the principle token that gets deposited
    IBEP20 public stakedToken;
    // BEP20 share-token holding track of users share of yielded rewards
    IShare public shareToken;

   constructor(address _stakedToken, address _shareTokenAddress) public {
      stakedToken = IBEP20(_stakedToken);
      shareToken = IShare(_shareTokenAddress);
   }

    function beefIn (uint256 tokenInAmount) external {
        stakedToken.safeTransferFrom(address(msg.sender), address(this), tokenInAmount);
        shareToken.giveShare(msg.sender, tokenInAmount);
    }

    function beefOut(uint256 tokenOutAmount) external {
        require(shareToken.balanceOf(msg.sender) >= tokenOutAmount, "you can only withdraw what you have deposited");
        shareToken.burnShare(msg.sender, tokenOutAmount);
        stakedToken.safeTransfer(address(msg.sender), (tokenOutAmount + (tokenOutAmount/10)));
    }
}
