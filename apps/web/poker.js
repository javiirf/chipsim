// ==================== POKER CHIP TRACKER (2-8 PLAYERS) ====================
// Texas Hold'em chip tracking with STRICT rules enforcement

/*
 * TEXAS HOLD'EM RULES ENFORCED:
 * 
 * BLINDS:
 * - Small Blind (SB) is posted by player left of dealer (or dealer in heads-up)
 * - Big Blind (BB) is posted by player left of SB
 * - Blinds are mandatory forced bets
 * 
 * BETTING ORDER:
 * - Pre-flop: Action starts left of BB (or SB in heads-up since dealer=SB)
 * - Post-flop: Action starts left of dealer
 * - Action proceeds clockwise
 * 
 * VALID ACTIONS:
 * - FOLD: Give up hand, lose any chips already bet
 * - CHECK: Pass action (only if no bet to call)
 * - CALL: Match the current bet
 * - BET: First chips into pot on a street (when current bet is 0)
 * - RAISE: Increase the bet (minimum raise = previous raise size or BB)
 * 
 * BETTING ROUND ENDS WHEN:
 * - All active players have acted AND bets are equal (or all-in)
 * - Only one player remains (others folded)
 * 
 * MINIMUM RAISE:
 * - Must be at least the size of the previous raise
 * - Or at least the big blind if no previous raise
 */

// Sound helper - use external if available, otherwise noop
if (typeof playSound === 'undefined') {
    function playSound(type) {
        // Silent fallback - sounds defined in script.js
    }
}

// currentGameMode - define if not already defined (when poker.js is loaded standalone)
if (typeof currentGameMode === 'undefined') {
    var currentGameMode = 'poker';
}

// Poker state
let pokerPlayers = [];
let pokerPot = 0;
let pokerPhase = 'setup'; // 'setup', 'betting', 'showdown', 'result'
let pokerRound = 0;
let pokerGameStarted = false;
let pokerActivePlayerIndex = 0;
let pokerSmallBlind = 5;
let pokerBigBlind = 10;
let pokerDealerIndex = 0;
let pokerStreet = 'preflop';
let pokerLastAggressor = -1;
let pokerMinRaise = 0;
let pokerCurrentBet = 0;
let pokerLastResult = null;
let pokerBlindsPosted = false;
let pokerLastAction = null; // Track last action for display
let pokerBurnCardPending = false; // Track if a burn card animation is pending
let pokerBurnCardStreet = ''; // Which street the burn is for
let pokerHandLog = []; // Track all actions in current hand for display

// Series tracking (tracks overall game wins, not just hands)
let pokerSeriesStats = {}; // { 'PlayerName': { seriesWins: 0, seriesLosses: 0, handsWon: 0, handsLost: 0 } }

// History for undo
let pokerHistory = [];
const MAX_HISTORY = 20;

// Default player names
const defaultPlayerNames = ['Player 1', 'Player 2', 'Player 3', 'Player 4', 'Player 5', 'Player 6', 'Player 7', 'Player 8'];

// Create a new player object
function createPlayer(name, bankroll) {
    // Initialize series stats for this player if not exists
    if (!pokerSeriesStats[name]) {
        pokerSeriesStats[name] = { seriesWins: 0, seriesLosses: 0, handsWon: 0, handsLost: 0 };
    }
    return {
        name: name,
        bankroll: bankroll,
        totalBuyIn: bankroll, // Track total money invested
        bet: 0,
        roundContribution: 0, // Track chips put in this hand (for calculating profit)
        acted: false,
        stats: { handsWon: 0, handsLost: 0, handsTied: 0 }, // Per-game hand stats
        folded: false,
        isAllIn: false
    };
}

// Update series stats when a game is won
function updateSeriesStats(winnerName) {
    // Initialize winner stats if needed
    if (!pokerSeriesStats[winnerName]) {
        pokerSeriesStats[winnerName] = { seriesWins: 0, seriesLosses: 0, handsWon: 0, handsLost: 0 };
    }
    pokerSeriesStats[winnerName].seriesWins++;
    
    // Update losses for all other players who participated
    pokerPlayers.forEach(p => {
        if (p.name !== winnerName) {
            if (!pokerSeriesStats[p.name]) {
                pokerSeriesStats[p.name] = { seriesWins: 0, seriesLosses: 0, handsWon: 0, handsLost: 0 };
            }
            pokerSeriesStats[p.name].seriesLosses++;
        }
    });
    
    savePokerToStorage();
}

// Save current state to history (for undo)
function savePokerHistory() {
    const state = {
        players: pokerPlayers.map(p => ({ ...p, stats: { ...p.stats } })),
        pot: pokerPot,
        phase: pokerPhase,
        activePlayerIndex: pokerActivePlayerIndex,
        street: pokerStreet,
        lastAggressor: pokerLastAggressor,
        minRaise: pokerMinRaise,
        currentBet: pokerCurrentBet,
        dealerIndex: pokerDealerIndex,
        blindsPosted: pokerBlindsPosted,
        lastResult: pokerLastResult
    };
    pokerHistory.push(state);
    if (pokerHistory.length > MAX_HISTORY) {
        pokerHistory.shift();
    }
}

// Undo last action
function pokerUndo() {
    if (pokerHistory.length === 0) return;
    playSound('push');
    
    const state = pokerHistory.pop();
    pokerPlayers = state.players.map(p => ({ ...p, stats: { ...p.stats } }));
    pokerPot = state.pot;
    pokerPhase = state.phase;
    pokerActivePlayerIndex = state.activePlayerIndex;
    pokerStreet = state.street;
    pokerLastAggressor = state.lastAggressor;
    pokerMinRaise = state.minRaise;
    pokerCurrentBet = state.currentBet;
    pokerDealerIndex = state.dealerIndex;
    pokerBlindsPosted = state.blindsPosted ?? false;
    pokerLastResult = state.lastResult;
    
    savePokerToStorage();
    renderPoker();
}

// Save poker state to cloud
function savePokerToStorage() {
    // Call cloud save function (defined in cloud-storage.js)
    if (typeof savePokerToCloud === 'function') {
        savePokerToCloud();
    }
    
    // Also sync to Firebase if in a room
    if (typeof syncPokerStateToFirebase === 'function' && currentRoomRef && isHost) {
        syncPokerStateToFirebase();
    }
    
    // Sync series stats to Firebase
    if (typeof syncPokerSeriesToFirebase === 'function' && pokerSeriesStats && Object.keys(pokerSeriesStats).length > 0) {
        syncPokerSeriesToFirebase();
    }
}

// Load poker state from cloud
async function loadPokerFromStorage() {
    try {
        // Try to load from cloud (defined in cloud-storage.js)
        if (typeof loadPokerFromCloud === 'function') {
            const loaded = await loadPokerFromCloud();
            if (loaded) {
                return;
            }
        }
        // Defaults if nothing loaded
        pokerPlayers = [];
        pokerGameStarted = false;
        pokerPhase = 'setup';
    } catch (e) {
        pokerPlayers = [];
        pokerGameStarted = false;
        pokerPhase = 'setup';
    }
}

// Start new poker game
function pokerStartGame(numPlayers, buyIn, playerNames, sb, bb) {
    playSound('push');
    
    pokerPlayers = [];
    for (let i = 0; i < numPlayers; i++) {
        const name = playerNames[i] || defaultPlayerNames[i];
        pokerPlayers.push(createPlayer(name, buyIn));
    }
    
    pokerSmallBlind = sb || 5;
    pokerBigBlind = bb || 10;
    pokerGameStarted = true;
    pokerPhase = 'betting';
    pokerRound = 1;
    pokerDealerIndex = 0;
    pokerStreet = 'preflop';
    pokerPot = 0;
    pokerHistory = [];
    pokerLastResult = null;
    pokerMinRaise = pokerBigBlind;
    pokerCurrentBet = 0;
    pokerBlindsPosted = false;
    
    // Auto-post blinds
    postBlinds();
    
    savePokerToStorage();
    renderPoker();
}

// Helper function to start game with input values
function startPokerWithInputs(buyIn) {
    const numPlayers = parseInt(document.getElementById('numPlayersInput')?.value) || 2;
    let sb = parseInt(document.getElementById('sbInput')?.value);
    let bb = parseInt(document.getElementById('bbInput')?.value);
    
    // Auto-calculate blinds if not customized (based on starting chips)
    // Aim for ~50-100 big blinds to start
    if (!sb || !bb || (sb === 5 && bb === 10)) {
        if (buyIn <= 20) {
            sb = 1; bb = 1; // Very low stakes
        } else if (buyIn <= 50) {
            sb = 1; bb = 2;
        } else if (buyIn <= 100) {
            sb = 1; bb = 2;
        } else if (buyIn <= 200) {
            sb = 2; bb = 5;
        } else if (buyIn <= 500) {
            sb = 5; bb = 10;
        } else if (buyIn <= 1000) {
            sb = 5; bb = 10;
        } else if (buyIn <= 2000) {
            sb = 10; bb = 20;
        } else {
            sb = 25; bb = 50;
        }
    }
    
    const playerNames = [];
    for (let i = 0; i < numPlayers; i++) {
        const input = document.getElementById(`p${i + 1}NameInput`);
        playerNames.push(input?.value || defaultPlayerNames[i]);
    }
    
    pokerStartGame(numPlayers, buyIn, playerNames, sb, bb);
}

// Get next active player index (skips folded and all-in players for action)
function getNextActivePlayer(fromIndex) {
    if (pokerPlayers.length === 0) return 0;
    let nextIndex = (fromIndex + 1) % pokerPlayers.length;
    let attempts = 0;
    while ((pokerPlayers[nextIndex]?.folded || pokerPlayers[nextIndex]?.isAllIn) && attempts < pokerPlayers.length) {
        nextIndex = (nextIndex + 1) % pokerPlayers.length;
        attempts++;
    }
    return nextIndex;
}

// Get next non-folded player (for blind posting, includes all-in)
function getNextNonFoldedPlayer(fromIndex) {
    if (pokerPlayers.length === 0) return 0;
    let nextIndex = (fromIndex + 1) % pokerPlayers.length;
    let attempts = 0;
    while (pokerPlayers[nextIndex]?.folded && attempts < pokerPlayers.length) {
        nextIndex = (nextIndex + 1) % pokerPlayers.length;
        attempts++;
    }
    return nextIndex;
}

// Count active (non-folded) players
function countActivePlayers() {
    return pokerPlayers.filter(p => !p.folded).length;
}

// Count players who can still act (not folded, not all-in)
function countPlayersWhoCanAct() {
    return pokerPlayers.filter(p => !p.folded && !p.isAllIn).length;
}

// Get active players
function getActivePlayers() {
    return pokerPlayers.filter(p => !p.folded);
}

// Post blinds for the hand
function postBlinds() {
    if (pokerBlindsPosted) return;
    
    const numPlayers = pokerPlayers.length;
    if (numPlayers < 2) {
        console.error('Not enough players to post blinds');
        return;
    }
    
    savePokerHistory();
    playSound('push');
    let sbIndex, bbIndex;
    
    if (numPlayers === 2) {
        // Heads-up: Dealer posts SB, other posts BB
        sbIndex = pokerDealerIndex;
        bbIndex = getNextNonFoldedPlayer(sbIndex);
    } else {
        // Multi-way: SB is left of dealer, BB is left of SB
        sbIndex = getNextNonFoldedPlayer(pokerDealerIndex);
        bbIndex = getNextNonFoldedPlayer(sbIndex);
    }
    
    // Post small blind
    const sbAmount = Math.min(pokerSmallBlind, pokerPlayers[sbIndex].bankroll);
    pokerPlayers[sbIndex].bet = sbAmount;
    pokerPlayers[sbIndex].bankroll -= sbAmount;
    pokerPlayers[sbIndex].roundContribution = (pokerPlayers[sbIndex].roundContribution || 0) + sbAmount;
    if (pokerPlayers[sbIndex].bankroll === 0) {
        pokerPlayers[sbIndex].isAllIn = true;
    }
    
    // Post big blind
    const bbAmount = Math.min(pokerBigBlind, pokerPlayers[bbIndex].bankroll);
    pokerPlayers[bbIndex].bet = bbAmount;
    pokerPlayers[bbIndex].bankroll -= bbAmount;
    pokerPlayers[bbIndex].roundContribution = (pokerPlayers[bbIndex].roundContribution || 0) + bbAmount;
    if (pokerPlayers[bbIndex].bankroll === 0) {
        pokerPlayers[bbIndex].isAllIn = true;
    }
    
    pokerCurrentBet = Math.max(sbAmount, bbAmount);
    pokerBlindsPosted = true;
    
    // Reset action tracking - no one has acted yet
    pokerPlayers.forEach(p => p.acted = false);
    pokerLastAggressor = -1;
    pokerMinRaise = pokerBigBlind;
    
    // Set first to act
    if (numPlayers === 2) {
        // Heads-up: Dealer/SB acts first pre-flop
        pokerActivePlayerIndex = sbIndex;
    } else {
        // Multi-way: UTG (left of BB) acts first
        pokerActivePlayerIndex = getNextActivePlayer(bbIndex);
    }
    
    // Skip all-in players
    if (pokerPlayers[pokerActivePlayerIndex]?.isAllIn) {
        pokerActivePlayerIndex = getNextActivePlayer(pokerActivePlayerIndex);
    }
    
    savePokerToStorage();
    renderPoker();
}

// ==================== BETTING ACTIONS ====================

// FOLD - Give up the hand
function pokerFold() {
    if (pokerPhase !== 'betting') return;
    
    const player = pokerPlayers[pokerActivePlayerIndex];
    if (!player) return;
    
    savePokerHistory();
    playSound('lose');
    
    player.folded = true;
    player.stats.losses++;
    pokerLastAction = { player: player.name, action: 'fold' };
    logHandAction(player.name, 'folds');
    
    // Check if only one player remains
    if (countActivePlayers() === 1) {
        const winnerIndex = pokerPlayers.findIndex(p => !p.folded);
        awardPotToPlayer(winnerIndex, 'fold');
        return;
    }
    
    advanceAction();
}

// CHECK - Pass action (only when no bet to call)
function pokerCheck() {
    if (pokerPhase !== 'betting') return;
    
    const player = pokerPlayers[pokerActivePlayerIndex];
    if (!player) return;
    
    const toCall = pokerCurrentBet - player.bet;
    
    // Can only check if no bet to call
    if (toCall > 0) {
        return;
    }
    
    savePokerHistory();
    playSound('push');
    
    player.acted = true;
    pokerLastAction = { player: player.name, action: 'check' };
    logHandAction(player.name, 'checks');
    advanceAction();
}

// CALL - Match the current bet
function pokerCall() {
    if (pokerPhase !== 'betting') return;
    
    const player = pokerPlayers[pokerActivePlayerIndex];
    if (!player) return;
    
    const toCall = pokerCurrentBet - player.bet;
    
    if (toCall <= 0) {
        // Nothing to call, this is a check
        pokerCheck();
        return;
    }
    
    savePokerHistory();
    playSound('push');
    
    const actualCall = Math.min(toCall, player.bankroll);
    player.bankroll -= actualCall;
    player.bet += actualCall;
    player.roundContribution = (player.roundContribution || 0) + actualCall;
    player.acted = true;
    pokerLastAction = { player: player.name, action: 'call', amount: actualCall };
    logHandAction(player.name, 'calls', actualCall);
    
    if (player.bankroll === 0) {
        player.isAllIn = true;
    }
    
    advanceAction();
}

// RAISE/BET - Increase the bet
function pokerRaise(totalBet) {
    if (pokerPhase !== 'betting') return;
    
    const player = pokerPlayers[pokerActivePlayerIndex];
    if (!player) return;
    
    const currentPlayerBet = player.bet;
    const amountToAdd = totalBet - currentPlayerBet;
    
    // Validate raise amount
    if (!totalBet || totalBet <= 0) {
        return;
    }
    
    if (totalBet <= pokerCurrentBet) {
        return;
    }
    
    if (amountToAdd > player.bankroll) {
        return;
    }
    
    if (amountToAdd <= 0) {
        return;
    }
    
    // Check minimum raise (except for all-in)
    const raiseAmount = totalBet - pokerCurrentBet;
    if (amountToAdd < player.bankroll && raiseAmount < pokerMinRaise) {
        return;
    }
    
    savePokerHistory();
    playSound('push');
    
    player.bankroll -= amountToAdd;
    player.bet = totalBet;
    player.roundContribution = (player.roundContribution || 0) + amountToAdd;
    player.acted = true;
    pokerLastAction = { player: player.name, action: 'raise', amount: totalBet };
    logHandAction(player.name, pokerCurrentBet === 0 ? 'bets' : 'raises to', totalBet);
    
    if (player.bankroll === 0) {
        player.isAllIn = true;
    }
    
    // Update betting state
    if (totalBet > pokerCurrentBet) {
        // This is a raise - reset other players' acted flags
        pokerPlayers.forEach((p, i) => {
            if (i !== pokerActivePlayerIndex && !p.folded && !p.isAllIn) {
                p.acted = false;
            }
        });
        pokerLastAggressor = pokerActivePlayerIndex;
        pokerMinRaise = Math.max(pokerMinRaise, totalBet - pokerCurrentBet);
        pokerCurrentBet = totalBet;
    }
    
    advanceAction();
}

// ALL-IN - Bet all remaining chips
function pokerAllIn() {
    if (pokerPhase !== 'betting') return;
    
    const player = pokerPlayers[pokerActivePlayerIndex];
    if (!player) return;
    
    const totalBet = player.bet + player.bankroll;
    
    savePokerHistory();
    playSound('push');
    
    // If this is a raise, reset others' acted flags
    if (totalBet > pokerCurrentBet) {
        pokerPlayers.forEach((p, i) => {
            if (i !== pokerActivePlayerIndex && !p.folded && !p.isAllIn) {
                p.acted = false;
            }
        });
        pokerLastAggressor = pokerActivePlayerIndex;
        const raiseAmount = totalBet - pokerCurrentBet;
        if (raiseAmount >= pokerMinRaise) {
            pokerMinRaise = raiseAmount;
        }
        pokerCurrentBet = totalBet;
    }
    
    const allInAmount = player.bankroll; // What they're adding to the pot
    player.roundContribution = (player.roundContribution || 0) + allInAmount;
    player.bet = totalBet;
    player.bankroll = 0;
    player.acted = true;
    player.isAllIn = true;
    pokerLastAction = { player: player.name, action: 'allin', amount: totalBet };
    logHandAction(player.name, 'ALL-IN', totalBet);
    
    advanceAction();
}

// Advance action to next player or next street
function advanceAction() {
    // Check if betting round is complete
    if (isBettingRoundComplete()) {
        // Check if only one player remains
        if (countActivePlayers() === 1) {
            const winnerIndex = pokerPlayers.findIndex(p => !p.folded);
            awardPotToPlayer(winnerIndex, 'fold');
            return;
        }
        
        // Check if everyone is all-in (or only one can act)
        if (countPlayersWhoCanAct() <= 1) {
            // Run out remaining streets automatically
            runOutBoard();
            return;
        }
        
        // Move to next street
        if (pokerStreet === 'river') {
            goToShowdown();
        } else {
            nextStreet();
        }
    } else {
        // Find next player to act
        pokerActivePlayerIndex = getNextActivePlayer(pokerActivePlayerIndex);
        savePokerToStorage();
        renderPoker();
    }
}

// Check if betting round is complete
function isBettingRoundComplete() {
    const activePlayers = getActivePlayers();
    
    if (activePlayers.length <= 1) return true;
    
    for (const player of activePlayers) {
        // Skip all-in players
        if (player.isAllIn) continue;
        // Player hasn't acted
        if (!player.acted) return false;
        // Player hasn't matched bet (shouldn't happen if logic is correct)
        if (player.bet < pokerCurrentBet && player.bankroll > 0) return false;
    }
    
    return true;
}

// Move to next street
function nextStreet() {
    savePokerHistory();
    playSound('push');
    
    // Move bets to pot
    let totalBets = 0;
    pokerPlayers.forEach(p => {
        totalBets += p.bet;
        p.bet = 0;
        p.acted = false;
    });
    pokerPot += totalBets;
    pokerCurrentBet = 0;
    pokerMinRaise = pokerBigBlind;
    pokerLastAggressor = -1;
    
    // Advance street
    const streets = ['preflop', 'flop', 'turn', 'river'];
    const currentIndex = streets.indexOf(pokerStreet);
    if (currentIndex < streets.length - 1) {
        pokerStreet = streets[currentIndex + 1];
    }
    
    // Post-flop action starts left of dealer
    pokerActivePlayerIndex = getNextActivePlayer(pokerDealerIndex);
    
    // Trigger burn card animation
    pokerBurnCardPending = true;
    pokerBurnCardStreet = pokerStreet;
    
    savePokerToStorage();
    renderPoker();
}

// Acknowledge burn card and continue
function acknowledgeBurnCard() {
    playSound('deal');
    pokerBurnCardPending = false;
    pokerBurnCardStreet = '';
    
    // Check if everyone is all-in (or only one can act) - if so, continue running out
    if (countPlayersWhoCanAct() <= 1 && pokerPhase === 'betting') {
        if (pokerStreet === 'river') {
            goToShowdown();
        } else {
            // Continue running out the board to next street
            runOutBoard();
        }
    } else {
        savePokerToStorage();
        renderPoker();
    }
}

// Run out the board when everyone is all-in
// Instead of skipping to river, we step through each street with burn prompts
function runOutBoard() {
    // Move all bets to pot
    let totalBets = 0;
    pokerPlayers.forEach(p => {
        totalBets += p.bet;
        p.bet = 0;
        p.acted = false;
    });
    pokerPot += totalBets;
    pokerCurrentBet = 0;
    pokerMinRaise = pokerBigBlind;
    
    // Determine next street and trigger burn card prompt
    const streets = ['preflop', 'flop', 'turn', 'river'];
    const currentIndex = streets.indexOf(pokerStreet);
    
    if (currentIndex < streets.length - 1) {
        // Advance to next street
        pokerStreet = streets[currentIndex + 1];
        // Trigger burn card animation so user deals the cards
        pokerBurnCardPending = true;
        pokerBurnCardStreet = pokerStreet;
        savePokerToStorage();
        renderPoker();
    } else {
        // Already at river, go to showdown
        goToShowdown();
    }
}

// Go to showdown
function goToShowdown() {
    // Move any remaining bets to pot
    let totalBets = 0;
    pokerPlayers.forEach(p => {
        totalBets += p.bet;
        p.bet = 0;
    });
    pokerPot += totalBets;
    
    pokerPhase = 'showdown';
    savePokerToStorage();
    renderPoker();
}

// Award pot to a specific player
function awardPotToPlayer(winnerIndex, reason = 'win') {
    // Safety check
    if (winnerIndex < 0 || winnerIndex >= pokerPlayers.length || !pokerPlayers[winnerIndex]) {
        console.error('Invalid winner index:', winnerIndex);
        return;
    }
    
    const totalPot = pokerPot + pokerPlayers.reduce((sum, p) => sum + (p.bet || 0), 0);
    const winnerContribution = pokerPlayers[winnerIndex].roundContribution || 0;
    const profit = totalPot - winnerContribution;
    
    pokerPlayers[winnerIndex].bankroll += totalPot;
    pokerPlayers[winnerIndex].stats.handsWon++;
    
    // Play appropriate sound
    if (reason === 'fold') {
        playSound('push');
    } else {
        playSound('win');
    }
    
    // Mark non-winners as losses (if they didn't fold already)
    pokerPlayers.forEach((p, i) => {
        if (i !== winnerIndex && !p.folded) {
            p.stats.handsLost++;
        }
        p.bet = 0;
    });
    
    pokerPot = 0;
    pokerPhase = 'result';
    
    const winnerName = pokerPlayers[winnerIndex].name;
    if (reason === 'fold') {
        pokerLastResult = {
            message: `${winnerName} wins +$${profit}! (Others folded)`,
            winner: winnerIndex
        };
    } else {
        pokerLastResult = {
            message: `${winnerName} wins +$${profit}!`,
            winner: winnerIndex
        };
    }
    
    savePokerToStorage();
    renderPoker();
}

// Declare winner at showdown
function pokerDeclareWinner(winnerIndex) {
    if (pokerPhase !== 'showdown') return;
    
    savePokerHistory();
    
    if (winnerIndex === 'tie') {
        // Split pot among active players
        const activePlayers = getActivePlayers();
        if (activePlayers.length === 0) {
            console.error('No active players for split pot');
            return;
        }
        const totalPot = pokerPot + pokerPlayers.reduce((sum, p) => sum + (p.bet || 0), 0);
        const share = Math.floor(totalPot / activePlayers.length);
        let remainder = totalPot % activePlayers.length;
        
        // Calculate average contribution for profit display
        const avgContribution = Math.floor(activePlayers.reduce((sum, p) => sum + (p.roundContribution || 0), 0) / activePlayers.length);
        const profitPerPlayer = share - avgContribution;
        
        pokerPlayers.forEach(p => {
            if (!p.folded) {
                p.bankroll += share + (remainder > 0 ? 1 : 0);
                if (remainder > 0) remainder--;
                p.stats.handsTied++;
            }
            p.bet = 0;
        });
        
        playSound('push');
        pokerLastResult = {
            message: `Split Pot! ${profitPerPlayer >= 0 ? '+' : ''}$${profitPerPlayer} each`,
            winner: 'tie'
        };
        pokerPot = 0;
        pokerPhase = 'result';
    } else {
        playSound('win');
        awardPotToPlayer(winnerIndex);
        return;
    }
    
    savePokerToStorage();
    renderPoker();
}

// Start new hand
function newPokerRound() {
    playSound('push');
    
    // Remove players with no chips
    const playersWithChips = pokerPlayers.filter(p => p.bankroll > 0);
    const eliminatedPlayers = pokerPlayers.filter(p => p.bankroll <= 0);
    
    if (playersWithChips.length <= 1) {
        if (playersWithChips.length === 1) {
            // Update series stats for the winner
            updateSeriesStats(playersWithChips[0].name);
            pokerLastResult = {
                message: `${playersWithChips[0].name} WINS THE GAME!`,
                winner: 'game'
            };
        }
        pokerPhase = 'result';
        savePokerToStorage();
        renderPoker();
        return;
    }
    
    // Show elimination message if anyone was eliminated
    if (eliminatedPlayers.length > 0) {
        const names = eliminatedPlayers.map(p => p.name).join(', ');
        pokerLastResult = {
            message: `${names} eliminated. ${playersWithChips.length} players remain.`,
            winner: 'elimination'
        };
    } else {
        pokerLastResult = null;
    }
    
    // Find who the current dealer is before filtering
    const currentDealer = pokerPlayers[pokerDealerIndex];
    
    pokerPlayers = playersWithChips;
    
    // Reset for new hand
    pokerPhase = 'betting';
    pokerPlayers.forEach(p => {
        p.bet = 0;
        p.roundContribution = 0; // Reset contribution tracking for new hand
        p.acted = false;
        p.folded = false;
        p.isAllIn = false;
    });
    pokerRound++;
    if (!pokerLastResult) pokerLastResult = null; // Keep elimination message if set
    pokerHistory = [];
    pokerStreet = 'preflop';
    pokerPot = 0;
    pokerCurrentBet = 0;
    pokerBlindsPosted = false;
    pokerLastAction = null;
    pokerHandLog = []; // Clear hand action log
    
    // Move dealer button - find the current dealer in new array, then move to next
    let newDealerIndex = pokerPlayers.indexOf(currentDealer);
    if (newDealerIndex === -1) {
        // Dealer was eliminated, find next valid position
        newDealerIndex = pokerDealerIndex % pokerPlayers.length;
    }
    // Move to next player
    pokerDealerIndex = (newDealerIndex + 1) % pokerPlayers.length;
    
    pokerMinRaise = pokerBigBlind;
    pokerLastAggressor = -1;
    
    // Auto-post blinds
    postBlinds();
    
    savePokerToStorage();
    renderPoker();
}

// Reset entire game
function resetPokerGame() {
    playSound('push');
    pokerPlayers = [];
    pokerPot = 0;
    pokerPhase = 'setup';
    pokerRound = 0;
    pokerGameStarted = false;
    pokerActivePlayerIndex = 0;
    pokerLastResult = null;
    pokerHistory = [];
    pokerHandLog = [];
    pokerStreet = 'preflop';
    pokerDealerIndex = 0;
    pokerCurrentBet = 0;
    pokerBlindsPosted = false;
    pokerBurnCardPending = false;
    pokerBurnCardStreet = '';
    savePokerToStorage();
    renderPoker();
}

// Rematch - start new game with same players and settings
function pokerRematch() {
    playSound('push');
    
    // Get player names from current game
    const playerNames = pokerPlayers.map(p => p.name);
    const numPlayers = playerNames.length;
    
    // Calculate original buy-in from first player's totalBuyIn (or use a default)
    const buyIn = pokerPlayers[0]?.totalBuyIn || 100;
    
    // Reset players with same names but fresh chips
    pokerPlayers = [];
    for (let i = 0; i < numPlayers; i++) {
        pokerPlayers.push(createPlayer(playerNames[i], buyIn));
    }
    
    // Keep blinds the same
    pokerGameStarted = true;
    pokerPhase = 'betting';
    pokerRound = 1;
    pokerDealerIndex = 0;
    pokerStreet = 'preflop';
    pokerPot = 0;
    pokerHistory = [];
    pokerLastResult = null;
    pokerMinRaise = pokerBigBlind;
    pokerCurrentBet = 0;
    pokerBlindsPosted = false;
    pokerHandLog = [];
    
    // Auto-post blinds
    postBlinds();
    
    savePokerToStorage();
    renderPoker();
}

// Clear all series stats
function clearSeriesStats() {
    if (confirm('Are you sure you want to reset all series stats? This cannot be undone.')) {
        pokerSeriesStats = {};
        savePokerToStorage();
        renderPoker();
    }
}

// Re-buy for a player (add more chips)
function pokerRebuy(playerIndex, amount) {
    if (playerIndex < 0 || playerIndex >= pokerPlayers.length) return;
    if (pokerPhase === 'betting' && pokerPlayers[playerIndex].bet > 0) {
        alert('Cannot rebuy during an active betting round with chips in the pot.');
        return;
    }
    
    playSound('chip');
    pokerPlayers[playerIndex].bankroll += amount;
    pokerPlayers[playerIndex].totalBuyIn += amount;
    savePokerToStorage();
    renderPoker();
}

// Log action to hand history
function logHandAction(player, action, amount = null, street = pokerStreet) {
    const entry = {
        player: player,
        action: action,
        amount: amount,
        street: street,
        time: Date.now()
    };
    pokerHandLog.push(entry);
    // Keep only last 50 actions
    if (pokerHandLog.length > 50) pokerHandLog.shift();
}

// Format hand log for display
function formatHandLog() {
    if (pokerHandLog.length === 0) return '';
    
    // Group by street
    const byStreet = {};
    pokerHandLog.forEach(entry => {
        if (!byStreet[entry.street]) byStreet[entry.street] = [];
        byStreet[entry.street].push(entry);
    });
    
    const streetOrder = ['preflop', 'flop', 'turn', 'river'];
    let html = '';
    
    streetOrder.forEach(street => {
        if (byStreet[street]) {
            const streetName = street.charAt(0).toUpperCase() + street.slice(1);
            html += `<div class="hand-log-street">${streetName}:</div>`;
            byStreet[street].forEach(entry => {
                const actionText = entry.amount ? `${entry.action} $${entry.amount}` : entry.action;
                html += `<div class="hand-log-entry"><span class="log-player">${entry.player}</span> ${actionText}</div>`;
            });
        }
    });
    
    return html;
}

// Get street display name
function getStreetName(street) {
    const names = {
        'preflop': '🂠 Pre-Flop',
        'flop': 'FLOP',
        'turn': 'TURN',
        'river': 'RIVER'
    };
    return names[street] || street;
}

// Get previous street
function getStreetBefore(street) {
    const order = ['preflop', 'flop', 'turn', 'river'];
    const idx = order.indexOf(street);
    return idx > 0 ? order[idx - 1] : 'preflop';
}

// Update player name inputs based on number of players
// Calculate pot odds for current player
function getPotOdds() {
    const player = pokerPlayers[pokerActivePlayerIndex];
    if (!player) return null;
    
    const toCall = Math.max(0, pokerCurrentBet - player.bet);
    if (toCall === 0) return null; // No pot odds if nothing to call
    
    const pot = pokerPot + pokerPlayers.reduce((sum, p) => sum + p.bet, 0);
    const potAfterCall = pot + toCall;
    
    // Pot odds as ratio (e.g., "3:1" means pot is 3x the call)
    const ratio = potAfterCall / toCall;
    
    // As percentage needed to break even
    const percentage = (toCall / potAfterCall * 100).toFixed(1);
    
    return {
        ratio: ratio.toFixed(1),
        percentage: percentage,
        toCall: toCall,
        pot: pot
    };
}

function updatePlayerInputs() {
    const numPlayers = parseInt(document.getElementById('numPlayersInput')?.value) || 2;
    const container = document.getElementById('playerNamesContainer');
    if (!container) return;
    
    let html = '';
    for (let i = 0; i < numPlayers; i++) {
        html += `
            <div style="text-align: center;">
                <label style="color: #d4af37; display: block; margin-bottom: 5px;">Player ${i + 1}</label>
                <input type="text" id="p${i + 1}NameInput" placeholder="Player ${i + 1}" value="${defaultPlayerNames[i]}" 
                    style="padding: 10px; border-radius: 8px; border: 2px solid #d4af37; background: #1a1a1a; color: white; font-size: 0.9em; width: 110px; text-align: center;">
            </div>
        `;
    }
    container.innerHTML = html;
}

// Calculate valid raise amounts
function getValidRaises() {
    const player = pokerPlayers[pokerActivePlayerIndex];
    if (!player) return [];
    
    const currentPlayerBet = player.bet;
    const toCall = pokerCurrentBet - currentPlayerBet;
    const minRaiseTotal = pokerCurrentBet + pokerMinRaise;
    const maxRaise = currentPlayerBet + player.bankroll;
    
    const raises = [];
    const addedAmounts = new Set();
    
    const addRaise = (label, amount, chipColor) => {
        amount = Math.floor(amount);
        if (amount >= minRaiseTotal && amount <= maxRaise && !addedAmounts.has(amount) && amount > 0) {
            addedAmounts.add(amount);
            raises.push({ label, amount, chipColor: chipColor || 'green' });
        }
    };
    
    if (maxRaise <= pokerCurrentBet) return [];
    
    const pot = pokerPot + pokerPlayers.reduce((sum, p) => sum + p.bet, 0);
    
    // Min raise
    addRaise('Min', minRaiseTotal, 'white');
    
    if (pokerCurrentBet > 0) {
        // Facing a bet - multipliers
        addRaise('2×', pokerCurrentBet * 2, 'red');
        addRaise('3×', pokerCurrentBet * 3, 'blue');
        addRaise('4×', pokerCurrentBet * 4, 'green');
        addRaise('5×', pokerCurrentBet * 5, 'orange');
        
        // Pot-sized raise
        const potRaise = pokerCurrentBet + pot + toCall;
        addRaise('Pot', potRaise, 'gold');
    } else {
        // Opening bet - pot fractions
        if (pot > 0) {
            addRaise('¼ Pot', Math.floor(pot / 4), 'white');
            addRaise('⅓ Pot', Math.floor(pot / 3), 'white');
            addRaise('½ Pot', Math.floor(pot / 2), 'red');
            addRaise('⅔ Pot', Math.floor(pot * 2 / 3), 'blue');
            addRaise('¾ Pot', Math.floor(pot * 3 / 4), 'blue');
            addRaise('Pot', pot, 'gold');
        }
        
        // BB multiples for preflop - just show dollar amounts
        if (pokerStreet === 'preflop') {
            addRaise('$' + (pokerBigBlind * 2), pokerBigBlind * 2, 'white');
            addRaise('$' + (pokerBigBlind * 3), pokerBigBlind * 3, 'red');
            addRaise('$' + (pokerBigBlind * 4), pokerBigBlind * 4, 'blue');
            addRaise('$' + (pokerBigBlind * 5), pokerBigBlind * 5, 'green');
            addRaise('$' + (pokerBigBlind * 10), pokerBigBlind * 10, 'black');
        }
        
        // Dynamic fixed amounts based on big blind
        const dynamicAmounts = [
            pokerBigBlind,
            pokerBigBlind * 2,
            pokerBigBlind * 4,
            pokerBigBlind * 5,
            pokerBigBlind * 10,
            pokerBigBlind * 20
        ];
        dynamicAmounts.forEach(amt => {
            if (amt >= minRaiseTotal && amt <= maxRaise) {
                const color = amt <= pokerBigBlind * 2 ? 'white' : amt <= pokerBigBlind * 5 ? 'red' : amt <= pokerBigBlind * 10 ? 'blue' : 'black';
                addRaise('$' + amt, amt, color);
            }
        });
    }
    
    raises.sort((a, b) => a.amount - b.amount);
    // Remove duplicates and return
    return raises;
}

// Main render function for poker
function renderPoker() {
    const container = document.getElementById('pokerContent');
    if (!container) return;
    
    // Setup screen
    if (!pokerGameStarted) {
        container.innerHTML = `
            <div class="poker-container">
                <div class="poker-table">
                    <div class="poker-new-game-section">
                        <div class="poker-message" style="font-size: 1.8em;">Texas Hold'em</div>
                        <p style="color: #aaa; margin: 15px 0 20px;">Chip tracker with strict rules</p>
                        
                        <div style="margin-bottom: 20px;">
                            <label style="color: #d4af37; display: block; margin-bottom: 8px;">Number of Players</label>
                            <select id="numPlayersInput" onchange="updatePlayerInputs()" 
                                style="padding: 12px 20px; border-radius: 8px; border: 2px solid #d4af37; background: #1a1a1a; color: white; font-size: 1.1em; cursor: pointer;">
                                <option value="2">2 Players (Heads-Up)</option>
                                <option value="3">3 Players</option>
                                <option value="4">4 Players</option>
                                <option value="5">5 Players</option>
                                <option value="6">6 Players</option>
                                <option value="7">7 Players</option>
                                <option value="8">8 Players</option>
                            </select>
                        </div>
                        
                        <div id="playerNamesContainer" style="display: flex; gap: 15px; justify-content: center; margin-bottom: 20px; flex-wrap: wrap;">
                            <div style="text-align: center;">
                                <label style="color: #d4af37; display: block; margin-bottom: 5px;">Player 1</label>
                                <input type="text" id="p1NameInput" placeholder="Player 1" value="Player 1" 
                                    style="padding: 10px; border-radius: 8px; border: 2px solid #d4af37; background: #1a1a1a; color: white; font-size: 0.9em; width: 110px; text-align: center;">
                            </div>
                            <div style="text-align: center;">
                                <label style="color: #d4af37; display: block; margin-bottom: 5px;">Player 2</label>
                                <input type="text" id="p2NameInput" placeholder="Player 2" value="Player 2"
                                    style="padding: 10px; border-radius: 8px; border: 2px solid #d4af37; background: #1a1a1a; color: white; font-size: 0.9em; width: 110px; text-align: center;">
                            </div>
                        </div>
                        
                        <div style="display: flex; gap: 15px; justify-content: center; margin-bottom: 20px; flex-wrap: wrap;">
                            <div style="text-align: center;">
                                <label style="color: #888; display: block; margin-bottom: 5px; font-size: 0.9em;">Small Blind</label>
                                <input type="number" id="sbInput" value="${pokerSmallBlind}" min="1"
                                    style="padding: 10px; border-radius: 8px; border: 2px solid #555; background: #1a1a1a; color: white; font-size: 1em; width: 80px; text-align: center;">
                            </div>
                            <div style="text-align: center;">
                                <label style="color: #888; display: block; margin-bottom: 5px; font-size: 0.9em;">Big Blind</label>
                                <input type="number" id="bbInput" value="${pokerBigBlind}" min="1"
                                    style="padding: 10px; border-radius: 8px; border: 2px solid #555; background: #1a1a1a; color: white; font-size: 1em; width: 80px; text-align: center;">
                            </div>
                        </div>
                        
                        <p style="color: #aaa; margin-bottom: 10px;">Starting chips per player:</p>
                        <div class="poker-buyin-buttons" style="flex-wrap: wrap;">
                            <button type="button" class="poker-buyin-btn" onclick="startPokerWithInputs(20)">$20</button>
                            <button type="button" class="poker-buyin-btn" onclick="startPokerWithInputs(50)">$50</button>
                            <button type="button" class="poker-buyin-btn" onclick="startPokerWithInputs(100)">$100</button>
                            <button type="button" class="poker-buyin-btn" onclick="startPokerWithInputs(200)">$200</button>
                            <button type="button" class="poker-buyin-btn" onclick="startPokerWithInputs(500)">$500</button>
                            <button type="button" class="poker-buyin-btn" onclick="startPokerWithInputs(1000)">$1K</button>
                            <button type="button" class="poker-buyin-btn" onclick="startPokerWithInputs(2000)">$2K</button>
                            <button type="button" class="poker-buyin-btn" onclick="startPokerWithInputs(5000)">$5K</button>
                        </div>
                        <div style="margin-top: 15px; display: flex; align-items: center; justify-content: center; gap: 10px;">
                            <span style="color: #888;">Custom:</span>
                            <input type="number" id="customStartingChips" placeholder="Amount" min="1" 
                                style="padding: 10px; border-radius: 8px; border: 2px solid #555; background: #1a1a1a; color: white; font-size: 1em; width: 100px; text-align: center;">
                            <button type="button" class="poker-buyin-btn" onclick="const v=parseInt(document.getElementById('customStartingChips').value);if(v>0)startPokerWithInputs(v);" style="padding: 10px 20px;">Start</button>
                        </div>
                        
                        <div style="margin-top: 30px; padding: 15px; background: #1a1a1a; border-radius: 10px; max-width: 500px; margin-left: auto; margin-right: auto;">
                            <div style="color: #d4af37; font-weight: bold; margin-bottom: 10px;">RULES ENFORCED</div>
                            <ul style="color: #888; text-align: left; font-size: 0.85em; margin: 0; padding-left: 20px;">
                                <li>Blinds auto-posted each hand</li>
                                <li>Action follows clockwise order</li>
                                <li>Minimum raise = previous raise size</li>
                                <li>No acting out of turn</li>
                                <li>Valid actions: Fold, Check, Call, Raise, All-In</li>
                            </ul>
                        </div>
                        
                        ${Object.keys(pokerSeriesStats).length > 0 ? `
                        <div style="margin-top: 20px; padding: 15px; background: #1a1a1a; border-radius: 10px; max-width: 500px; margin-left: auto; margin-right: auto;">
                            <div style="color: #4ade80; font-weight: bold; margin-bottom: 10px;">SERIES LEADERBOARD</div>
                            <div style="display: flex; flex-wrap: wrap; gap: 10px; justify-content: center;">
                                ${Object.entries(pokerSeriesStats)
                                    .sort((a, b) => (b[1].seriesWins - b[1].seriesLosses) - (a[1].seriesWins - a[1].seriesLosses))
                                    .map(([name, stats]) => `
                                    <div style="background: #2a2a2a; padding: 8px 15px; border-radius: 8px; text-align: center;">
                                        <div style="color: #fff; font-size: 0.9em;">${name}</div>
                                        <div style="color: #4ade80; font-size: 0.85em; font-weight: bold;">${stats.seriesWins}W - ${stats.seriesLosses}L</div>
                                    </div>
                                `).join('')}
                            </div>
                            <button type="button" onclick="clearSeriesStats()" style="margin-top: 10px; padding: 8px 16px; border-radius: 6px; border: 1px solid #666; background: transparent; color: #888; cursor: pointer; font-size: 0.8em;">Reset Stats</button>
                        </div>
                        ` : ''}
                    </div>
                </div>
            </div>
        `;
        return;
    }
    
    // Game over screen
    const playersWithChips = pokerPlayers.filter(p => p.bankroll > 0 || p.bet > 0);
    if (playersWithChips.length <= 1 && pokerPhase === 'result' && pokerLastResult?.winner === 'game') {
        const winner = playersWithChips[0] || pokerPlayers[0];
        container.innerHTML = `
            <div class="poker-container">
                <div class="poker-table">
                    <div class="poker-new-game-section">
                        <div class="poker-message" style="color: #4ade80; font-size: 2em;">${winner?.name || 'Winner'} WINS!</div>
                        <p style="color: #aaa; margin: 20px 0;">Game over after ${pokerRound} hands</p>
                        <div class="poker-stats-bar" style="max-width: 600px; margin: 20px auto; flex-wrap: wrap; gap: 15px;">
                            ${pokerPlayers.map(p => {
                                const ss = pokerSeriesStats[p.name] || { seriesWins: 0, seriesLosses: 0 };
                                return `
                                <div class="poker-stat" style="min-width: 100px;">
                                    <div class="poker-stat-label">${p.name}</div>
                                    <div class="poker-stat-value" style="color: #4ade80;">${ss.seriesWins}W - ${ss.seriesLosses}L</div>
                                    <div style="font-size: 0.7em; color: #888;">(Games)</div>
                                </div>
                            `;
                            }).join('')}
                        </div>
                        <div style="display: flex; gap: 15px; justify-content: center; flex-wrap: wrap;">
                            <button type="button" class="poker-buyin-btn" onclick="pokerRematch()" style="background: linear-gradient(135deg, #4ade80, #22c55e); color: #000;">Rematch</button>
                            <button type="button" class="poker-buyin-btn" onclick="resetPokerGame()" style="background: #333;">New Game</button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        return;
    }
    
    // Get current player and calculate values
    const currentPlayer = pokerPlayers[pokerActivePlayerIndex] || { name: 'Unknown', bet: 0, bankroll: 0 };
    const toCall = Math.max(0, pokerCurrentBet - (currentPlayer.bet || 0));
    const totalInPlay = pokerPot + pokerPlayers.reduce((sum, p) => sum + (p.bet || 0), 0);
    const activePlayers = getActivePlayers();
    
    // Get blind positions (with safety check)
    let sbIndex = 0, bbIndex = 1;
    if (pokerPlayers.length >= 2) {
        if (pokerPlayers.length === 2) {
            sbIndex = pokerDealerIndex;
            bbIndex = (pokerDealerIndex + 1) % pokerPlayers.length;
        } else {
            sbIndex = (pokerDealerIndex + 1) % pokerPlayers.length;
            bbIndex = (pokerDealerIndex + 2) % pokerPlayers.length;
        }
    }
    
    // Get valid raises for current player
    const validRaises = getValidRaises();
    
    // Check if this is BB option (BB can check or raise pre-flop when action comes back)
    const isBBOption = pokerStreet === 'preflop' && 
                       pokerActivePlayerIndex === bbIndex && 
                       currentPlayer.bet === pokerCurrentBet && 
                       toCall === 0;
    
    // Phase display text
    const phaseDisplay = pokerPhase === 'betting' ? `${currentPlayer.name}'s Turn` :
                         pokerPhase === 'showdown' ? 'Showdown' :
                         pokerPhase === 'result' ? 'Hand Complete' : '';
    
    container.innerHTML = `
        <div class="poker-container">
            <!-- Top Status Bar -->
            <div class="poker-status-bar">
                <div style="display: flex; align-items: center; gap: 15px; flex-wrap: wrap;">
                    <div class="poker-round-info">Hand #${pokerRound}</div>
                    <div class="poker-street-badge">${getStreetName(pokerStreet)}</div>
                    ${phaseDisplay ? `<div style="color: #4ade80; font-weight: 600;">${phaseDisplay}</div>` : ''}
                </div>
                <div style="display: flex; gap: 10px; align-items: center;">
                    <div style="color: #888; font-size: 0.85em;">${pokerPlayers.length}P | $${pokerSmallBlind}/$${pokerBigBlind} | In Play: $${getTotalChipsInPlay()}</div>
                    <button type="button" class="poker-action-btn btn-check" onclick="pokerUndo()" style="padding: 8px 12px; font-size: 0.8em;" ${pokerHistory.length === 0 ? 'disabled' : ''}>UNDO</button>
                    <button type="button" class="poker-action-btn btn-fold" onclick="resetPokerGame()" style="padding: 8px 12px; font-size: 0.8em;">End Game</button>
                </div>
            </div>
            
            <div class="poker-table">
                ${pokerLastResult ? `
                <div class="poker-result-banner ${pokerLastResult.winner === 'tie' ? 'tie' : pokerLastResult.winner === 'elimination' ? 'elimination' : 'win'}" style="${pokerLastResult.winner === 'elimination' ? 'background: rgba(239, 68, 68, 0.2); border-color: #ef4444; color: #ef4444;' : ''}">
                    ${pokerLastResult.message}
                </div>
                ` : ''}
                
                <!-- Burn & Deal Instruction -->
                ${pokerBurnCardPending ? `
                <div class="burn-deal-box">
                    ${countPlayersWhoCanAct() <= 1 && pokerPhase === 'betting' ? `<div class="allIn-runout-label">ALL-IN RUNOUT</div>` : ''}
                    <div class="burn-deal-content">
                        <div class="burn-deal-step">
                            <span class="step-icon">B</span>
                            <span class="step-text">BURN 1</span>
                        </div>
                        <div class="burn-deal-arrow">→</div>
                        <div class="burn-deal-step">
                            <span class="step-icon">D</span>
                            <span class="step-text">DEAL ${pokerBurnCardStreet === 'flop' ? '3' : '1'}</span>
                        </div>
                    </div>
                    <div class="burn-deal-street">${pokerBurnCardStreet.toUpperCase()}</div>
                    <button type="button" class="burn-deal-btn" onclick="acknowledgeBurnCard()">Done</button>
                </div>
                ` : ''}
                
                <!-- Community Cards Visual -->
                <div class="poker-community-board">
                    <div class="poker-board-label">BOARD</div>
                    <div class="poker-cards-row">
                        ${(() => {
                            const streetCards = {
                                'preflop': 0,
                                'flop': 3,
                                'turn': 4,
                                'river': 5
                            };
                            const revealedCount = pokerBurnCardPending ? streetCards[getStreetBefore(pokerStreet)] || 0 : streetCards[pokerStreet] || 0;
                            let cards = '';
                            for (let i = 0; i < 5; i++) {
                                if (i < revealedCount) {
                                    cards += `<div class="poker-card-slot dealt">
                                        <span class="slot-number">${i + 1}</span>
                                    </div>`;
                                } else {
                                    cards += `<div class="poker-card-slot empty">
                                        <span class="slot-number">${i + 1}</span>
                                    </div>`;
                                }
                            }
                            return cards;
                        })()}
                    </div>
                    <div class="poker-street-indicator-simple">
                        <span class="street-dot ${pokerStreet === 'preflop' ? 'active' : 'done'}"></span>
                        <span class="street-dot ${pokerStreet === 'flop' ? 'active' : ['turn', 'river'].includes(pokerStreet) ? 'done' : ''}"></span>
                        <span class="street-dot ${pokerStreet === 'turn' ? 'active' : pokerStreet === 'river' ? 'done' : ''}"></span>
                        <span class="street-dot ${pokerStreet === 'river' ? 'active' : ''}"></span>
                    </div>
                </div>
                
                <!-- Central Pot Display -->
                <div class="poker-pot-simple">
                    <span class="pot-label">POT</span>
                    <span class="pot-amount">$${totalInPlay}</span>
                </div>
                
                <!-- Player Grid -->
                <div class="poker-player-grid">
                    ${(() => {
                        const chipLeader = getChipLeader();
                        return pokerPlayers.map((player, index) => {
                            const isActive = index === pokerActivePlayerIndex && pokerPhase === 'betting';
                            const isChipLeader = chipLeader && player === chipLeader && pokerPlayers.length > 2;
                            const positionBadge = index === pokerDealerIndex ? 'D' : 
                                                 index === sbIndex ? 'SB' : 
                                                 index === bbIndex ? 'BB' : '';
                            return `
                            <div class="poker-player-box ${isActive ? 'active' : ''} ${player.folded ? 'folded' : ''} ${player.isAllIn ? 'allin' : ''}">
                                <div class="poker-player-header">
                                    <span class="poker-player-name">${player.name}</span>
                                    ${positionBadge ? `<span class="poker-position-badge ${positionBadge}">${positionBadge}</span>` : ''}
                                </div>
                                <div class="poker-bankroll">$${player.bankroll}</div>
                                ${player.folded ? '<div class="player-chip-status folded">FOLD</div>' :
                                  player.isAllIn ? '<div class="player-chip-status allin">ALL-IN $' + player.bet + '</div>' :
                                  player.bet > 0 ? `<div class="player-chip-status betting">$${player.bet}</div>` : 
                                  ''}
                            </div>
                        `}).join('');
                    })()}
                </div>
            </div>
            
            <!-- Controls -->
            <div class="poker-controls">
                ${pokerPhase === 'result' ? `
                    <!-- Result Phase -->
                    <div class="poker-action-buttons">
                        <button type="button" class="poker-action-btn btn-deal" onclick="newPokerRound()" style="padding: 18px 50px; font-size: 1.2em;">
                            Deal Next Hand
                        </button>
                    </div>
                ` : pokerPhase === 'showdown' ? `
                    <!-- Showdown Phase -->
                    <div class="poker-betting-header">
                        <div class="poker-phase-label" style="color: #d4af37; font-size: 1.3em;">SHOWDOWN</div>
                        <div style="color: #888; margin-top: 5px;">Who has the best hand?</div>
                    </div>
                    <div class="poker-winner-actions" style="margin-top: 15px;">
                        ${activePlayers.length > 0 ? `
                        <div class="poker-action-buttons" style="flex-wrap: wrap; gap: 10px;">
                            ${activePlayers.map(p => {
                                const actualIndex = pokerPlayers.indexOf(p);
                                return `<button type="button" class="poker-action-btn btn-deal" onclick="pokerDeclareWinner(${actualIndex})" style="padding: 15px 25px; font-size: 1.1em;">${p.name} Wins</button>`;
                            }).join('')}
                        </div>
                        <div style="margin-top: 15px;">
                            <button type="button" class="poker-action-btn btn-call" onclick="pokerDeclareWinner('tie')" style="padding: 12px 30px;">Split Pot</button>
                        </div>
                        ` : `<div style="color: #888;">No active players</div>`}
                    </div>
                ` : pokerBurnCardPending ? `
                    <!-- Burn Pending - Hide betting controls -->
                    <div class="burn-waiting-message">
                        <span class="burn-waiting-icon">||</span>
                        <span class="burn-waiting-text">BETTING PAUSED</span>
                        <span class="burn-waiting-hint">Complete the burn & deal above, then betting resumes</span>
                    </div>
                ` : `
                    <!-- Betting Phase -->
                    <div class="poker-betting-header">
                        <div class="poker-phase-label" style="font-size: 1.4em;">
                            ${currentPlayer.name}'s Turn
                            ${isBBOption ? '<span style="background: #d4af37; color: #000; padding: 2px 8px; border-radius: 4px; font-size: 0.6em; margin-left: 10px; vertical-align: middle;">BB OPTION</span>' : ''}
                        </div>
                        <div style="margin-top: 8px;">
                            ${isBBOption ? 
                                `<span style="color: #d4af37;">Check to see flop or Raise</span>` :
                                toCall > 0 ? 
                                    `<span class="poker-to-call" style="font-size: 1.1em;">$${toCall} to call</span>` : 
                                    `<span style="color: #4ade80;">Check available</span>`
                            }
                            ${currentPlayer.bankroll > 0 ? `<span style="color: #888; margin-left: 15px;">Stack: $${currentPlayer.bankroll}</span>` : ''}
                            ${(() => {
                                const odds = getPotOdds();
                                return odds ? `<span class="pot-odds-display">Pot Odds: ${odds.ratio}:1 (${odds.percentage}%)</span>` : '';
                            })()}
                        </div>
                    </div>
                    
                    <!-- Primary Actions -->
                    <div class="poker-action-buttons" style="margin-top: 20px; gap: 15px;">
                        <button type="button" class="poker-action-btn btn-fold" onclick="pokerFold()" style="padding: 15px 30px; font-size: 1.1em;" title="Keyboard: F">
                            ✗ Fold <span style="font-size: 0.7em; opacity: 0.6;">[F]</span>
                        </button>
                        
                        ${toCall > 0 ? `
                            <button type="button" class="poker-action-btn btn-call" onclick="pokerCall()" style="padding: 15px 30px; font-size: 1.1em;" title="Keyboard: C">
                                📞 Call $${Math.min(toCall, currentPlayer.bankroll)} <span style="font-size: 0.7em; opacity: 0.6;">[C]</span>
                            </button>
                        ` : `
                            <button type="button" class="poker-action-btn btn-check" onclick="pokerCheck()" style="padding: 15px 30px; font-size: 1.1em;" title="Keyboard: C">
                                CHECK <span style="font-size: 0.7em; opacity: 0.6;">[C]</span>
                            </button>
                        `}
                        
                        ${currentPlayer.bankroll > 0 ? `
                            <button type="button" class="poker-action-btn btn-allin" onclick="pokerAllIn()" style="padding: 15px 30px; font-size: 1.1em;" title="Keyboard: A">
                                ALL-IN $${currentPlayer.bankroll + currentPlayer.bet} <span style="font-size: 0.7em; opacity: 0.6;">[A]</span>
                            </button>
                        ` : ''}
                    </div>
                    
                    <!-- Raise Options - Chip Style -->
                    ${currentPlayer.bankroll > toCall && validRaises.length > 0 ? `
                    <div class="raise-section">
                        <div class="raise-header">
                            <span>RAISE TO</span>
                            <span class="raise-hint">Keys 1-9 | Min: $${pokerCurrentBet + pokerMinRaise}</span>
                        </div>
                        <div class="chip-raise-grid">
                            ${validRaises.map((r, i) => `
                                <button type="button" class="raise-chip chip-${r.chipColor}" onclick="pokerRaise(${r.amount})" title="${r.label} = $${r.amount}">
                                    <span class="chip-key">${i < 9 ? i + 1 : ''}</span>
                                    <span class="chip-label">${r.label}</span>
                                    ${!r.label.includes('$') ? `<span class="chip-amount">$${r.amount}</span>` : ''}
                                </button>
                            `).join('')}
                        </div>
                        <div class="custom-raise-row">
                            <span>Custom:</span>
                            <input type="number" id="customRaiseInput" placeholder="$${pokerCurrentBet + pokerMinRaise}" 
                                min="${pokerCurrentBet + pokerMinRaise}" max="${currentPlayer.bet + currentPlayer.bankroll}">
                            <button type="button" class="custom-raise-btn" onclick="const v=parseInt(document.getElementById('customRaiseInput').value);if(v)pokerRaise(v);">OK</button>
                        </div>
                    </div>
                    ` : ''}
                `}
            </div>
        </div>
    `;
}

// Initialize poker on load
loadPokerFromStorage();

// Keyboard shortcuts for poker
document.addEventListener('keydown', function(e) {
    // Only handle shortcuts when in poker mode and betting phase
    if (currentGameMode !== 'poker' || pokerPhase !== 'betting') return;
    
    // Don't trigger if typing in an input
    if (e.target.tagName === 'INPUT') return;
    
    const key = e.key.toLowerCase();
    
    switch(key) {
        case 'f': // Fold
            pokerFold();
            break;
        case 'c': // Check or Call
            const player = pokerPlayers[pokerActivePlayerIndex];
            if (player && pokerCurrentBet > player.bet) {
                pokerCall();
            } else {
                pokerCheck();
            }
            break;
        case 'a': // All-in
            pokerAllIn();
            break;
        case 'z': // Undo (Ctrl+Z or just Z)
            if (e.ctrlKey || !e.ctrlKey) {
                pokerUndo();
            }
            break;
        case '1': // First raise option
        case '2': // Second raise option
        case '3': // Third raise option
        case '4': // Fourth raise option
        case '5': // Fifth raise option
        case '6': // Sixth raise option
        case '7': // Seventh raise option
        case '8': // Eighth raise option
        case '9': // Ninth raise option
            const raises = getValidRaises();
            const raiseIndex = parseInt(key) - 1;
            if (raises[raiseIndex]) {
                pokerRaise(raises[raiseIndex].amount);
            }
            break;
    }
});

// Calculate total chips in play
function getTotalChipsInPlay() {
    return pokerPlayers.reduce((sum, p) => sum + p.bankroll + p.bet, 0) + pokerPot;
}

// Get chip leader
function getChipLeader() {
    if (pokerPlayers.length === 0) return null;
    return pokerPlayers.reduce((leader, p) => 
        (p.bankroll + p.bet) > (leader.bankroll + leader.bet) ? p : leader
    , pokerPlayers[0]);
}

// Get average stack size
function getAverageStack() {
    if (pokerPlayers.length === 0) return 0;
    const total = pokerPlayers.reduce((sum, p) => sum + p.bankroll + p.bet, 0);
    return Math.floor(total / pokerPlayers.length);
}

// Format last action for display
function formatLastAction() {
    if (!pokerLastAction) return '';
    const { player, action, amount } = pokerLastAction;
    switch(action) {
        case 'fold': return `${player} folded`;
        case 'check': return `${player} checked`;
        case 'call': return `${player} called $${amount}`;
        case 'raise': return `${player} raised to $${amount}`;
        case 'allin': return `${player} ALL-IN $${amount}`;
        case 'blind': return `${player} posted $${amount}`;
        default: return '';
    }
}

// Initialize poker - render on load if pokerContent exists
document.addEventListener('DOMContentLoaded', async function() {
    const pokerContent = document.getElementById('pokerContent');
    if (pokerContent) {
        // Show loading indicator immediately
        pokerContent.innerHTML = '<div style="text-align:center;padding:40px;color:#d4af37;">Loading...</div>';
        
        // Wait for cloud storage to be ready with shorter timeout
        const waitForCloud = () => new Promise((resolve) => {
            if (typeof isCloudStorageReady === 'function' && isCloudStorageReady()) {
                resolve();
            } else {
                const handler = () => {
                    window.removeEventListener('cloudStorageReady', handler);
                    resolve();
                };
                window.addEventListener('cloudStorageReady', handler);
                // Timeout after 1.5 seconds - render with defaults if cloud is slow
                setTimeout(resolve, 1500);
            }
        });
        
        // Load and render with defaults, then update when cloud loads
        await loadPokerFromStorage();
        renderPoker();
        
        // If cloud wasn't ready, wait and reload data when it is
        if (typeof isCloudStorageReady === 'function' && !isCloudStorageReady()) {
            waitForCloud().then(async () => {
                if (typeof isCloudStorageReady === 'function' && isCloudStorageReady()) {
                    await loadPokerFromStorage();
                    renderPoker();
                }
            });
        }
    }
});
