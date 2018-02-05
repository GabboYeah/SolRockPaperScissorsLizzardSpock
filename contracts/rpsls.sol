pragma solidity ^0.4.11;

contract rpsls {

    // Struct that identify a player
    struct Player {
        // Player Address
        address addr;
        // Hash of the choice made by the player
        bytes32 hashedChoice;
    }

    // Struct that identify a game
    struct Game {
        // Balance of the game
        uint balance;
        // Player1 struct with all his features
        Player player1;
        // Player2 struct with all his features
        Player player2;
        // PlainChoice of player1
        string player1Choice;
        // PlainChoice of player2
        string player2Choice;
        // Time in which the first of the two player reveal his choice
        uint firstRevealTime;
    }

    // Map of games
    mapping (address => Game) gamesMap;

    // Map of scores
    mapping (string => mapping(string => int)) scoresMatrix;
    
    // Check if the player is not betting
    modifier checkValue(uint value) {
        if (value > 0)
            _;
    }

    // Check if the player's choice is valid
    modifier checkChoice(string choice, address sender, uint value) {
        if (keccak256(choice) == keccak256("rock") || keccak256(choice) == keccak256("paper") || keccak256(choice) == keccak256("scissors") || keccak256(choice) == keccak256("lizard") || keccak256(choice) == keccak256("spock"))
            _;
        else if (value > 0) 
            sender.transfer(value);
    }

    // Check players hav already done their choices
    modifier checkStatus(address hostGame) {
        if (gamesMap[hostGame].player1.hashedChoice != 0 && gamesMap[hostGame].player2.hashedChoice != 0) 
            _;
    }

    // Costructor:
    //  Fill the matrix with all the possible scores configuration
    function rpsls() public {
        // Rock configurations
        scoresMatrix["rock"]["rock"] = 0;
        scoresMatrix["rock"]["paper"] = 2;
        scoresMatrix["rock"]["scissors"] = 1;
        scoresMatrix["rock"]["lizard"] = 1;
        scoresMatrix["rock"]["spock"] = 2;

        // Paper configurations
        scoresMatrix["paper"]["rock"] = 1;
        scoresMatrix["paper"]["paper"] = 0;
        scoresMatrix["paper"]["scissors"] = 2;
        scoresMatrix["paper"]["lizard"] = 2;
        scoresMatrix["paper"]["spock"] = 1;

        // Scissors configurations
        scoresMatrix["scissors"]["rock"] = 2;
        scoresMatrix["scissors"]["paper"] = 1;
        scoresMatrix["scissors"]["scissors"] = 0;
        scoresMatrix["scissors"]["lizard"] = 1;
        scoresMatrix["scissors"]["spock"] = 2;

        // Lizard configurations
        scoresMatrix["lizard"]["rock"] = 2;
        scoresMatrix["lizard"]["paper"] = 1;
        scoresMatrix["lizard"]["scissors"] = 2;
        scoresMatrix["lizard"]["lizard"] = 0;
        scoresMatrix["lizard"]["spock"] = 1;

        // Spock configurations
        scoresMatrix["spock"]["rock"] = 1;
        scoresMatrix["spock"]["paper"] = 2;
        scoresMatrix["spock"]["scissors"] = 1;
        scoresMatrix["spock"]["lizard"] = 2;
        scoresMatrix["spock"]["spock"] = 0;
    }

    // Create or restart a game.The games are saved in gamesMap using user creator address
    //  Before starting the function, bet value and choice selected are checked
    function start(string choice, string key) checkValue(msg.value) checkChoice(choice, msg.sender, msg.value) payable public {
        // Get game with index equal to player address. If there is not a game indexed in this way, 
        // it automatically create a new empty game
        Game storage g = gamesMap[msg.sender];

        // If balance is set to 0 it means that game was empty or the previos game is ended
        //  we clear all the fields before going on
        if (g.balance == 0) {
            // Clear game fields
            clear(msg.sender);
            // Adding to balance the player1 bet
            g.balance += msg.value;
            // setting the player1 address and hashed choice
            g.player1.addr = msg.sender;
            g.player1.hashedChoice = keccak256(keccak256(choice) ^ keccak256(key));
        } else {
            msg.sender.transfer(msg.value);
        }
    }

    // Clear game fields
    function clear(address hostGame) private {
        Game storage g = gamesMap[hostGame];

        g.player1.addr = 0;
        g.player1.hashedChoice = 0x0;
        g.player1Choice = "";
        g.player2.addr = 0;
        g.player2.hashedChoice = 0x0;
        g.player2Choice = "";
    }

    // Allow a player to join a game given the host address.
    //  Before joining the game, bet value and choice selected are checked
    function join(address hostGame, string choice, string key) checkValue(msg.value) checkChoice(choice, msg.sender, msg.value) payable public {
        Game storage g = gamesMap[hostGame];

        // Checking if the sender is different from the game host and if the room is not full
        if (msg.sender != g.player1.addr && g.player2.addr == 0) {
            // Adding to balance the player2 bet
            g.balance += msg.value;
            // setting the player2 address and hashed choice
            g.player2.addr = msg.sender;
            g.player2.hashedChoice = keccak256(keccak256(choice) ^ keccak256(key));
        } else {
            msg.sender.transfer(msg.value);
        }
    }

    // Reveal the player's choice. 
    //  Before starting the function, it is checked if both players have made a choice
    function reveal(address hostGame, string choice, string key) checkStatus(hostGame) public returns(address) {
        Game storage g = gamesMap[hostGame];

        // If the player that is revealing is player1 and the hashed choice matched with the saved one...
        if (msg.sender == g.player1.addr && g.player1.hashedChoice == keccak256(keccak256(choice) ^ keccak256(key))) {
            // ... we check if he is the first player who revealed:
            //  If true, we save the time in which he revealed 
            if (bytes(g.player2Choice).length == 0)
                g.firstRevealTime = block.timestamp;

            // If the time is not running out we saved the player's plainchoice in the game
            if (block.timestamp <= (g.firstRevealTime + 120))
                g.player1Choice = choice;

            // If the player2 already revealed his choice the game can ends
            if (bytes(g.player2Choice).length != 0)
                establishWinner(hostGame);

        // Same operations are done in case of player2
        } else if (msg.sender == g.player2.addr && g.player2.hashedChoice == keccak256(keccak256(choice) ^ keccak256(key))) {
            if (bytes(g.player1Choice).length == 0)
                g.firstRevealTime = block.timestamp;

            if (block.timestamp <= (g.firstRevealTime + 120))
                g.player2Choice = choice;
            
            if (bytes(g.player1Choice).length != 0)
                establishWinner(hostGame);
        }
    }

    // Establish and pay the winner of the game
    function establishWinner(address hostGame) public {
        Game storage g = gamesMap[hostGame];
        // If player2 didn't reveal his choice before countdown ended player1 wins
        if (bytes(g.player1Choice).length != 0 && bytes(g.player2Choice).length == 0 && block.timestamp >= (g.firstRevealTime + 120)) {
            // And get all the balance
            g.player1.addr.transfer(g.balance);
        
        // If player1 idn't reveal his choice before countdown ended player2 wins
        } else if (bytes(g.player1Choice).length == 0 && bytes(g.player2Choice).length != 0 && block.timestamp >= (g.firstRevealTime + 120)) {
            // And get all the balance
            g.player2.addr.transfer(g.balance);

        // In the case of both players revealed their choices check the scoreMatrix in order to establish the winner
        } else if (bytes(g.player1Choice).length != 0 && bytes(g.player2Choice).length != 0) {
            // Player1 wins
            if (scoresMatrix[g.player1Choice][g.player2Choice] == 1) {
              g.player1.addr.transfer(g.balance);

            // Player2 wins
            } else if (scoresMatrix[g.player1Choice][g.player2Choice] == 2) {
                g.player2.addr.transfer(g.balance);
            
            // Draw case
            } else {
                // Give back half of the balance to both players
                g.player1.addr.transfer(g.balance/2);
                g.player2.addr.transfer(g.balance/2);
            }
        }

        // Set the balance back to 0
        g.balance = 0;
    }

    function getGameStatus (address hostGame) public view returns(uint256, address, address, bytes32, bytes32, string, string) {
        Game storage g = gamesMap[hostGame];
        return(g.balance, g.player1.addr, g.player2.addr, g.player1.hashedChoice, g.player2.hashedChoice, g.player1Choice, g.player2Choice);
    }
}
