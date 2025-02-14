pragma solidity ^0.8.28;
import {console} from "forge-std/console.sol";

contract ERC20{

    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    event Transfer(address _from, address _to, uint256 value);
    event Approval(address _sender, address _spender, uint256 value);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping (address => uint256) public nonces; 
    address public _owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    bool public _paused;

    uint256 private _totalSupply;
    uint _init;

    constructor(string memory a, string memory b){
        initialize(a, b);
    }

    modifier check_paused {
        require(_paused == false);
        _;
    }

    function initialize(string memory n, string memory s) internal {
        require(_init == 0);
        _init = 1;
        name = n;
        symbol = s;
        decimals = 18;
        _totalSupply = 100000 * 10 ** decimals;
        _owner = msg.sender;
        _balances[msg.sender] = 100000 * 10 ** decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) check_paused() public returns (bool) {
        require(value <= _balances[msg.sender], "too much value");
        require(to != address(0), "cant send to zero address");
        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value ) check_paused() public returns (bool)
    {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _balances[from] -= value;
        _balances[to] += value;
        _allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function pause() public {
        require(msg.sender == _owner);
        _paused = (_paused ? false : true);
    }

    function _toTypedDataHash(bytes32 hash) public pure returns (bytes32){
        return keccak256(abi.encodePacked(hex"1901", hash));
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0))
            revert();
        return signer;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external{
        require(spender != address(0));
        require(block.timestamp < deadline);
        bytes32 try_hash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
            owner, 
            spender, 
            value, 
            nonces[owner], 
            deadline
            ));
        bytes32 new_hash = _toTypedDataHash(try_hash);
        require(recover(new_hash, v, r, s) == owner, "INVALID_SIGNER");
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
        ++nonces[owner];
    }
}