"# SolRockPaperScissorsLizzardSpock" 
An implementation of "Rock, paper, scissors, lizard, Spock" in Solidity.

TODO:
1. Be sure to have Truffle and Ganache installed on your machine (http://truffleframework.com/)

2. Run ganache and get the network port. modify the port attribute of truffle-config.js file

3. Be sure that files in Migration directory link to the right files in contracts directory

4. remove build folder

5. compile and migrate the project:
  $truffle compile
  $truffle migrate
  
6. Open the console:
  $truffle console

EXAMPLE:
-Instantiate the contract:
  $var rp = rpsls.at(rpsls.address)
  
-Save all the accounts:
  $accounts = web3.eth.accounts

-Get two accounts:
  $host = accounts[0]
  $other = accounts[1]

-Start a game:
  $rp.start("scissors", "ciao", {value: web3.toWei(5, "ether")})
  
-Let player two join the game:
  $rp.join(host, "paper", "ciao", {from: other, value: web3.toWei(5, "ether")})
  
-Reveal scores:
  $rp.reveal(host, "scissors", "ciao")
  $rp.reveal(host, "paper", "ciao", {from: other})
  
Look at ganache ;)
