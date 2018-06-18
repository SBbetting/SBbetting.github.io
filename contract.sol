pragma solidity ^0.4.21;
import "./SafeMath.sol";



contract EIP20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract WorldCupGame {
    using SafeMath for uint256;
    address public owner;
    address public tokenAddress;
    EIP20Interface public token;
    
    address[] public winners;

    uint256 public betAmount;
    
    struct  Score {
        address better;
        uint256 homeScore;
        uint256 guestScore;
    }
    
    Score[] public scores; // this array stores the guessing scores of each game;
    
    uint256 public betterCounter=0;
    uint256 public winnerCounter=0;
    
    uint256 public homeScoreOutcome;
    uint256 public guestScoreOutcome;
    
    enum States { Open, Closed, Resolved }
    States public state;
    
    function WorldCupGame(address _address) public { // constructor
        owner = msg.sender;
        betAmount = 100;
        state = States.Open; // open the state
        token = EIP20Interface(_address);
        tokenAddress = _address;
    }
    
    
    
    function changeTokenAddress(address _address) public { // connect token to erc20 tokens
        require(msg.sender == owner);
        token = EIP20Interface(_address);
        tokenAddress = _address;
    }
    
    function changeMinAmount(uint256 _amount) public {
         require(msg.sender == owner);
         betAmount = _amount;
    }
    
    
    // function test(address _address,uint _amount) public { // connect token to erc20 tokens
    //     token.transfer(_address,_amount);
    // }
    
    // function test1(address _from, address _to, uint _amount) public{
    //     token.transferFrom(_from,_to,_amount);
    // }
    
    // function test2(address _from, uint _amount) public{
    //     token.transferFrom(_from,address(this),_amount);
    // }
    
    // function test3(uint _amount) public{
    //     token.transferFrom(msg.sender,address(this),_amount);
    // }
    
    // function test2(address _from, address _to, uint _amount){
    //     token.approve(address(this),_amount);
    // }
    
    
    function closeBetting() public{
        require(msg.sender == owner);
        state = States.Closed;
    }
    
    // bet the score
    function bet(uint _home, uint _guest) public{
        require(state == States.Open);// make sure state is open;
        // token.approve(this,betAmount);
        token.transferFrom(msg.sender,address(this),betAmount); // transfer token to the address, user needs to make an approval first
        Score memory newScore = Score({
            better: msg.sender,
            homeScore:_home,
            guestScore:_guest
        }); // push the new guess to the score array
        
        if (betterCounter<scores.length){
           scores[betterCounter]=newScore; // not using length method to reuse the contract in the future 
        }
        else{
           scores.push(newScore); 
        }
        betterCounter++;
    }
    
    // get total balance of Token in this better contract
    function getPoolSize() public returns(uint256){
        return token.balanceOf(address(this));
    }
    

    
    function resolveBetting(uint _home, uint _guest) public{
        require(msg.sender==owner);
        require(state == States.Closed);
        homeScoreOutcome = _home;
        guestScoreOutcome = _guest;
        
        uint256 totalPoolSize = getPoolSize(); 
        
        // resolve the winner address
        _resolveWinningResult();
        if(winnerCounter==0){
            // no one is correct, send the token to the owner address;
            // token.transfer(owner,totalPoolSize);
        }else{ // someone get the correct guess
            for(uint256 i=0;i<winnerCounter;i<i++){
              token.transfer(winners[i],totalPoolSize.div(winnerCounter));// the remiander should be small enough to be ignored
            }
        }
        
        // specify the winning address
        state = States.Resolved; // available for the next round of Betting;
    }
    
    
    function _resolveWinningResult() private returns(address[]){
        for (uint256 i=0;i<betterCounter;i++){
                // check each element of the array
                if((scores[i].homeScore == homeScoreOutcome)&&(scores[i].guestScore == guestScoreOutcome)){
                    
                        if (winnerCounter<winners.length){
                           winners[winnerCounter]=scores[i].better; // not using length method to reuse the contract in the future 
                        }
                        else{
                           winners.push(scores[i].better); 
                        }
                        winnerCounter++;
                    
                    
                    // winners[winnerCounter] = scores[i].better;
                    // winnerCounter++;
                } // the guy who win the game
        }
        return winners;
    }
    
    
    function restartGame() public{
        require(msg.sender == owner);
        winnerCounter = 0;
        betterCounter = 0;
        state = States.Open;
    }
    
    
    
}