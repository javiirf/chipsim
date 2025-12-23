// Single player state
let bankroll = 0;
let bet = 0;
let lastBet = 0;
let status = '';
let autoRebet = false;
let gameStarted = false;

// Undo bet history
let betHistory = []; // Stack of bet actions for undo

// Streak tracking
let currentStreak = 0; // Positive for wins, negative for losses
let streakType = ''; // 'win' or 'lose'

// Two hands mode
let twoHandsMode = false;
let hand2Bet = 0;
let hand2Status = '';
let hand2IsDoubleDown = false;
let activeBox = 1; // Which betting box is active (1 or 2)
let hand1Complete = false;
let hand2Complete = false;
let hand1WinAmount = 0; // Track win amount for display
let hand2WinAmount = 0; // Track win amount for display

// Split hands state for box 2 (two hands mode)
let hand2IsSplit = false;
let hand2SplitCount = 0; // 0 = no split, 1 = 2 hands, 2 = 3 hands, 3 = 4 hands
let hand2SplitBet = 0;
let hand2SplitBet2 = 0; // Third split hand bet
let hand2SplitBet3 = 0; // Fourth split hand bet
let hand2ActiveHand = 1; // 1 = main hand, 2 = split hand, 3 = third split, 4 = fourth split
let hand2Hand1Result = '';
let hand2Hand2Result = '';
let hand2Hand3Result = '';
let hand2Hand4Result = '';
let hand2SplitOriginalBet = 0;
let hand2Split1DD = false; // Track if split hand 2A has been doubled
let hand2Split2DD = false; // Track if split hand 2B has been doubled
let hand2Split3DD = false; // Track if split hand 2C has been doubled
let hand2Split4DD = false; // Track if split hand 2D has been doubled

// Split hands state (for splitting within a hand)
let isSplit = false;
let splitCount = 0; // 0 = no split, 1 = 2 hands, 2 = 3 hands, 3 = 4 hands
let splitBet = 0;
let splitBet2 = 0; // Third split hand bet
let splitBet3 = 0; // Fourth split hand bet
let activeHand = 1; // 1 = main hand, 2 = split hand, 3 = third split, 4 = fourth split
let hand1Result = '';
let hand2Result = '';
let hand3Result = '';
let hand4Result = '';
let splitOriginalBet = 0; // Track original bet for split hands
let split1DD = false; // Track if split hand 1A has been doubled
let split2DD = false; // Track if split hand 1B has been doubled
let split3DD = false; // Track if split hand 1C has been doubled
let split4DD = false; // Track if split hand 1D has been doubled

// Double down state
let isDoubleDown = false;

// Surrender state
let hasSurrendered = false;
let hand2HasSurrendered = false;

// Insurance state
let hasInsurance = false;
let insuranceBet = 0;

// Round tracking
let roundNumber = 0;
let roundInProgress = false;
let betConfirmed = false;
let isDealing = false;

// Outcome tracking for display
let lastWinAmount = 0;
let lastTotalPayout = 0; // Total amount returned (bet + winnings)

// Session statistics
let stats = {
    wins: 0,
    losses: 0,
    pushes: 0,
    blackjacks: 0,
    totalWon: 0,
    totalLost: 0,
    biggestWin: 0,
    handsPlayed: 0
};

// Leaderboard
let leaderboard = [];

// Sound effects system
let soundEnabled = localStorage.getItem('soundEnabled') !== 'false';
let audioContext = null;

// Audio file elements
let placeYourBetsAudio = null;
let cardDropAudio = null;

function initAudioFiles() {
    if (!placeYourBetsAudio) {
        placeYourBetsAudio = new Audio('place-your-bets-please-female-voice-28110.mp3');
    }
    if (!cardDropAudio) {
        cardDropAudio = new Audio('carddrop2-92718.mp3');
    }
}

function playPlaceYourBets() {
    if (!soundEnabled) return;
    initAudioFiles();
    
    placeYourBetsAudio.currentTime = 4.4; // Start at 4.4 seconds
    placeYourBetsAudio.play();
    
    // Stop at 8 seconds (3.6 second duration)
    setTimeout(() => {
        placeYourBetsAudio.pause();
    }, 3600);
}

function playCardDrop() {
    if (!soundEnabled) return;
    initAudioFiles();
    cardDropAudio.currentTime = 0;
    cardDropAudio.play();
}

function initAudio() {
    if (!audioContext) {
        audioContext = new (window.AudioContext || window.webkitAudioContext)();
    }
    return audioContext;
}

function playSound(type) {
    if (!soundEnabled) return;
    
    try {
        const ctx = initAudio();
        if (ctx.state === 'suspended') {
            ctx.resume();
        }
        
        switch(type) {
            case 'chip':
                playChipSound(ctx);
                break;
            case 'deal':
                playCardDrop(); // Use the audio file
                break;
            case 'win':
                playWinSound(ctx);
                break;
            case 'lose':
                playLoseSound(ctx);
                break;
            case 'blackjack':
                playBlackjackSound(ctx);
                break;
            case 'push':
                playPushSound(ctx);
                break;
            case 'click':
                playClickSound(ctx);
                break;
            case 'placeBets':
                playPlaceYourBets();
                break;
            case 'streak':
                playStreakSound(ctx);
                break;
        }
    } catch (e) {
        // Silent fail for audio errors
    }
}

// Streak celebration sound
function playStreakSound(ctx) {
    // Rising triumphant notes
    const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
    notes.forEach((freq, i) => {
        setTimeout(() => {
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.connect(gain);
            gain.connect(ctx.destination);
            
            osc.frequency.setValueAtTime(freq, ctx.currentTime);
            osc.type = 'triangle';
            gain.gain.setValueAtTime(0.15, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.3);
            
            osc.start(ctx.currentTime);
            osc.stop(ctx.currentTime + 0.3);
        }, i * 100);
    });
}

function playChipSound(ctx) {
    // Multiple short clicks for chip stacking sound
    for (let i = 0; i < 3; i++) {
        setTimeout(() => {
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.connect(gain);
            gain.connect(ctx.destination);
            
            osc.frequency.setValueAtTime(800 + Math.random() * 400, ctx.currentTime);
            osc.type = 'square';
            gain.gain.setValueAtTime(0.1, ctx.currentTime);
            gain.gain.exponentialDecayTo = 0.01;
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.05);
            
            osc.start(ctx.currentTime);
            osc.stop(ctx.currentTime + 0.05);
        }, i * 30);
    }
}

function playWinSound(ctx) {
    // Ascending happy arpeggio
    const notes = [523, 659, 784, 1047]; // C5, E5, G5, C6
    notes.forEach((freq, i) => {
        setTimeout(() => {
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.connect(gain);
            gain.connect(ctx.destination);
            
            osc.frequency.setValueAtTime(freq, ctx.currentTime);
            osc.type = 'sine';
            gain.gain.setValueAtTime(0.2, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.3);
            
            osc.start(ctx.currentTime);
            osc.stop(ctx.currentTime + 0.3);
        }, i * 100);
    });
}

function playLoseSound(ctx) {
    // Descending sad tones
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    
    osc.frequency.setValueAtTime(400, ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(150, ctx.currentTime + 0.4);
    osc.type = 'sine';
    
    gain.gain.setValueAtTime(0.15, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.4);
    
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.4);
}

function playBlackjackSound(ctx) {
    // Exciting fanfare
    const notes = [523, 659, 784, 1047, 1319]; // C5, E5, G5, C6, E6
    notes.forEach((freq, i) => {
        setTimeout(() => {
            const osc = ctx.createOscillator();
            const osc2 = ctx.createOscillator();
            const gain = ctx.createGain();
            
            osc.connect(gain);
            osc2.connect(gain);
            gain.connect(ctx.destination);
            
            osc.frequency.setValueAtTime(freq, ctx.currentTime);
            osc2.frequency.setValueAtTime(freq * 1.5, ctx.currentTime);
            osc.type = 'sine';
            osc2.type = 'triangle';
            
            gain.gain.setValueAtTime(0.15, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.4);
            
            osc.start(ctx.currentTime);
            osc2.start(ctx.currentTime);
            osc.stop(ctx.currentTime + 0.4);
            osc2.stop(ctx.currentTime + 0.4);
        }, i * 80);
    });
}

function playPushSound(ctx) {
    // Neutral tone
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    
    osc.frequency.setValueAtTime(440, ctx.currentTime);
    osc.type = 'sine';
    
    gain.gain.setValueAtTime(0.1, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.2);
    
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.2);
}

function playClickSound(ctx) {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    
    osc.frequency.setValueAtTime(600, ctx.currentTime);
    osc.type = 'square';
    
    gain.gain.setValueAtTime(0.08, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.03);
    
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.03);
}

function toggleSound() {
    soundEnabled = !soundEnabled;
    localStorage.setItem('soundEnabled', soundEnabled);
    document.querySelectorAll('.sound-btn').forEach(btn => {
        btn.textContent = soundEnabled ? '🔊' : '🔇';
        btn.classList.toggle('muted', !soundEnabled);
    });
    if (soundEnabled) playSound('click');
}

// Preset buy-in amounts
const PRESET_BUYINS = [100, 500, 1000];

// Helper: Get current split hand bet for box 1
function getCurrentSplitBet() {
    return activeHand === 1 ? bet : (activeHand === 2 ? splitBet : (activeHand === 3 ? splitBet2 : splitBet3));
}

// Helper: Get current split hand bet for box 2
function getHand2CurrentSplitBet() {
    return hand2ActiveHand === 1 ? hand2Bet : (hand2ActiveHand === 2 ? hand2SplitBet : (hand2ActiveHand === 3 ? hand2SplitBet2 : hand2SplitBet3));
}

// Helper: Check if split hand has double down (box 1) - handNum is 1-4
function getSplitDD(handNum) {
    return handNum === 1 ? split1DD : (handNum === 2 ? split2DD : (handNum === 3 ? split3DD : split4DD));
}

// Helper: Check if split hand has double down (box 2) - handNum is 1-4
function getHand2SplitDD(handNum) {
    return handNum === 1 ? hand2Split1DD : (handNum === 2 ? hand2Split2DD : (handNum === 3 ? hand2Split3DD : hand2Split4DD));
}

// Helper: Get current bet for active box
function getActiveBet() {
    return activeBox === 1 ? bet : hand2Bet;
}

// Helper: Check if active box is split
function getActiveSplit() {
    return activeBox === 1 ? isSplit : hand2IsSplit;
}

// Helper: Check if active box has double down
function getActiveDD() {
    return activeBox === 1 ? isDoubleDown : hand2IsDoubleDown;
}

// Helper: Format split hand display with result/bet (box = 1 or 2)
function formatSplitHandDisplay(result, currentBet, handNum, box) {
    const isDD = box === 1 ? getSplitDD(handNum) : getHand2SplitDD(handNum);
    const originalBet = box === 1 ? splitOriginalBet : hand2SplitOriginalBet;
    const betAmount = isDD ? originalBet * 2 : originalBet;
    if (!result) return `<span class="hand-bet">$${currentBet}${isDD ? ' (DD)' : ''}</span>`;
    if (result === 'win') return `<span class="hand-bet win-amount">+$${betAmount}</span>`;
    if (result === 'blackjack') return `<span class="hand-bet win-amount">+$${Math.floor(betAmount * 1.5)}</span>`;
    if (result === 'lose') return `<span class="hand-bet lose-amount">-$${betAmount}</span>`;
    if (result === 'push') return `<span class="hand-bet push-amount">$${betAmount}</span>`;
    return `<span class="hand-bet">$${currentBet}</span>`;
}

// Initialize the app
async function init() {
    // Show loading state
    const container = document.getElementById('playerSide');
    if (container) {
        container.innerHTML = '<div style="text-align:center;padding:40px;color:#d4af37;">Loading...</div>';
    }
    
    // Wait for cloud storage to be ready, with shorter timeout
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
    
    // Render immediately with defaults, then update when cloud loads
    await loadFromStorage();
    render();
    setupKeyboardShortcuts();
    
    // If cloud wasn't ready, wait and reload data when it is
    if (typeof isCloudStorageReady === 'function' && !isCloudStorageReady()) {
        waitForCloud().then(async () => {
            if (typeof isCloudStorageReady === 'function' && isCloudStorageReady()) {
                await loadFromStorage();
                render();
            }
        });
    }
}

// Save to cloud storage
function saveToStorage() {
    // Call cloud save function (defined in cloud-storage.js)
    if (typeof saveBlackjackToCloud === 'function') {
        saveBlackjackToCloud();
    }
}

// Load from cloud storage
async function loadFromStorage() {
    // Try to load from cloud (defined in cloud-storage.js)
    if (typeof loadBlackjackFromCloud === 'function') {
        const loaded = await loadBlackjackFromCloud();
        if (loaded) {
            return;
        }
    }
    // Fallback defaults if nothing loaded
    bankroll = 0;
    bet = 0;
    lastBet = 0;
    autoRebet = false;
    gameStarted = false;
    roundNumber = 0;
    stats = { wins: 0, losses: 0, pushes: 0, blackjacks: 0, totalWon: 0, totalLost: 0, biggestWin: 0, handsPlayed: 0 };
    twoHandsMode = false;
    hand2Bet = 0;
    leaderboard = [];
}

// Keyboard shortcuts
function setupKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
        if (document.activeElement.tagName === 'INPUT') return;
        
        switch(e.key) {
            case '1': quickBet(5); break;
            case '2': quickBet(10); break;
            case '3': quickBet(25); break;
            case '4': quickBet(50); break;
            case '5': quickBet(100); break;
            case 'Enter': case ' ': e.preventDefault(); confirmBet(); break;
            case 'r': case 'R': rebet(); break;
            case 'c': case 'C': clearBet(); break;
            case 'd': case 'D': doubleDown(); break;
            case 's': case 'S': splitHand(); break;
            case 'i': case 'I': takeInsurance(); break;
            case 'Escape': newGame(); break;
        }
    });
}

// Preset buy-in
function presetBuyin(amount) {
    playSound('push');
    bankroll += amount;
    gameStarted = true;
    status = '';
    saveToStorage();
    render();
}

// Toggle two hands mode
function toggleTwoHands() {
    if (!betConfirmed && !isDealing) {
        playSound('push');
        twoHandsMode = !twoHandsMode;
        if (!twoHandsMode) {
            // Return hand 2 bet to bankroll when disabling
            bankroll += hand2Bet;
            hand2Bet = 0;
            activeBox = 1;
        }
        saveToStorage();
        render();
    }
}

// Switch active betting box (for two hands mode)
function switchBox(box) {
    if (twoHandsMode && !betConfirmed && !isDealing) {
        playSound('push');
        activeBox = box;
        render();
    }
}

// Quick bet for specific box in two hands mode
function quickBetBox(amount, box) {
    if (amount <= bankroll && !betConfirmed && !isDealing && twoHandsMode) {
        playSound('push');
        if (box === 1) {
            bet += amount;
        } else {
            hand2Bet += amount;
        }
        bankroll -= amount;
        status = '';
        saveToStorage();
        render();
    }
}

// Copy bet from one hand to another in two hands mode
function copyBet(fromBox) {
    if (!betConfirmed && !isDealing && twoHandsMode) {
        const sourceBet = fromBox === 1 ? bet : hand2Bet;
        
        if (sourceBet > 0 && sourceBet <= bankroll) {
            playSound('push');
            const targetBox = fromBox === 1 ? 2 : 1;
            betHistory.push({ type: 'quickBet', amount: sourceBet, box: targetBox });
            if (fromBox === 1) {
                hand2Bet = sourceBet;
            } else {
                bet = sourceBet;
            }
            bankroll -= sourceBet;
            saveToStorage();
            render();
        }
    }
}

// Clear specific hand bet in two hands mode
function clearHandBet(box) {
    if (!betConfirmed && !isDealing && twoHandsMode) {
        playSound('push');
        if (box === 1 && bet > 0) {
            bankroll += bet;
            bet = 0;
        } else if (box === 2 && hand2Bet > 0) {
            bankroll += hand2Bet;
            hand2Bet = 0;
        }
        saveToStorage();
        render();
    }
}

// Add chips to bankroll
function addChips() {
    const input = document.getElementById('addChipsInput');
    const amount = parseInt(input.value) || 0;
    if (amount > 0) {
        playSound('push');
        bankroll += amount;
        input.value = '';
        status = '';
        gameStarted = true;
        saveToStorage();
        render();
    }
}

// Quick bet - add amount to current bet
function quickBet(amount) {
    if (amount <= bankroll && !betConfirmed && !isDealing) {
        playSound('push');
        // Save to undo history
        betHistory.push({ type: 'quickBet', amount: amount, box: twoHandsMode ? activeBox : 1 });
        if (twoHandsMode && activeBox === 2) {
            hand2Bet += amount;
        } else {
            bet += amount;
        }
        bankroll -= amount;
        status = '';
        saveToStorage();
        render();
    }
}

// Undo last bet action
function undoBet() {
    if (betHistory.length > 0 && !betConfirmed && !isDealing) {
        playSound('push');
        const lastAction = betHistory.pop();
        if (lastAction.type === 'quickBet') {
            if (lastAction.box === 2) {
                hand2Bet -= lastAction.amount;
            } else {
                bet -= lastAction.amount;
            }
            bankroll += lastAction.amount;
        } else if (lastAction.type === 'allIn') {
            if (lastAction.box === 2) {
                hand2Bet -= lastAction.amount;
            } else {
                bet -= lastAction.amount;
            }
            bankroll += lastAction.amount;
        } else if (lastAction.type === 'doubleBet') {
            if (lastAction.box === 2) {
                hand2Bet -= lastAction.amount;
            } else {
                bet -= lastAction.amount;
            }
            bankroll += lastAction.amount;
        } else if (lastAction.type === 'rebet') {
            if (lastAction.box === 2) {
                hand2Bet -= lastAction.amount;
            } else {
                bet -= lastAction.amount;
            }
            bankroll += lastAction.amount;
        }
        saveToStorage();
        render();
    }
}

// Confirm bet and start dealing animation
function confirmBet() {
    const hasValidBet = twoHandsMode ? (bet > 0 || hand2Bet > 0) : bet > 0;
    if (hasValidBet && !betConfirmed && !isDealing) {
        playSound('deal');
        betConfirmed = true;
        isDealing = true;
        betHistory = []; // Clear undo history when bet is confirmed
        // In two hands mode, set active box to whichever has a bet
        if (twoHandsMode) {
            activeBox = bet > 0 ? 1 : 2;
            hand1Complete = bet === 0;
            hand2Complete = hand2Bet === 0;
        }
        startRound();
        saveToStorage();
        render();
        // isDealing stays true until a result button is clicked
    }
}

// Start a new round
function startRound() {
    roundNumber++;
    roundInProgress = true;
}

// Track streak and show notification
function updateStreak(result) {
    if (result === 'win' || result === 'blackjack') {
        if (streakType === 'win') {
            currentStreak++;
        } else {
            currentStreak = 1;
            streakType = 'win';
        }
    } else if (result === 'lose') {
        if (streakType === 'lose') {
            currentStreak++;
        } else {
            currentStreak = 1;
            streakType = 'lose';
        }
    } else {
        // Push doesn't break or continue streak
        return;
    }
    
    // Show streak notification for 3+ in a row
    if (currentStreak >= 3) {
        showStreakNotification();
    }
}

// Show streak notification
function showStreakNotification() {
    const existingNotif = document.querySelector('.streak-notification');
    if (existingNotif) existingNotif.remove();
    
    const notif = document.createElement('div');
    notif.className = 'streak-notification ' + streakType + '-streak';
    
    const emoji = streakType === 'win' ? '🔥' : '❄️';
    const text = streakType === 'win' ? 'WIN STREAK' : 'LOSING STREAK';
    notif.innerHTML = `${emoji} ${currentStreak}x ${text}! ${emoji}`;
    
    document.body.appendChild(notif);
    
    // Play streak sound for win streaks
    if (streakType === 'win') {
        setTimeout(() => playSound('streak'), 300);
    }
    
    // Remove after animation
    setTimeout(() => {
        notif.classList.add('fade-out');
        setTimeout(() => notif.remove(), 500);
    }, 2500);
}

// End current round
function endRound() {
    roundInProgress = false;
    betConfirmed = false;
    // Reset double down state
    isDoubleDown = false;
    hand2IsDoubleDown = false;
    // Reset surrender state
    hasSurrendered = false;
    hand2HasSurrendered = false;
    // Reset insurance state
    hasInsurance = false;
    insuranceBet = 0;
    // Reset hand 2 split state
    hand2IsSplit = false;
    hand2SplitCount = 0;
    hand2SplitBet = 0;
    hand2SplitBet2 = 0;
    hand2ActiveHand = 1;
    hand2Hand1Result = '';
    hand2Hand2Result = '';
    hand2Hand3Result = '';
    hand2Hand4Result = '';
    hand2SplitOriginalBet = 0;
    hand2Split1DD = false;
    hand2Split2DD = false;
    hand2Split3DD = false;
    hand2Split4DD = false;
    hand2SplitBet3 = 0;
    // Reset hand 1 split state
    isSplit = false;
    splitCount = 0;
    splitBet = 0;
    splitBet2 = 0;
    splitBet3 = 0;
    activeHand = 1;
    hand1Result = '';
    hand2Result = '';
    hand3Result = '';
    hand4Result = '';
    split1DD = false;
    split2DD = false;
    split3DD = false;
    split4DD = false;
    splitOriginalBet = 0;
    // Play "place your bets" for next round
    setTimeout(() => {
        playSound('placeBets');
    }, 500);
    // Clear status after 5 seconds to show "Place Your Bet"
    setTimeout(() => {
        if (!betConfirmed && !isDealing) {
            status = '';
            render();
        }
    }, 5000);
}

// Rebet - bet same as last time (only when no current bet)
function rebet() {
    if (lastBet > 0 && bet === 0 && !betConfirmed && !isDealing) {
        const amount = Math.min(lastBet, bankroll);
        if (amount > 0) {
            playSound('push');
            betHistory.push({ type: 'rebet', amount: amount });
            bet = amount;
            bankroll -= amount;
            status = '';
            // In two hands mode, also rebet on hand 2 if we can afford it
            if (twoHandsMode && hand2Bet === 0 && amount <= bankroll) {
                betHistory.push({ type: 'rebet', amount: amount, box: 2 });
                hand2Bet = amount;
                bankroll -= amount;
            }
            // If we couldn't bet the full lastBet amount, turn off autoRebet
            if (amount !== lastBet) autoRebet = false;
            saveToStorage();
            render();
        }
    }
}

// Double current bet (just doubles the bet amount)
function doubleBet() {
    if (!betConfirmed && !isDealing) {
        if (twoHandsMode) {
            const currentBet = getActiveBet();
            if (currentBet > 0 && currentBet <= bankroll) {
                playSound('push');
                betHistory.push({ type: 'doubleBet', amount: currentBet, box: activeBox });
                if (activeBox === 1) {
                    bet += currentBet;
                } else {
                    hand2Bet += currentBet;
                }
                bankroll -= currentBet;
                saveToStorage();
                render();
            }
        } else if (bet > 0 && !isSplit && !isDoubleDown && bet <= bankroll) {
            const amount = bet;
            playSound('push');
            betHistory.push({ type: 'doubleBet', amount: amount });
            bet += amount;
            bankroll -= amount;
            saveToStorage();
            render();
        }
    }
}

// Double Down - doubles bet and locks in for one result (only after cards dealt)
function doubleDown() {
    if (twoHandsMode) {
        // Two hands mode - check if we're in a split
        if (activeBox === 1 && isSplit) {
            // Double down on split hand 1
            if (activeHand === 1 && bet > 0 && bet <= bankroll && !split1DD) {
                playSound('push');
                bankroll -= bet;
                bet *= 2;
                split1DD = true;
                saveToStorage();
                render();
            } else if (activeHand === 2 && splitBet > 0 && splitBet <= bankroll && !split2DD) {
                playSound('push');
                bankroll -= splitBet;
                splitBet *= 2;
                split2DD = true;
                saveToStorage();
                render();
            } else if (activeHand === 3 && splitBet2 > 0 && splitBet2 <= bankroll && !split3DD) {
                playSound('push');
                bankroll -= splitBet2;
                splitBet2 *= 2;
                split3DD = true;
                saveToStorage();
                render();
            } else if (activeHand === 4 && splitBet3 > 0 && splitBet3 <= bankroll && !split4DD) {
                playSound('push');
                bankroll -= splitBet3;
                splitBet3 *= 2;
                split4DD = true;
                saveToStorage();
                render();
            }
        } else if (activeBox === 2 && hand2IsSplit) {
            // Double down on split hand 2
            if (hand2ActiveHand === 1 && hand2Bet > 0 && hand2Bet <= bankroll && !hand2Split1DD) {
                playSound('push');
                bankroll -= hand2Bet;
                hand2Bet *= 2;
                hand2Split1DD = true;
                saveToStorage();
                render();
            } else if (hand2ActiveHand === 2 && hand2SplitBet > 0 && hand2SplitBet <= bankroll && !hand2Split2DD) {
                playSound('push');
                bankroll -= hand2SplitBet;
                hand2SplitBet *= 2;
                hand2Split2DD = true;
                saveToStorage();
                render();
            } else if (hand2ActiveHand === 3 && hand2SplitBet2 > 0 && hand2SplitBet2 <= bankroll && !hand2Split3DD) {
                playSound('push');
                bankroll -= hand2SplitBet2;
                hand2SplitBet2 *= 2;
                hand2Split3DD = true;
                saveToStorage();
                render();
            } else if (hand2ActiveHand === 4 && hand2SplitBet3 > 0 && hand2SplitBet3 <= bankroll && !hand2Split4DD) {
                playSound('push');
                bankroll -= hand2SplitBet3;
                hand2SplitBet3 *= 2;
                hand2Split4DD = true;
                saveToStorage();
                render();
            }
        } else if (activeBox === 1 && bet > 0 && bet <= bankroll && !isDoubleDown && betConfirmed) {
            playSound('push');
            bankroll -= bet;
            bet *= 2;
            isDoubleDown = true;
            saveToStorage();
            render();
        } else if (activeBox === 2 && hand2Bet > 0 && hand2Bet <= bankroll && !hand2IsDoubleDown && betConfirmed) {
            playSound('push');
            bankroll -= hand2Bet;
            hand2Bet *= 2;
            hand2IsDoubleDown = true;
            saveToStorage();
            render();
        }
    } else {
        // Single hand mode
        if (bet > 0 && bet <= bankroll && !isSplit && !isDoubleDown && betConfirmed) {
            playSound('push');
            bankroll -= bet;
            bet *= 2;
            isDoubleDown = true;
            saveToStorage();
            render();
        }
    }
}

// Clear bet
function clearBet() {
    if (!betConfirmed && !isDealing) {
        playSound('push');
        if (twoHandsMode && activeBox === 2) {
            bankroll += hand2Bet;
            hand2Bet = 0;
        } else {
            bankroll += bet;
            bet = 0;
        }
        status = '';
        saveToStorage();
        render();
    }
}

// Clear all bets (for two hands mode)
function clearAllBets() {
    if (!betConfirmed && !isDealing) {
        playSound('push');
        bankroll += bet + hand2Bet;
        bet = 0;
        hand2Bet = 0;
        betHistory = []; // Clear undo history when clearing all bets
        status = '';
        saveToStorage();
        render();
    }
}

// Split hand - creates second/third/fourth hand with equal bet (only after cards dealt)
function splitHand() {
    if (twoHandsMode) {
        // Two hands mode - split the active box
        if (activeBox === 1) {
            // Get the current hand's bet for splitting
            const currentHandBet = getCurrentSplitBet();
            
            if (!isSplit && bet > 0 && bet <= bankroll && betConfirmed) {
                // First split - creates hands A and B
                playSound('push');
                splitOriginalBet = bet;
                isSplit = true;
                splitCount = 1;
                splitBet = bet;
                bankroll -= bet;
                activeHand = 1;
                hand1Result = '';
                hand2Result = '';
                hand3Result = '';
                hand4Result = '';
                status = '';
                saveToStorage();
                render();
            } else if (isSplit && splitCount < 3 && getCurrentSplitBet() > 0 && getCurrentSplitBet() <= bankroll && betConfirmed) {
                // Second/Third split - creates hand C or D
                playSound('push');
                splitCount++;
                if (splitCount === 2) {
                    splitBet2 = currentHandBet;
                    hand3Result = '';
                } else if (splitCount === 3) {
                    splitBet3 = currentHandBet;
                    hand4Result = '';
                }
                bankroll -= currentHandBet;
                saveToStorage();
                render();
            }
        } else if (activeBox === 2) {
            const currentHandBet = getHand2CurrentSplitBet();
            
            if (!hand2IsSplit && hand2Bet > 0 && hand2Bet <= bankroll && betConfirmed) {
                // First split for hand 2
                playSound('push');
                hand2SplitOriginalBet = hand2Bet;
                hand2IsSplit = true;
                hand2SplitCount = 1;
                hand2SplitBet = hand2Bet;
                bankroll -= hand2Bet;
                hand2ActiveHand = 1;
                hand2Hand1Result = '';
                hand2Hand2Result = '';
                hand2Hand3Result = '';
                hand2Hand4Result = '';
                hand2Status = '';
                saveToStorage();
                render();
            } else if (hand2IsSplit && hand2SplitCount < 3 && currentHandBet > 0 && currentHandBet <= bankroll && betConfirmed) {
                // Second/Third split for hand 2
                playSound('push');
                hand2SplitCount++;
                if (hand2SplitCount === 2) {
                    hand2SplitBet2 = currentHandBet;
                    hand2Hand3Result = '';
                } else if (hand2SplitCount === 3) {
                    hand2SplitBet3 = currentHandBet;
                    hand2Hand4Result = '';
                }
                bankroll -= currentHandBet;
                saveToStorage();
                render();
            }
        }
    } else {
        // Single hand mode
        const currentHandBet = getCurrentSplitBet();
        
        if (!isSplit && bet > 0 && bet <= bankroll && betConfirmed) {
            // First split
            playSound('push');
            splitOriginalBet = bet;
            isSplit = true;
            splitCount = 1;
            splitBet = bet;
            bankroll -= bet;
            activeHand = 1;
            hand1Result = '';
            hand2Result = '';
            hand3Result = '';
            hand4Result = '';
            status = '';
            saveToStorage();
            render();
        } else if (isSplit && splitCount < 3 && currentHandBet > 0 && currentHandBet <= bankroll && betConfirmed) {
            // Second/Third split
            playSound('push');
            splitCount++;
            if (splitCount === 2) {
                splitBet2 = currentHandBet;
                hand3Result = '';
            } else if (splitCount === 3) {
                splitBet3 = currentHandBet;
                hand4Result = '';
            }
            bankroll -= currentHandBet;
            saveToStorage();
            render();
        }
    }
}

// Insurance - side bet that pays 2:1 if dealer has blackjack
function takeInsurance() {
    // Calculate total bet for insurance (half of total amount at risk)
    let totalBetAtRisk = bet;
    if (twoHandsMode && hand2Bet > 0) {
        totalBetAtRisk += hand2Bet;
    }
    
    const insuranceAmount = Math.floor(totalBetAtRisk / 2);
    
    // Can take insurance if:
    // - Bet is confirmed
    // - Haven't already taken insurance
    // - Not in a split (within a single hand)
    // - Not doubled down
    // - Have enough bankroll
    if (betConfirmed && !hasInsurance && !isSplit && !hand2IsSplit && !isDoubleDown && !hand2IsDoubleDown && insuranceAmount <= bankroll) {
        playSound('push');
        hasInsurance = true;
        insuranceBet = insuranceAmount;
        bankroll -= insuranceAmount;
        saveToStorage();
        render();
    }
}

// Insurance wins (dealer has blackjack) - pays 2:1
function insuranceWins() {
    if (hasInsurance && insuranceBet > 0) {
        playSound('win');
        const winAmount = insuranceBet * 2; // 2:1 payout
        bankroll += insuranceBet + winAmount; // Return bet + winnings
        lastWinAmount = winAmount;
        status = 'insurance-win';
        
        // Set lastBet before resetting bet
        lastBet = bet;
        
        // Reset insurance
        hasInsurance = false;
        insuranceBet = 0;
        
        // Return original bets since dealer has BJ (push on main hands)
        bankroll += bet;
        bet = 0;
        
        // In two hands mode, also return hand 2 bet
        if (twoHandsMode && hand2Bet > 0) {
            bankroll += hand2Bet;
            hand2Bet = 0;
            hand1Complete = true;
            hand2Complete = true;
        }
        
        isDealing = false;
        endRound();
        if (autoRebet) doAutoRebet();
        saveToStorage();
        render();
    }
}

// Insurance loses (dealer doesn't have blackjack) - continue play
function insuranceLoses() {
    if (hasInsurance) {
        playSound('push');
        // Insurance bet is lost, just continue playing
        stats.totalLost += insuranceBet;
        hasInsurance = false;
        insuranceBet = 0;
        status = ''; // Clear any previous status
        saveToStorage();
        render();
    }
}

// Surrender - forfeit half your bet and give up the hand
function surrender() {
    if (twoHandsMode) {
        if (activeBox === 1 && bet > 0 && betConfirmed && !isSplit && !isDoubleDown && !hasSurrendered) {
            playSound('push');
            const halfBet = Math.floor(bet / 2);
            const lostAmount = bet - halfBet;
            lastBet = bet;
            bankroll += halfBet; // Return half the bet
            stats.totalLost += lostAmount; // Lost half the bet
            stats.losses++;
            stats.handsPlayed++;
            hasSurrendered = true;
            hand1Complete = true;
            status = 'surrender';
            hand1WinAmount = -lostAmount; // Negative to indicate loss
            lastWinAmount = lostAmount;
            bet = 0;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        } else if (activeBox === 2 && hand2Bet > 0 && betConfirmed && !hand2IsSplit && !hand2IsDoubleDown && !hand2HasSurrendered) {
            playSound('push');
            const halfBet = Math.floor(hand2Bet / 2);
            const lostAmount = hand2Bet - halfBet;
            lastBet = hand2Bet;
            bankroll += halfBet; // Return half the bet
            stats.totalLost += lostAmount; // Lost half the bet
            stats.losses++;
            stats.handsPlayed++;
            hand2HasSurrendered = true;
            hand2Complete = true;
            hand2Status = 'surrender';
            hand2WinAmount = -lostAmount; // Negative to indicate loss
            lastWinAmount = lostAmount;
            hand2Bet = 0;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        }
    } else {
        // Single hand mode
        if (bet > 0 && betConfirmed && !isSplit && !isDoubleDown && !hasSurrendered) {
            playSound('push');
            const halfBet = Math.floor(bet / 2);
            bankroll += halfBet; // Return half the bet
            stats.totalLost += bet - halfBet; // Lost half the bet
            stats.losses++;
            stats.handsPlayed++;
            hasSurrendered = true;
            status = 'surrender';
            lastWinAmount = bet - halfBet;
            lastBet = bet;
            bet = 0;
            isDealing = false;
            endRound();
            if (autoRebet) doAutoRebet();
            saveToStorage();
            render();
        }
    }
}

// Switch active hand during split
function switchHand() {
    if (twoHandsMode && activeBox === 2 && hand2IsSplit) {
        playSound('push');
        // Cycle through active hands for hand 2
        const maxHand = hand2SplitCount + 1; // splitCount 1 = 2 hands, 2 = 3 hands, 3 = 4 hands
        hand2ActiveHand = hand2ActiveHand >= maxHand ? 1 : hand2ActiveHand + 1;
        render();
    } else if (isSplit) {
        playSound('push');
        // Cycle through active hands
        const maxHand = splitCount + 1; // splitCount 1 = 2 hands, 2 = 3 hands, 3 = 4 hands
        activeHand = activeHand >= maxHand ? 1 : activeHand + 1;
        render();
    }
}

// Check if two hands round is complete
function checkTwoHandsComplete() {
    if (twoHandsMode && hand1Complete && hand2Complete) {
        // Both hands done, end round
        isDealing = false;
        
        // Calculate combined result for display (surrender counts as loss)
        const wins = (status === 'win' || status === 'blackjack' ? 1 : 0) + 
                     (hand2Status === 'win' || hand2Status === 'blackjack' ? 1 : 0);
        const losses = (status === 'lose' || status === 'surrender' ? 1 : 0) + 
                       (hand2Status === 'lose' || hand2Status === 'surrender' ? 1 : 0);
        const pushes = (status === 'push' ? 1 : 0) + (hand2Status === 'push' ? 1 : 0);
        
        // Calculate totals - negative values indicate losses
        const totalWon = Math.max(0, hand1WinAmount) + Math.max(0, hand2WinAmount);
        const totalLost = Math.abs(Math.min(0, hand1WinAmount)) + Math.abs(Math.min(0, hand2WinAmount));
        
        // Set combined amounts for status bar
        // If there were losses, show lost amount; if wins, show won amount
        if (losses > 0 && wins === 0 && pushes === 0) {
            lastWinAmount = totalLost; // For lose/surrender, show what was lost
        } else if (wins > 0 && losses === 0) {
            lastWinAmount = totalWon; // For wins, show what was won
        } else {
            // Mixed results - show net
            lastWinAmount = totalWon > 0 ? totalWon : totalLost;
        }
        lastTotalPayout = totalWon; // Combined total payout
        
        // Play appropriate sound based on combined result
        if (wins > 0 && losses === 0) {
            playSound(status === 'blackjack' || hand2Status === 'blackjack' ? 'blackjack' : 'win');
            status = wins === 2 && (status === 'blackjack' || hand2Status === 'blackjack') ? 'blackjack' : 'win';
        } else if (losses > 0 && wins === 0) {
            playSound('lose');
            status = (status === 'surrender' || hand2Status === 'surrender') ? 'surrender' : 'lose';
        } else if (wins > losses) {
            playSound('win');
            status = 'win';
        } else if (losses > wins) {
            playSound('lose');
            status = 'lose';
        } else {
            playSound('push');
            status = 'push';
        }
        
        endRound();
        // Reset for next round
        hand1Complete = false;
        hand2Complete = false;
        hand2IsDoubleDown = false;
        hand1WinAmount = 0;
        hand2WinAmount = 0;
        activeBox = 1; // Reset to box 1 for next round
        if (autoRebet) doAutoRebet();
        saveToStorage();
        return true;
    }
    return false;
}

// Move to next hand in two hands mode
function moveToNextHand() {
    if (twoHandsMode) {
        if (activeBox === 1 && !hand2Complete && hand2Bet > 0) {
            activeBox = 2;
            render();
            return true;
        } else if (activeBox === 2 && !hand1Complete && bet > 0) {
            activeBox = 1;
            render();
            return true;
        }
    }
    return false;
}

// Win 1:1
function win() {
    // Two hands mode with split within a box
    if (twoHandsMode && betConfirmed && (isSplit || hand2IsSplit)) {
        if (activeBox === 1 && isSplit) {
            // Hand 1 is split
            if (activeHand === 1 && bet > 0) {
                bankroll += bet * 2;
                hand1Result = 'win';
                bet = 0;
                if (splitBet > 0) {
                    activeHand = 2;
                } else if (splitBet2 > 0) {
                    activeHand = 3;
                } else if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    // Done with hand 1 split
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 2 && splitBet > 0) {
                bankroll += splitBet * 2;
                hand2Result = 'win';
                splitBet = 0;
                if (splitBet2 > 0) {
                    activeHand = 3;
                } else if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 3 && splitBet2 > 0) {
                bankroll += splitBet2 * 2;
                hand3Result = 'win';
                splitBet2 = 0;
                if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 4 && splitBet3 > 0) {
                bankroll += splitBet3 * 2;
                hand4Result = 'win';
                splitBet3 = 0;
                finishTwoHandsSplit(1);
                hand1Complete = true;
                isSplit = false;
                if (!checkTwoHandsComplete()) moveToNextHand();
            }
            saveToStorage();
            render();
        } else if (activeBox === 2 && hand2IsSplit) {
            // Hand 2 is split
            if (hand2ActiveHand === 1 && hand2Bet > 0) {
                bankroll += hand2Bet * 2;
                hand2Hand1Result = 'win';
                hand2Bet = 0;
                if (hand2SplitBet > 0) {
                    hand2ActiveHand = 2;
                } else if (hand2SplitBet2 > 0) {
                    hand2ActiveHand = 3;
                } else if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 2 && hand2SplitBet > 0) {
                bankroll += hand2SplitBet * 2;
                hand2Hand2Result = 'win';
                hand2SplitBet = 0;
                if (hand2SplitBet2 > 0) {
                    hand2ActiveHand = 3;
                } else if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 3 && hand2SplitBet2 > 0) {
                bankroll += hand2SplitBet2 * 2;
                hand2Hand3Result = 'win';
                hand2SplitBet2 = 0;
                if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 4 && hand2SplitBet3 > 0) {
                bankroll += hand2SplitBet3 * 2;
                hand2Hand4Result = 'win';
                hand2SplitBet3 = 0;
                finishTwoHandsSplit(2);
                hand2Complete = true;
                hand2IsSplit = false;
                if (!checkTwoHandsComplete()) moveToNextHand();
            }
            saveToStorage();
            render();
        } else if (activeBox === 1 && !isSplit && bet > 0) {
            // Hand 1 not split, hand 2 is split
            const winAmount = bet;
            const totalPayout = bet * 2;
            lastBet = bet;
            hand1WinAmount = totalPayout;
            bankroll += bet * 2;
            stats.wins++;
            stats.handsPlayed++;
            stats.totalWon += winAmount;
            if (winAmount > stats.biggestWin) stats.biggestWin = winAmount;
            bet = 0;
            status = 'win';
            isDoubleDown = false;
            hand1Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        } else if (activeBox === 2 && !hand2IsSplit && hand2Bet > 0) {
            // Hand 2 not split, hand 1 is split
            const winAmount = hand2Bet;
            const totalPayout = hand2Bet * 2;
            lastBet = hand2Bet;
            hand2WinAmount = totalPayout;
            bankroll += hand2Bet * 2;
            stats.wins++;
            stats.handsPlayed++;
            stats.totalWon += winAmount;
            if (winAmount > stats.biggestWin) stats.biggestWin = winAmount;
            hand2Bet = 0;
            hand2Status = 'win';
            hand2IsDoubleDown = false;
            hand2Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        }
    } else if (isSplit) {
        if (activeHand === 1 && bet > 0) {
            bankroll += bet * 2;
            hand1Result = 'win';
            bet = 0;
            if (splitBet > 0) {
                activeHand = 2;
            } else if (splitBet2 > 0) {
                activeHand = 3;
            } else if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 2 && splitBet > 0) {
            bankroll += splitBet * 2;
            hand2Result = 'win';
            splitBet = 0;
            if (splitBet2 > 0) {
                activeHand = 3;
            } else if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 3 && splitBet2 > 0) {
            bankroll += splitBet2 * 2;
            hand3Result = 'win';
            splitBet2 = 0;
            if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 4 && splitBet3 > 0) {
            bankroll += splitBet3 * 2;
            hand4Result = 'win';
            splitBet3 = 0;
            finishSplit();
        }
        render();
    } else if (twoHandsMode && betConfirmed) {
        // Two hands mode
        if (activeBox === 1 && bet > 0) {
            const winAmount = bet;
            const totalPayout = bet * 2;
            hand1WinAmount = totalPayout; // Track total payout for display
            lastWinAmount = bet;
            lastTotalPayout = totalPayout;
            lastBet = isDoubleDown ? bet / 2 : bet;
            bankroll += bet * 2;
            stats.wins++;
            stats.handsPlayed++;
            stats.totalWon += winAmount;
            if (winAmount > stats.biggestWin) stats.biggestWin = winAmount;
            bet = 0;
            status = 'win';
            updateStreak('win');
            isDoubleDown = false;
            hand1Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        } else if (activeBox === 2 && hand2Bet > 0) {
            const winAmount = hand2Bet;
            const totalPayout = hand2Bet * 2;
            hand2WinAmount = totalPayout; // Track total payout for display
            lastWinAmount = hand2Bet;
            lastTotalPayout = totalPayout;
            lastBet = hand2IsDoubleDown ? hand2Bet / 2 : hand2Bet;
            bankroll += hand2Bet * 2;
            stats.wins++;
            stats.handsPlayed++;
            stats.totalWon += winAmount;
            if (winAmount > stats.biggestWin) stats.biggestWin = winAmount;
            hand2Bet = 0;
            hand2Status = 'win';
            updateStreak('win');
            hand2IsDoubleDown = false;
            hand2Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        }
    } else if (bet > 0) {
        const winAmount = bet; // Net profit (equals doubled bet if DD)
        const totalPayout = bet * 2; // Total returned (bet + winnings)
        lastWinAmount = bet; // Show profit in banner (the full doubled bet)
        lastTotalPayout = totalPayout; // Total amount returned
        lastBet = isDoubleDown ? bet / 2 : bet;
        bankroll += bet * 2;
        
        // Update stats
        stats.wins++;
        stats.handsPlayed++;
        stats.totalWon += winAmount;
        if (winAmount > stats.biggestWin) stats.biggestWin = winAmount;
        
        bet = 0;
        status = 'win';
        isDoubleDown = false;
        isDealing = false;
        updateStreak('win');
        playSound('win');
        endRound();
        if (autoRebet) doAutoRebet();
        saveToStorage();
        render();
    }
}

// Blackjack 3:2
function blackjack() {
    // Two hands mode with split within a box
    if (twoHandsMode && betConfirmed && (isSplit || hand2IsSplit)) {
        if (activeBox === 1 && isSplit) {
            if (activeHand === 1 && bet > 0) {
                bankroll += Math.floor(bet * 2.5);
                hand1Result = 'blackjack';
                bet = 0;
                if (splitBet > 0) {
                    activeHand = 2;
                } else if (splitBet2 > 0) {
                    activeHand = 3;
                } else if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 2 && splitBet > 0) {
                bankroll += Math.floor(splitBet * 2.5);
                hand2Result = 'blackjack';
                splitBet = 0;
                if (splitBet2 > 0) {
                    activeHand = 3;
                } else if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 3 && splitBet2 > 0) {
                bankroll += Math.floor(splitBet2 * 2.5);
                hand3Result = 'blackjack';
                splitBet2 = 0;
                if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 4 && splitBet3 > 0) {
                bankroll += Math.floor(splitBet3 * 2.5);
                hand4Result = 'blackjack';
                splitBet3 = 0;
                finishTwoHandsSplit(1);
                hand1Complete = true;
                isSplit = false;
                if (!checkTwoHandsComplete()) moveToNextHand();
            }
            saveToStorage();
            render();
        } else if (activeBox === 2 && hand2IsSplit) {
            if (hand2ActiveHand === 1 && hand2Bet > 0) {
                bankroll += Math.floor(hand2Bet * 2.5);
                hand2Hand1Result = 'blackjack';
                hand2Bet = 0;
                if (hand2SplitBet > 0) {
                    hand2ActiveHand = 2;
                } else if (hand2SplitBet2 > 0) {
                    hand2ActiveHand = 3;
                } else if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 2 && hand2SplitBet > 0) {
                bankroll += Math.floor(hand2SplitBet * 2.5);
                hand2Hand2Result = 'blackjack';
                hand2SplitBet = 0;
                if (hand2SplitBet2 > 0) {
                    hand2ActiveHand = 3;
                } else if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 3 && hand2SplitBet2 > 0) {
                bankroll += Math.floor(hand2SplitBet2 * 2.5);
                hand2Hand3Result = 'blackjack';
                hand2SplitBet2 = 0;
                if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 4 && hand2SplitBet3 > 0) {
                bankroll += Math.floor(hand2SplitBet3 * 2.5);
                hand2Hand4Result = 'blackjack';
                hand2SplitBet3 = 0;
                finishTwoHandsSplit(2);
                hand2Complete = true;
                hand2IsSplit = false;
                if (!checkTwoHandsComplete()) moveToNextHand();
            }
            saveToStorage();
            render();
        } else if (activeBox === 1 && !isSplit && bet > 0) {
            const winAmount = Math.floor(bet * 1.5);
            const totalPayout = Math.floor(bet * 2.5);
            lastBet = bet;
            hand1WinAmount = totalPayout;
            bankroll += Math.floor(bet * 2.5);
            stats.blackjacks++;
            stats.wins++;
            stats.handsPlayed++;
            stats.totalWon += winAmount;
            if (winAmount > stats.biggestWin) stats.biggestWin = winAmount;
            bet = 0;
            status = 'blackjack';
            isDoubleDown = false;
            hand1Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        } else if (activeBox === 2 && !hand2IsSplit && hand2Bet > 0) {
            const winAmount = Math.floor(hand2Bet * 1.5);
            const totalPayout = Math.floor(hand2Bet * 2.5);
            lastBet = hand2Bet;
            hand2WinAmount = totalPayout;
            bankroll += Math.floor(hand2Bet * 2.5);
            stats.blackjacks++;
            stats.wins++;
            stats.handsPlayed++;
            stats.totalWon += winAmount;
            if (winAmount > stats.biggestWin) stats.biggestWin = winAmount;
            hand2Bet = 0;
            hand2Status = 'blackjack';
            hand2IsDoubleDown = false;
            hand2Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        }
    } else if (isSplit) {
        if (activeHand === 1 && bet > 0) {
            bankroll += Math.floor(bet * 2.5);
            hand1Result = 'blackjack';
            stats.blackjacks++;
            bet = 0;
            if (splitBet > 0) {
                activeHand = 2;
            } else if (splitBet2 > 0) {
                activeHand = 3;
            } else if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 2 && splitBet > 0) {
            bankroll += Math.floor(splitBet * 2.5);
            hand2Result = 'blackjack';
            stats.blackjacks++;
            splitBet = 0;
            if (splitBet2 > 0) {
                activeHand = 3;
            } else if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 3 && splitBet2 > 0) {
            bankroll += Math.floor(splitBet2 * 2.5);
            hand3Result = 'blackjack';
            stats.blackjacks++;
            splitBet2 = 0;
            if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 4 && splitBet3 > 0) {
            bankroll += Math.floor(splitBet3 * 2.5);
            hand4Result = 'blackjack';
            stats.blackjacks++;
            splitBet3 = 0;
            finishSplit();
        }
        render();
    } else if (twoHandsMode && betConfirmed) {
        // Two hands mode
        if (activeBox === 1 && bet > 0) {
            const winAmount = Math.floor(bet * 1.5);
            const totalPayout = Math.floor(bet * 2.5);
            hand1WinAmount = totalPayout; // Track total payout for display
            lastWinAmount = winAmount;
            lastTotalPayout = totalPayout;
            lastBet = isDoubleDown ? bet / 2 : bet;
            bankroll += Math.floor(bet * 2.5);
            stats.blackjacks++;
            stats.wins++;
            stats.handsPlayed++;
            stats.totalWon += winAmount;
            if (winAmount > stats.biggestWin) stats.biggestWin = winAmount;
            bet = 0;
            status = 'blackjack';
            updateStreak('blackjack');
            isDoubleDown = false;
            hand1Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        } else if (activeBox === 2 && hand2Bet > 0) {
            const winAmount = Math.floor(hand2Bet * 1.5);
            const totalPayout = Math.floor(hand2Bet * 2.5);
            hand2WinAmount = totalPayout; // Track total payout for display
            lastWinAmount = winAmount;
            lastTotalPayout = totalPayout;
            lastBet = hand2IsDoubleDown ? hand2Bet / 2 : hand2Bet;
            bankroll += Math.floor(hand2Bet * 2.5);
            stats.blackjacks++;
            stats.wins++;
            stats.handsPlayed++;
            stats.totalWon += winAmount;
            if (winAmount > stats.biggestWin) stats.biggestWin = winAmount;
            hand2Bet = 0;
            hand2Status = 'blackjack';
            updateStreak('blackjack');
            hand2IsDoubleDown = false;
            hand2Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        }
    } else if (bet > 0) {
        const winAmount = Math.floor(bet * 1.5); // Net profit (3:2)
        const totalPayout = Math.floor(bet * 2.5); // Total returned (bet + 3:2 winnings)
        lastWinAmount = winAmount; // Show profit in banner
        lastTotalPayout = totalPayout; // Total amount returned
        lastBet = isDoubleDown ? bet / 2 : bet;
        bankroll += Math.floor(bet * 2.5);
        
        // Update stats
        stats.blackjacks++;
        stats.wins++;
        stats.handsPlayed++;
        stats.totalWon += winAmount;
        if (winAmount > stats.biggestWin) stats.biggestWin = winAmount;
        
        bet = 0;
        status = 'blackjack';
        isDoubleDown = false;
        isDealing = false;
        updateStreak('blackjack');
        playSound('blackjack');
        endRound();
        if (autoRebet) doAutoRebet();
        saveToStorage();
        render();
    }
}

// Push - return bet
function push() {
    // Two hands mode with split within a box
    if (twoHandsMode && betConfirmed && (isSplit || hand2IsSplit)) {
        if (activeBox === 1 && isSplit) {
            if (activeHand === 1 && bet > 0) {
                bankroll += bet;
                hand1Result = 'push';
                bet = 0;
                if (splitBet > 0) {
                    activeHand = 2;
                } else if (splitBet2 > 0) {
                    activeHand = 3;
                } else if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 2 && splitBet > 0) {
                bankroll += splitBet;
                hand2Result = 'push';
                splitBet = 0;
                if (splitBet2 > 0) {
                    activeHand = 3;
                } else if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 3 && splitBet2 > 0) {
                bankroll += splitBet2;
                hand3Result = 'push';
                splitBet2 = 0;
                if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 4 && splitBet3 > 0) {
                bankroll += splitBet3;
                hand4Result = 'push';
                splitBet3 = 0;
                finishTwoHandsSplit(1);
                hand1Complete = true;
                isSplit = false;
                if (!checkTwoHandsComplete()) moveToNextHand();
            }
            saveToStorage();
            render();
        } else if (activeBox === 2 && hand2IsSplit) {
            if (hand2ActiveHand === 1 && hand2Bet > 0) {
                bankroll += hand2Bet;
                hand2Hand1Result = 'push';
                hand2Bet = 0;
                if (hand2SplitBet > 0) {
                    hand2ActiveHand = 2;
                } else if (hand2SplitBet2 > 0) {
                    hand2ActiveHand = 3;
                } else if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 2 && hand2SplitBet > 0) {
                bankroll += hand2SplitBet;
                hand2Hand2Result = 'push';
                hand2SplitBet = 0;
                if (hand2SplitBet2 > 0) {
                    hand2ActiveHand = 3;
                } else if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 3 && hand2SplitBet2 > 0) {
                bankroll += hand2SplitBet2;
                hand2Hand3Result = 'push';
                hand2SplitBet2 = 0;
                if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 4 && hand2SplitBet3 > 0) {
                bankroll += hand2SplitBet3;
                hand2Hand4Result = 'push';
                hand2SplitBet3 = 0;
                finishTwoHandsSplit(2);
                hand2Complete = true;
                hand2IsSplit = false;
                if (!checkTwoHandsComplete()) moveToNextHand();
            }
            saveToStorage();
            render();
        } else if (activeBox === 1 && !isSplit && bet > 0) {
            lastBet = bet;
            bankroll += bet;
            stats.pushes++;
            stats.handsPlayed++;
            bet = 0;
            status = 'push';
            isDoubleDown = false;
            hand1Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        } else if (activeBox === 2 && !hand2IsSplit && hand2Bet > 0) {
            lastBet = hand2Bet;
            bankroll += hand2Bet;
            stats.pushes++;
            stats.handsPlayed++;
            hand2Bet = 0;
            hand2Status = 'push';
            hand2IsDoubleDown = false;
            hand2Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        }
    } else if (isSplit) {
        if (activeHand === 1 && bet > 0) {
            bankroll += bet;
            hand1Result = 'push';
            bet = 0;
            if (splitBet > 0) {
                activeHand = 2;
            } else if (splitBet2 > 0) {
                activeHand = 3;
            } else if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 2 && splitBet > 0) {
            bankroll += splitBet;
            hand2Result = 'push';
            splitBet = 0;
            if (splitBet2 > 0) {
                activeHand = 3;
            } else if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 3 && splitBet2 > 0) {
            bankroll += splitBet2;
            hand3Result = 'push';
            splitBet2 = 0;
            if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 4 && splitBet3 > 0) {
            bankroll += splitBet3;
            hand4Result = 'push';
            splitBet3 = 0;
            finishSplit();
        }
        render();
    } else if (twoHandsMode && betConfirmed) {
        // Two hands mode
        if (activeBox === 1 && bet > 0) {
            hand1WinAmount = bet; // Track bet returned for display
            lastWinAmount = bet;
            lastBet = isDoubleDown ? bet / 2 : bet;
            bankroll += bet;
            stats.pushes++;
            stats.handsPlayed++;
            bet = 0;
            status = 'push';
            isDoubleDown = false;
            hand1Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        } else if (activeBox === 2 && hand2Bet > 0) {
            hand2WinAmount = hand2Bet; // Track bet returned for display
            lastWinAmount = hand2Bet;
            lastBet = hand2IsDoubleDown ? hand2Bet / 2 : hand2Bet;
            bankroll += hand2Bet;
            stats.pushes++;
            stats.handsPlayed++;
            hand2Bet = 0;
            hand2Status = 'push';
            hand2IsDoubleDown = false;
            hand2Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        }
    } else if (bet > 0) {
        lastWinAmount = bet; // Bet returned
        lastBet = isDoubleDown ? bet / 2 : bet;
        bankroll += bet;
        
        // Update stats
        stats.pushes++;
        stats.handsPlayed++;
        
        bet = 0;
        status = 'push';
        isDoubleDown = false;
        isDealing = false;
        playSound('push');
        endRound();
        if (autoRebet) doAutoRebet();
        saveToStorage();
        render();
    }
}

// Lose
function lose() {
    // Two hands mode with split within a box
    if (twoHandsMode && betConfirmed && (isSplit || hand2IsSplit)) {
        if (activeBox === 1 && isSplit) {
            if (activeHand === 1 && bet > 0) {
                hand1Result = 'lose';
                bet = 0;
                if (splitBet > 0) {
                    activeHand = 2;
                } else if (splitBet2 > 0) {
                    activeHand = 3;
                } else if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 2 && splitBet > 0) {
                hand2Result = 'lose';
                splitBet = 0;
                if (splitBet2 > 0) {
                    activeHand = 3;
                } else if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 3 && splitBet2 > 0) {
                hand3Result = 'lose';
                splitBet2 = 0;
                if (splitBet3 > 0) {
                    activeHand = 4;
                } else {
                    finishTwoHandsSplit(1);
                    hand1Complete = true;
                    isSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (activeHand === 4 && splitBet3 > 0) {
                hand4Result = 'lose';
                splitBet3 = 0;
                finishTwoHandsSplit(1);
                hand1Complete = true;
                isSplit = false;
                if (!checkTwoHandsComplete()) moveToNextHand();
            }
            saveToStorage();
            render();
        } else if (activeBox === 2 && hand2IsSplit) {
            if (hand2ActiveHand === 1 && hand2Bet > 0) {
                hand2Hand1Result = 'lose';
                hand2Bet = 0;
                if (hand2SplitBet > 0) {
                    hand2ActiveHand = 2;
                } else if (hand2SplitBet2 > 0) {
                    hand2ActiveHand = 3;
                } else if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 2 && hand2SplitBet > 0) {
                hand2Hand2Result = 'lose';
                hand2SplitBet = 0;
                if (hand2SplitBet2 > 0) {
                    hand2ActiveHand = 3;
                } else if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 3 && hand2SplitBet2 > 0) {
                hand2Hand3Result = 'lose';
                hand2SplitBet2 = 0;
                if (hand2SplitBet3 > 0) {
                    hand2ActiveHand = 4;
                } else {
                    finishTwoHandsSplit(2);
                    hand2Complete = true;
                    hand2IsSplit = false;
                    if (!checkTwoHandsComplete()) moveToNextHand();
                }
            } else if (hand2ActiveHand === 4 && hand2SplitBet3 > 0) {
                hand2Hand4Result = 'lose';
                hand2SplitBet3 = 0;
                finishTwoHandsSplit(2);
                hand2Complete = true;
                hand2IsSplit = false;
                if (!checkTwoHandsComplete()) moveToNextHand();
            }
            saveToStorage();
            render();
        } else if (activeBox === 1 && !isSplit && bet > 0) {
            lastBet = bet;
            stats.losses++;
            stats.handsPlayed++;
            stats.totalLost += bet;
            bet = 0;
            status = 'lose';
            isDoubleDown = false;
            hand1Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        } else if (activeBox === 2 && !hand2IsSplit && hand2Bet > 0) {
            lastBet = hand2Bet;
            stats.losses++;
            stats.handsPlayed++;
            stats.totalLost += hand2Bet;
            hand2Bet = 0;
            hand2Status = 'lose';
            hand2IsDoubleDown = false;
            hand2Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        }
    } else if (isSplit) {
        if (activeHand === 1 && bet > 0) {
            hand1Result = 'lose';
            bet = 0;
            if (splitBet > 0) {
                activeHand = 2;
            } else if (splitBet2 > 0) {
                activeHand = 3;
            } else if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 2 && splitBet > 0) {
            hand2Result = 'lose';
            splitBet = 0;
            if (splitBet2 > 0) {
                activeHand = 3;
            } else if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 3 && splitBet2 > 0) {
            hand3Result = 'lose';
            splitBet2 = 0;
            if (splitBet3 > 0) {
                activeHand = 4;
            } else {
                finishSplit();
            }
        } else if (activeHand === 4 && splitBet3 > 0) {
            hand4Result = 'lose';
            splitBet3 = 0;
            finishSplit();
        }
        render();
    } else if (twoHandsMode && betConfirmed) {
        // Two hands mode
        if (activeBox === 1 && bet > 0) {
            const lostAmount = bet;
            hand1WinAmount = -lostAmount; // Negative value for loss
            lastWinAmount = bet;
            lastBet = isDoubleDown ? bet / 2 : bet;
            stats.losses++;
            stats.handsPlayed++;
            stats.totalLost += lostAmount;
            bet = 0;
            status = 'lose';
            updateStreak('lose');
            isDoubleDown = false;
            hand1Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        } else if (activeBox === 2 && hand2Bet > 0) {
            const lostAmount = hand2Bet;
            hand2WinAmount = -lostAmount; // Negative value for loss
            lastWinAmount = hand2Bet;
            lastBet = hand2IsDoubleDown ? hand2Bet / 2 : hand2Bet;
            stats.losses++;
            stats.handsPlayed++;
            stats.totalLost += lostAmount;
            hand2Bet = 0;
            hand2Status = 'lose';
            updateStreak('lose');
            hand2IsDoubleDown = false;
            hand2Complete = true;
            if (!checkTwoHandsComplete()) moveToNextHand();
            saveToStorage();
            render();
        }
    } else if (bet > 0) {
        const lostAmount = bet;
        lastWinAmount = bet; // Amount lost
        lastBet = isDoubleDown ? bet / 2 : bet;
        
        // Update stats
        stats.losses++;
        stats.handsPlayed++;
        stats.totalLost += lostAmount;
        
        bet = 0;
        status = 'lose';
        isDoubleDown = false;
        isDealing = false;
        updateStreak('lose');
        playSound('lose');
        endRound();
        if (autoRebet) doAutoRebet();
        saveToStorage();
        render();
    }
}

// Finish split hands in two-hands mode - calculate stats and totals
function finishTwoHandsSplit(box) {
    let wins = 0;
    let losses = 0;
    let pushes = 0;
    let totalWon = 0;
    let totalLost = 0;
    let handCount = 0;
    let blackjacks = 0;
    
    if (box === 1) {
        handCount = splitCount + 1;
        
        // Get actual bet amounts (accounting for DD)
        const h1Bet = split1DD ? splitOriginalBet * 2 : splitOriginalBet;
        const h2Bet = split2DD ? splitOriginalBet * 2 : splitOriginalBet;
        const h3Bet = split3DD ? splitOriginalBet * 2 : splitOriginalBet;
        const h4Bet = split4DD ? splitOriginalBet * 2 : splitOriginalBet;
        
        // Calculate results for each hand
        if (hand1Result === 'win') { wins++; totalWon += h1Bet; }
        else if (hand1Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(h1Bet * 1.5); }
        else if (hand1Result === 'lose') { losses++; totalLost += h1Bet; }
        else if (hand1Result === 'push') { pushes++; }
        
        if (hand2Result === 'win') { wins++; totalWon += h2Bet; }
        else if (hand2Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(h2Bet * 1.5); }
        else if (hand2Result === 'lose') { losses++; totalLost += h2Bet; }
        else if (hand2Result === 'push') { pushes++; }
        
        if (hand3Result) {
            if (hand3Result === 'win') { wins++; totalWon += h3Bet; }
            else if (hand3Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(h3Bet * 1.5); }
            else if (hand3Result === 'lose') { losses++; totalLost += h3Bet; }
            else if (hand3Result === 'push') { pushes++; }
        }
        
        if (hand4Result) {
            if (hand4Result === 'win') { wins++; totalWon += h4Bet; }
            else if (hand4Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(h4Bet * 1.5); }
            else if (hand4Result === 'lose') { losses++; totalLost += h4Bet; }
            else if (hand4Result === 'push') { pushes++; }
        }
        
        // Set hand1WinAmount for combined display
        if (wins > losses) {
            status = 'win';
            hand1WinAmount = totalWon * 2; // Payout (winnings + bet back)
        } else if (losses > wins) {
            status = 'lose';
            hand1WinAmount = -totalLost; // Negative for losses
        } else {
            status = 'push';
            hand1WinAmount = totalWon > 0 ? totalWon * 2 : 0;
        }
        
        // Update streak
        if (wins > losses) updateStreak('win');
        else if (losses > wins) updateStreak('lose');
        
        // Reset split state for hand 1
        lastBet = splitOriginalBet;
        splitOriginalBet = 0;
        
    } else { // box === 2
        handCount = hand2SplitCount + 1;
        
        // Get actual bet amounts (accounting for DD)
        const h1Bet = hand2Split1DD ? hand2SplitOriginalBet * 2 : hand2SplitOriginalBet;
        const h2Bet = hand2Split2DD ? hand2SplitOriginalBet * 2 : hand2SplitOriginalBet;
        const h3Bet = hand2Split3DD ? hand2SplitOriginalBet * 2 : hand2SplitOriginalBet;
        const h4Bet = hand2Split4DD ? hand2SplitOriginalBet * 2 : hand2SplitOriginalBet;
        
        // Calculate results for each hand
        if (hand2Hand1Result === 'win') { wins++; totalWon += h1Bet; }
        else if (hand2Hand1Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(h1Bet * 1.5); }
        else if (hand2Hand1Result === 'lose') { losses++; totalLost += h1Bet; }
        else if (hand2Hand1Result === 'push') { pushes++; }
        
        if (hand2Hand2Result === 'win') { wins++; totalWon += h2Bet; }
        else if (hand2Hand2Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(h2Bet * 1.5); }
        else if (hand2Hand2Result === 'lose') { losses++; totalLost += h2Bet; }
        else if (hand2Hand2Result === 'push') { pushes++; }
        
        if (hand2Hand3Result) {
            if (hand2Hand3Result === 'win') { wins++; totalWon += h3Bet; }
            else if (hand2Hand3Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(h3Bet * 1.5); }
            else if (hand2Hand3Result === 'lose') { losses++; totalLost += h3Bet; }
            else if (hand2Hand3Result === 'push') { pushes++; }
        }
        
        if (hand2Hand4Result) {
            if (hand2Hand4Result === 'win') { wins++; totalWon += h4Bet; }
            else if (hand2Hand4Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(h4Bet * 1.5); }
            else if (hand2Hand4Result === 'lose') { losses++; totalLost += h4Bet; }
            else if (hand2Hand4Result === 'push') { pushes++; }
        }
        
        // Set hand2WinAmount for combined display
        if (wins > losses) {
            hand2Status = 'win';
            hand2WinAmount = totalWon * 2; // Payout (winnings + bet back)
        } else if (losses > wins) {
            hand2Status = 'lose';
            hand2WinAmount = -totalLost; // Negative for losses
        } else {
            hand2Status = 'push';
            hand2WinAmount = totalWon > 0 ? totalWon * 2 : 0;
        }
        
        // Update streak
        if (wins > losses) updateStreak('win');
        else if (losses > wins) updateStreak('lose');
        
        // Reset split state for hand 2
        lastBet = hand2SplitOriginalBet;
        hand2SplitOriginalBet = 0;
    }
    
    // Update stats
    stats.handsPlayed += handCount;
    stats.wins += wins;
    stats.losses += losses;
    stats.pushes += pushes;
    stats.blackjacks += blackjacks;
    stats.totalWon += totalWon;
    stats.totalLost += totalLost;
    if (totalWon > stats.biggestWin) stats.biggestWin = totalWon;
}

// Finish split and calculate total result
function finishSplit() {
    let wins = 0;
    let losses = 0;
    let pushes = 0;
    let blackjacks = 0;
    let totalWon = 0;
    let totalLost = 0;
    let totalBet = 0;
    let handCount = splitCount + 1; // splitCount 1 = 2 hands, 2 = 3 hands, 3 = 4 hands
    
    // Get actual bet amounts (accounting for DD)
    const hand1Bet = split1DD ? splitOriginalBet * 2 : splitOriginalBet;
    const hand2Bet = split2DD ? splitOriginalBet * 2 : splitOriginalBet;
    const hand3Bet = split3DD ? splitOriginalBet * 2 : splitOriginalBet;
    const hand4Bet = split4DD ? splitOriginalBet * 2 : splitOriginalBet;
    
    // Calculate results for each hand
    if (hand1Result === 'win') { wins++; totalWon += hand1Bet; totalBet += hand1Bet; }
    else if (hand1Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(hand1Bet * 1.5); totalBet += hand1Bet; }
    else if (hand1Result === 'lose') { losses++; totalLost += hand1Bet; totalBet += hand1Bet; }
    else if (hand1Result === 'push') { pushes++; totalBet += hand1Bet; }
    
    if (hand2Result === 'win') { wins++; totalWon += hand2Bet; totalBet += hand2Bet; }
    else if (hand2Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(hand2Bet * 1.5); totalBet += hand2Bet; }
    else if (hand2Result === 'lose') { losses++; totalLost += hand2Bet; totalBet += hand2Bet; }
    else if (hand2Result === 'push') { pushes++; totalBet += hand2Bet; }
    
    // Third hand if exists
    if (hand3Result) {
        if (hand3Result === 'win') { wins++; totalWon += hand3Bet; totalBet += hand3Bet; }
        else if (hand3Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(hand3Bet * 1.5); totalBet += hand3Bet; }
        else if (hand3Result === 'lose') { losses++; totalLost += hand3Bet; totalBet += hand3Bet; }
        else if (hand3Result === 'push') { pushes++; totalBet += hand3Bet; }
    }
    
    // Fourth hand if exists
    if (hand4Result) {
        if (hand4Result === 'win') { wins++; totalWon += hand4Bet; totalBet += hand4Bet; }
        else if (hand4Result === 'blackjack') { wins++; blackjacks++; totalWon += Math.floor(hand4Bet * 1.5); totalBet += hand4Bet; }
        else if (hand4Result === 'lose') { losses++; totalLost += hand4Bet; totalBet += hand4Bet; }
        else if (hand4Result === 'push') { pushes++; totalBet += hand4Bet; }
    }
    
    // Set lastWinAmount for banner
    if (wins > losses) {
        status = 'win';
        lastWinAmount = totalWon;
        lastTotalPayout = totalWon + totalBet; // Winnings + returned bets
        playSound('win');
    } else if (losses > wins) {
        status = 'lose';
        lastWinAmount = totalLost - totalWon;
        lastTotalPayout = 0;
        playSound('lose');
    } else {
        status = 'push';
        lastWinAmount = totalBet;
        lastTotalPayout = totalBet;
        playSound('push');
    }
    
    // Update streak based on overall split result
    if (wins > losses) {
        updateStreak('win');
    } else if (losses > wins) {
        updateStreak('lose');
    }
    
    // Update stats (count as 2 or 3 hands)
    stats.handsPlayed += handCount;
    stats.wins += wins;
    stats.losses += losses;
    stats.pushes += pushes;
    stats.blackjacks += blackjacks;
    stats.totalWon += totalWon;
    stats.totalLost += totalLost;
    if (totalWon > stats.biggestWin) stats.biggestWin = totalWon;
    
    lastBet = splitOriginalBet; // Set lastBet to original single bet
    isSplit = false;
    activeHand = 1;
    splitOriginalBet = 0;
    isDealing = false;
    endRound();
    if (autoRebet) doAutoRebet();
    saveToStorage();
}

// Auto rebet helper
function doAutoRebet() {
    if (lastBet > 0 && lastBet <= bankroll && bet === 0 && !betConfirmed && !isDealing) {
        playSound('push');
        bet = lastBet;
        bankroll -= lastBet;
        if (twoHandsMode && hand2Bet === 0 && lastBet <= bankroll) {
            // Also place bet on hand 2 in two hands mode
            hand2Bet = lastBet;
            bankroll -= lastBet;
        }
        saveToStorage();
        render();
    }
}

// All In - bet entire bankroll
function allIn() {
    if (bankroll > 0 && !betConfirmed && !isDealing) {
        playSound('push');
        const amount = bankroll;
        betHistory.push({ type: 'allIn', amount: amount, box: twoHandsMode ? activeBox : 1 });
        if (twoHandsMode) {
            if (activeBox === 1) {
                bet += amount;
            } else {
                hand2Bet += amount;
            }
        } else {
            bet += amount;
        }
        bankroll = 0;
        saveToStorage();
        render();
    }
}

// Toggle auto rebet
function toggleAutoRebet() {
    playSound('push');
    autoRebet = !autoRebet;
    saveToStorage();
    render();
}

// New Game - reset everything
function newGame() {
    playSound('push');
    bankroll = 0;
    bet = 0;
    lastBet = 0;
    status = '';
    autoRebet = false;
    gameStarted = false;
    twoHandsMode = false;
    hand2Bet = 0;
    hand2Status = '';
    hand2IsDoubleDown = false;
    activeBox = 1;
    hand1Complete = false;
    hand2Complete = false;
    hand1WinAmount = 0;
    hand2WinAmount = 0;
    // Reset hand 1 split state
    isSplit = false;
    splitCount = 0;
    splitBet = 0;
    splitBet2 = 0;
    splitBet3 = 0;
    activeHand = 1;
    hand1Result = '';
    hand2Result = '';
    hand3Result = '';
    hand4Result = '';
    splitOriginalBet = 0;
    split1DD = false;
    split2DD = false;
    split3DD = false;
    split4DD = false;
    // Reset hand 2 split state
    hand2IsSplit = false;
    hand2SplitCount = 0;
    hand2SplitBet = 0;
    hand2SplitBet2 = 0;
    hand2SplitBet3 = 0;
    hand2ActiveHand = 1;
    hand2Hand1Result = '';
    hand2Hand2Result = '';
    hand2Hand3Result = '';
    hand2Hand4Result = '';
    hand2SplitOriginalBet = 0;
    hand2Split1DD = false;
    hand2Split2DD = false;
    hand2Split3DD = false;
    hand2Split4DD = false;
    // Reset other state
    isDoubleDown = false;
    hasInsurance = false;
    hasSurrendered = false;
    hand2HasSurrendered = false;
    insuranceBet = 0;
    roundNumber = 0;
    roundInProgress = false;
    betConfirmed = false;
    isDealing = false;
    lastWinAmount = 0;
    lastTotalPayout = 0;
    betHistory = [];
    currentStreak = 0;
    streakType = '';
    // Keep stats but clear cloud data for fresh start
    if (typeof deleteFromCloud === 'function') {
        deleteFromCloud('blackjack');
    }
    render();
}

// Reset stats only (keep chips)
function resetStats() {
    playSound('push');
    stats = { wins: 0, losses: 0, pushes: 0, blackjacks: 0, totalWon: 0, totalLost: 0, biggestWin: 0, handsPlayed: 0 };
    saveToStorage();
    render();
}

// ==================== LEADERBOARD FUNCTIONS ====================

// Save current score to leaderboard
function saveHighscore() {
    const name = prompt('Enter your name for the leaderboard:', 'Player');
    if (!name || name.trim() === '') return;
    
    playSound('win');
    
    const winRate = stats.handsPlayed > 0 ? Math.round((stats.wins / stats.handsPlayed) * 100) : 0;
    const netProfit = stats.totalWon - stats.totalLost;
    
    const entry = {
        name: name.trim().substring(0, 20), // Limit name length
        bankroll: bankroll,
        netProfit: netProfit,
        winRate: winRate,
        handsPlayed: stats.handsPlayed,
        wins: stats.wins,
        losses: stats.losses,
        pushes: stats.pushes,
        blackjacks: stats.blackjacks,
        biggestWin: stats.biggestWin,
        date: new Date().toLocaleDateString(),
        timestamp: Date.now()
    };
    
    leaderboard.push(entry);
    // Sort by bankroll (highest first)
    leaderboard.sort((a, b) => b.bankroll - a.bankroll);
    // Keep only top 10
    if (leaderboard.length > 10) {
        leaderboard = leaderboard.slice(0, 10);
    }
    
    saveToStorage();
    showLeaderboard();
}

// Show leaderboard modal
function showLeaderboard() {
    playSound('click');
    
    // Remove existing modal if any
    const existingModal = document.querySelector('.leaderboard-modal');
    if (existingModal) existingModal.remove();
    
    const modal = document.createElement('div');
    modal.className = 'leaderboard-modal';
    
    let tableRows = '';
    if (leaderboard.length === 0) {
        tableRows = '<tr><td colspan="7" class="no-scores">No scores yet! Save your first highscore.</td></tr>';
    } else {
        leaderboard.forEach((entry, index) => {
            const medal = index === 0 ? '🥇' : (index === 1 ? '🥈' : (index === 2 ? '🥉' : (index + 1)));
            const profitClass = entry.netProfit >= 0 ? 'profit-positive' : 'profit-negative';
            tableRows += `
                <tr class="${index < 3 ? 'top-three' : ''}">
                    <td class="rank">${medal}</td>
                    <td class="player-name">${entry.name}</td>
                    <td class="bankroll">$${entry.bankroll.toLocaleString()}</td>
                    <td class="${profitClass}">${entry.netProfit >= 0 ? '+' : ''}$${entry.netProfit.toLocaleString()}</td>
                    <td>${entry.winRate}%</td>
                    <td>${entry.wins}/${entry.losses}/${entry.pushes}</td>
                    <td class="date">${entry.date}</td>
                </tr>
            `;
        });
    }
    
    modal.innerHTML = `
        <div class="leaderboard-content">
            <div class="leaderboard-header">
                <h2>🏆 Leaderboard</h2>
                <button class="close-leaderboard" onclick="closeLeaderboard()">✕</button>
            </div>
            <div class="leaderboard-table-container">
                <table class="leaderboard-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Player</th>
                            <th>Bankroll</th>
                            <th>Net Profit</th>
                            <th>Win %</th>
                            <th>W/L/P</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${tableRows}
                    </tbody>
                </table>
            </div>
            <div class="leaderboard-actions">
                <button class="save-score-btn" onclick="closeLeaderboard(); saveHighscore();" ${stats.handsPlayed > 0 ? '' : 'disabled'}>
                    💾 Save Current Score
                </button>
                <button class="clear-leaderboard-btn" onclick="clearLeaderboard()" ${leaderboard.length > 0 ? '' : 'disabled'}>
                    🗑️ Clear All
                </button>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    // Close on backdrop click
    modal.addEventListener('click', (e) => {
        if (e.target === modal) closeLeaderboard();
    });
}

// Close leaderboard modal
function closeLeaderboard() {
    const modal = document.querySelector('.leaderboard-modal');
    if (modal) {
        modal.classList.add('closing');
        setTimeout(() => modal.remove(), 200);
    }
}

// Clear all leaderboard entries
function clearLeaderboard() {
    if (confirm('Are you sure you want to clear the entire leaderboard?')) {
        playSound('click');
        leaderboard = [];
        saveToStorage();
        showLeaderboard(); // Refresh the modal
    }
}

// ==================== RENDER FUNCTIONS ====================

// Render both sides
function render() {
    renderTopStatusBar();
    renderPlayerSide();
    renderDealerSide();
    renderOutcomeBanner();
}

// Render top status bar with betting status or result
function renderTopStatusBar() {
    const container = document.getElementById('topStatusBar');
    if (!container) return;
    
    // Show result after round ends (when status is set but bet is 0 and not confirmed)
    if (status && !betConfirmed && !isDealing && gameStarted) {
        let resultClass = '';
        let resultText = '';
        let resultIcon = '';
        
        if (status === 'win') {
            resultClass = 'result-win';
            resultIcon = '';
            resultText = `WIN! $${lastTotalPayout}`;
        } else if (status === 'blackjack') {
            resultClass = 'result-blackjack';
            resultIcon = '';
            resultText = `BLACKJACK! $${lastTotalPayout}`;
        } else if (status === 'push') {
            resultClass = 'result-push';
            resultIcon = '';
            resultText = lastWinAmount > 0 ? `PUSH $${lastWinAmount} returned` : 'PUSH - Bet returned';
        } else if (status === 'lose') {
            resultClass = 'result-lose';
            resultIcon = '';
            resultText = `LOSE -$${lastWinAmount}`;
        } else if (status === 'surrender') {
            resultClass = 'result-lose';
            resultIcon = '';
            resultText = `SURRENDER -$${lastWinAmount}`;
        } else if (status === 'insurance-win') {
            resultClass = 'result-win';
            resultIcon = '';
            resultText = `INSURANCE WIN +$${lastWinAmount}`;
        }
        
        container.innerHTML = `
            <div class="top-status-container ${resultClass}">
                <div class="betting-status ${resultClass}">
                    ${resultIcon} ${resultText}
                </div>
            </div>
        `;
    } else if (!betConfirmed && !isDealing && !isSplit && !isDoubleDown && gameStarted) {
        const hasBet = twoHandsMode ? (bet > 0 || hand2Bet > 0) : bet > 0;
        
        container.innerHTML = `
            <div class="top-status-container">
                <div class="betting-status ${hasBet ? 'has-bet' : ''}">
                    ${hasBet ? '🟢 BETTING OPEN - Click Deal!' : '💰 Place Your Bet'}
                </div>
            </div>
        `;
    } else if (betConfirmed && !isSplit) {
        container.innerHTML = `
            <div class="top-status-container">
                <div class="betting-status playing">
                    🎰 CARDS DEALT - Select Outcome
                </div>
            </div>
        `;
    } else {
        container.innerHTML = '';
    }
}

// Render Player Side (left)
function renderPlayerSide() {
    const container = document.getElementById('playerSide');
    
    let betsDisplay = '';
    if (twoHandsMode && betConfirmed && (isSplit || hand2IsSplit)) {
        // Two hands mode with split - show split hands for the split box
        const currentBet = activeBox === 1 ? (isSplit ? getCurrentSplitBet() : bet) : (hand2IsSplit ? getHand2CurrentSplitBet() : hand2Bet);
        const showPlayingInfo = !hand1Complete || !hand2Complete;
        
        // Hand 1 display (may or may not be split)
        let hand1Section = '';
        if (isSplit) {
            hand1Section = `
                <div class="split-in-two-hands ${activeBox === 1 ? 'active-box' : ''}">
                    <div class="split-box-label">Hand 1 (Split${splitCount >= 2 ? ' x' + (splitCount + 1) : ''})</div>
                    <div class="split-hands-mini ${splitCount >= 2 ? (splitCount === 3 ? 'four-hands' : 'three-hands') : ''}">
                        <div class="split-hand-mini ${activeBox === 1 && activeHand === 1 ? 'active-hand' : ''} ${hand1Result ? 'hand-' + hand1Result : ''}" onclick="activeBox = 1; activeHand = 1; render()">
                            <span class="hand-label">1A</span>
                            ${formatSplitHandDisplay(hand1Result, bet, 1, 1)}
                            ${hand1Result ? '<span class="hand-result">' + hand1Result.toUpperCase() + '</span>' : ''}
                        </div>
                        <div class="split-hand-mini ${activeBox === 1 && activeHand === 2 ? 'active-hand' : ''} ${hand2Result ? 'hand-' + hand2Result : ''}" onclick="activeBox = 1; activeHand = 2; render()">
                            <span class="hand-label">1B</span>
                            ${formatSplitHandDisplay(hand2Result, splitBet, 2, 1)}
                            ${hand2Result ? '<span class="hand-result">' + hand2Result.toUpperCase() + '</span>' : ''}
                        </div>
                        ${splitCount >= 2 ? `
                        <div class="split-hand-mini ${activeBox === 1 && activeHand === 3 ? 'active-hand' : ''} ${hand3Result ? 'hand-' + hand3Result : ''}" onclick="activeBox = 1; activeHand = 3; render()">
                            <span class="hand-label">1C</span>
                            ${formatSplitHandDisplay(hand3Result, splitBet2, 3, 1)}
                            ${hand3Result ? '<span class="hand-result">' + hand3Result.toUpperCase() + '</span>' : ''}
                        </div>
                        ` : ''}
                        ${splitCount === 3 ? `
                        <div class="split-hand-mini ${activeBox === 1 && activeHand === 4 ? 'active-hand' : ''} ${hand4Result ? 'hand-' + hand4Result : ''}" onclick="activeBox = 1; activeHand = 4; render()">
                            <span class="hand-label">1D</span>
                            ${formatSplitHandDisplay(hand4Result, splitBet3, 4, 1)}
                            ${hand4Result ? '<span class="hand-result">' + hand4Result.toUpperCase() + '</span>' : ''}
                        </div>
                        ` : ''}
                    </div>
                </div>
            `;
        } else {
            const hand1Display = hand1Complete 
                ? `<span class="hand-result ${status}">${status.toUpperCase()}${hand1WinAmount > 0 ? ' +$' + hand1WinAmount : (hand1WinAmount < 0 ? ' -$' + Math.abs(hand1WinAmount) : '')}</span>`
                : `<span class="hand-bet">$${bet}</span>`;
            hand1Section = `
                <div class="two-hand-box ${activeBox === 1 ? 'active-box' : ''} ${hand1Complete ? 'hand-complete hand-' + status : ''}" onclick="!hand1Complete && (activeBox = 1) && render()">
                    <span class="hand-label">Hand 1</span>
                    ${hand1Display}
                </div>
            `;
        }
        
        // Hand 2 display (may or may not be split)
        let hand2Section = '';
        if (hand2IsSplit) {
            hand2Section = `
                <div class="split-in-two-hands ${activeBox === 2 ? 'active-box' : ''}">
                    <div class="split-box-label">Hand 2 (Split${hand2SplitCount >= 2 ? ' x' + (hand2SplitCount + 1) : ''})</div>
                    <div class="split-hands-mini ${hand2SplitCount >= 2 ? (hand2SplitCount === 3 ? 'four-hands' : 'three-hands') : ''}">
                        <div class="split-hand-mini ${activeBox === 2 && hand2ActiveHand === 1 ? 'active-hand' : ''} ${hand2Hand1Result ? 'hand-' + hand2Hand1Result : ''}" onclick="activeBox = 2; hand2ActiveHand = 1; render()">
                            <span class="hand-label">2A</span>
                            ${formatSplitHandDisplay(hand2Hand1Result, hand2Bet, 1, 2)}
                            ${hand2Hand1Result ? '<span class="hand-result">' + hand2Hand1Result.toUpperCase() + '</span>' : ''}
                        </div>
                        <div class="split-hand-mini ${activeBox === 2 && hand2ActiveHand === 2 ? 'active-hand' : ''} ${hand2Hand2Result ? 'hand-' + hand2Hand2Result : ''}" onclick="activeBox = 2; hand2ActiveHand = 2; render()">
                            <span class="hand-label">2B</span>
                            ${formatSplitHandDisplay(hand2Hand2Result, hand2SplitBet, 2, 2)}
                            ${hand2Hand2Result ? '<span class="hand-result">' + hand2Hand2Result.toUpperCase() + '</span>' : ''}
                        </div>
                        ${hand2SplitCount >= 2 ? `
                        <div class="split-hand-mini ${activeBox === 2 && hand2ActiveHand === 3 ? 'active-hand' : ''} ${hand2Hand3Result ? 'hand-' + hand2Hand3Result : ''}" onclick="activeBox = 2; hand2ActiveHand = 3; render()">
                            <span class="hand-label">2C</span>
                            ${formatSplitHandDisplay(hand2Hand3Result, hand2SplitBet2, 3, 2)}
                            ${hand2Hand3Result ? '<span class="hand-result">' + hand2Hand3Result.toUpperCase() + '</span>' : ''}
                        </div>
                        ` : ''}
                        ${hand2SplitCount === 3 ? `
                        <div class="split-hand-mini ${activeBox === 2 && hand2ActiveHand === 4 ? 'active-hand' : ''} ${hand2Hand4Result ? 'hand-' + hand2Hand4Result : ''}" onclick="activeBox = 2; hand2ActiveHand = 4; render()">
                            <span class="hand-label">2D</span>
                            ${formatSplitHandDisplay(hand2Hand4Result, hand2SplitBet3, 4, 2)}
                            ${hand2Hand4Result ? '<span class="hand-result">' + hand2Hand4Result.toUpperCase() + '</span>' : ''}
                        </div>
                        ` : ''}
                    </div>
                </div>
            `;
        } else {
            const hand2Display = hand2Complete 
                ? `<span class="hand-result ${hand2Status}">${hand2Status.toUpperCase()}${hand2WinAmount > 0 ? ' +$' + hand2WinAmount : (hand2WinAmount < 0 ? ' -$' + Math.abs(hand2WinAmount) : '')}</span>`
                : `<span class="hand-bet">$${hand2Bet}</span>`;
            hand2Section = `
                <div class="two-hand-box ${activeBox === 2 ? 'active-box' : ''} ${hand2Complete ? 'hand-complete hand-' + hand2Status : ''}" onclick="!hand2Complete && (activeBox = 2) && render()">
                    <span class="hand-label">Hand 2</span>
                    ${hand2Display}
                </div>
            `;
        }
        
        const activeHandLabel = (activeBox === 1 && isSplit) ? (activeHand === 1 ? 'A' : (activeHand === 2 ? 'B' : (activeHand === 3 ? 'C' : 'D'))) : (activeBox === 2 && hand2IsSplit) ? (hand2ActiveHand === 1 ? 'A' : (hand2ActiveHand === 2 ? 'B' : (hand2ActiveHand === 3 ? 'C' : 'D'))) : '';
        
        betsDisplay = `
            ${showPlayingInfo ? `<div class="playing-hand-info">🎴 Playing Hand ${activeBox}${activeHandLabel} - $${currentBet}</div>` : ''}
            <div class="two-hands-play ${isSplit || hand2IsSplit ? 'has-splits' : ''}">
                ${hand1Section}
                ${hand2Section}
            </div>
            <div class="amount-box bankroll-box">
                <span class="amount-label">Bankroll</span>
                <div class="amount-value">$${bankroll}</div>
            </div>
        `;
    } else if (twoHandsMode && betConfirmed) {
        // Two hands mode during play - show win amounts
        const hand1Display = hand1Complete 
            ? `<span class="hand-result ${status}">${status.toUpperCase()}${hand1WinAmount > 0 ? ' +$' + hand1WinAmount : (hand1WinAmount < 0 ? ' -$' + Math.abs(hand1WinAmount) : '')}</span>`
            : `<span class="hand-bet">$${bet}</span>`;
        const hand2Display = hand2Complete 
            ? `<span class="hand-result ${hand2Status}">${hand2Status.toUpperCase()}${hand2WinAmount > 0 ? ' +$' + hand2WinAmount : (hand2WinAmount < 0 ? ' -$' + Math.abs(hand2WinAmount) : '')}</span>`
            : `<span class="hand-bet">$${hand2Bet}</span>`;
        
        const currentBet = getActiveBet();
        const showPlayingInfo = !hand1Complete || !hand2Complete;
            
        betsDisplay = `
            ${showPlayingInfo ? `<div class="playing-hand-info">🎴 Playing Hand ${activeBox} - $${currentBet}</div>` : ''}
            <div class="two-hands-play">
                <div class="two-hand-box ${activeBox === 1 ? 'active-box' : ''} ${hand1Complete ? 'hand-complete hand-' + status : ''}" onclick="!hand1Complete && (activeBox = 1) && render()">
                    <span class="hand-label">Hand 1</span>
                    ${hand1Display}
                </div>
                <div class="two-hand-box ${activeBox === 2 ? 'active-box' : ''} ${hand2Complete ? 'hand-complete hand-' + hand2Status : ''}" onclick="!hand2Complete && (activeBox = 2) && render()">
                    <span class="hand-label">Hand 2</span>
                    ${hand2Display}
                </div>
            </div>
            <div class="amount-box bankroll-box">
                <span class="amount-label">Bankroll</span>
                <div class="amount-value">$${bankroll}</div>
            </div>
        `;
    } else if (twoHandsMode && !betConfirmed) {
        // Two hands mode betting phase - improved UI
        betsDisplay = `
            <div class="two-hands-betting">
                <div class="two-hand-box ${activeBox === 1 ? 'active-box' : ''}" onclick="switchBox(1)">
                    <span class="hand-label">Hand 1</span>
                    <span class="hand-bet ${bet > 0 ? 'has-bet' : ''}">$${bet}</span>
                    <div class="hand-quick-btns">
                        <button onclick="event.stopPropagation(); quickBetBox(5, 1)">+5</button>
                        <button onclick="event.stopPropagation(); quickBetBox(25, 1)">+25</button>
                        <button onclick="event.stopPropagation(); clearHandBet(1)" ${bet > 0 ? '' : 'disabled'}>✕</button>
                    </div>
                    ${hand2Bet > 0 && bet === 0 ? '<button class="copy-btn" onclick="event.stopPropagation(); copyBet(2)">Copy from H2</button>' : ''}
                </div>
                <div class="two-hand-box ${activeBox === 2 ? 'active-box' : ''}" onclick="switchBox(2)">
                    <span class="hand-label">Hand 2</span>
                    <span class="hand-bet ${hand2Bet > 0 ? 'has-bet' : ''}">$${hand2Bet}</span>
                    <div class="hand-quick-btns">
                        <button onclick="event.stopPropagation(); quickBetBox(5, 2)">+5</button>
                        <button onclick="event.stopPropagation(); quickBetBox(25, 2)">+25</button>
                        <button onclick="event.stopPropagation(); clearHandBet(2)" ${hand2Bet > 0 ? '' : 'disabled'}>✕</button>
                    </div>
                    ${bet > 0 && hand2Bet === 0 ? '<button class="copy-btn" onclick="event.stopPropagation(); copyBet(1)">Copy from H1</button>' : ''}
                </div>
            </div>
            <div class="two-hands-total">
                Total Bet: <strong>$${bet + hand2Bet}</strong>
            </div>
            <div class="amount-box bankroll-box">
                <span class="amount-label">Bankroll</span>
                <div class="amount-value">$${bankroll}</div>
            </div>
        `;
    } else if (isSplit) {
        const currentSplitBet = getCurrentSplitBet();
        const handLabel = activeHand === 1 ? 'A' : (activeHand === 2 ? 'B' : (activeHand === 3 ? 'C' : 'D'));
        
        betsDisplay = `
            <div class="playing-hand-info">🎴 Playing Hand ${handLabel} - $${currentSplitBet || splitOriginalBet}</div>
            <div class="split-hands ${splitCount >= 2 ? (splitCount === 3 ? 'four-hands' : 'three-hands') : ''}">
                <div class="split-hand ${activeHand === 1 ? 'active-hand' : ''} ${hand1Result ? 'hand-' + hand1Result : ''}" onclick="activeHand = 1; render()">
                    <span class="hand-label">A</span>
                    ${formatSplitHandDisplay(hand1Result, bet, 1, 1)}
                    ${hand1Result ? '<span class="hand-result">' + hand1Result.toUpperCase() + '</span>' : ''}
                </div>
                <div class="split-hand ${activeHand === 2 ? 'active-hand' : ''} ${hand2Result ? 'hand-' + hand2Result : ''}" onclick="activeHand = 2; render()">
                    <span class="hand-label">B</span>
                    ${formatSplitHandDisplay(hand2Result, splitBet, 2, 1)}
                    ${hand2Result ? '<span class="hand-result">' + hand2Result.toUpperCase() + '</span>' : ''}
                </div>
                ${splitCount >= 2 ? `
                <div class="split-hand ${activeHand === 3 ? 'active-hand' : ''} ${hand3Result ? 'hand-' + hand3Result : ''}" onclick="activeHand = 3; render()">
                    <span class="hand-label">C</span>
                    ${formatSplitHandDisplay(hand3Result, splitBet2, 3, 1)}
                    ${hand3Result ? '<span class="hand-result">' + hand3Result.toUpperCase() + '</span>' : ''}
                </div>
                ` : ''}
                ${splitCount === 3 ? `
                <div class="split-hand ${activeHand === 4 ? 'active-hand' : ''} ${hand4Result ? 'hand-' + hand4Result : ''}" onclick="activeHand = 4; render()">
                    <span class="hand-label">D</span>
                    ${formatSplitHandDisplay(hand4Result, splitBet3, 4, 1)}
                    ${hand4Result ? '<span class="hand-result">' + hand4Result.toUpperCase() + '</span>' : ''}
                </div>
                ` : ''}
            </div>
            <div class="amount-box bankroll-box">
                <span class="amount-label">Bankroll</span>
                <div class="amount-value">$${bankroll}</div>
            </div>
        `;
    } else if (isDoubleDown) {
        betsDisplay = `
            <div class="double-down-display">
                <div class="dd-label">DOUBLE DOWN</div>
                <div class="dd-bet">$${bet}</div>
                <div class="dd-note">Awaiting result...</div>
            </div>
            <div class="amount-box bankroll-box">
                <span class="amount-label">Bankroll</span>
                <div class="amount-value">$${bankroll}</div>
            </div>
        `;
    } else if (isDealing) {
        betsDisplay = `
            <div class="dealing-display">
                <div class="dealing-cards">
                    <div class="card card-1"></div>
                    <div class="card card-2"></div>
                    <div class="card card-3"></div>
                    <div class="card card-4"></div>
                </div>
                <div class="dealing-text">Dealing...</div>
                <div class="dealing-bet">Bet: $${bet}${twoHandsMode && hand2Bet > 0 ? ' + $' + hand2Bet : ''}</div>
            </div>
            <div class="amount-box bankroll-box">
                <span class="amount-label">Bankroll</span>
                <div class="amount-value">$${bankroll}</div>
            </div>
        `;
    } else if (betConfirmed) {
        betsDisplay = `
            <div class="confirmed-bet-display">
                <div class="confirmed-label">BET LOCKED IN</div>
                <div class="confirmed-bet">$${bet}${twoHandsMode && hand2Bet > 0 ? ' + $' + hand2Bet : ''}</div>
                <div class="confirmed-note">Awaiting result...</div>
            </div>
            <div class="amount-box bankroll-box">
                <span class="amount-label">Bankroll</span>
                <div class="amount-value">$${bankroll}</div>
            </div>
        `;
    } else {
        betsDisplay = `
            <div class="amounts-display">
                <div class="amount-box">
                    <span class="amount-label">Bankroll</span>
                    <div class="amount-value ${bankroll === 0 && bet === 0 && gameStarted ? 'busted' : ''}">$${bankroll}</div>
                </div>
                <div class="amount-box">
                    <span class="amount-label">Bet</span>
                    <div class="amount-value bet">$${bet}</div>
                </div>
            </div>
            ${bankroll === 0 && bet === 0 && gameStarted ? '<div class="busted-message">💸 BUSTED! Add more chips to continue.</div>' : ''}
        `;
    }
    
    const controlsDisabled = isSplit || isDoubleDown || betConfirmed || isDealing;
    
    container.innerHTML = `
        <div class="panel-title player-title">PLAYER</div>
        
        ${betsDisplay}
        
        ${!gameStarted || (bankroll === 0 && bet === 0 && hand2Bet === 0) ? `<div class="set-bankroll">
            <div class="preset-buyins">
                <button onclick="presetBuyin(100)">$100</button>
                <button onclick="presetBuyin(500)">$500</button>
                <button onclick="presetBuyin(1000)">$1000</button>
            </div>
            <div class="custom-buyin">
                <input type="number" id="addChipsInput" placeholder="Custom...">
                <button onclick="addChips()">Add</button>
            </div>
        </div>` : ''}
        
        ${!betConfirmed && !isDealing && !isSplit && !isDoubleDown && gameStarted ? `
        <div class="two-hands-toggle">
            <label class="toggle-label">
                <input type="checkbox" ${twoHandsMode ? 'checked' : ''} onchange="toggleTwoHands()">
                <span class="toggle-text">Play 2 Hands</span>
            </label>
        </div>
        ` : ''}
        
        ${!betConfirmed && !isDealing && !isSplit && !isDoubleDown ? `
        <div class="confirm-bet-section">
            <button class="confirm-bet-btn" onclick="confirmBet()" ${(twoHandsMode ? (bet > 0 || hand2Bet > 0) : bet > 0) ? '' : 'disabled'}>
                DEAL CARDS${twoHandsMode ? (bet > 0 || hand2Bet > 0 ? ' - $' + (bet + hand2Bet) : '') : (bet > 0 ? ' - $' + bet : '')}
            </button>
        </div>
        ` : ''}
        
        <div class="quick-bets">
            <button onclick="quickBet(5)" ${controlsDisabled ? 'disabled' : ''}>+$5</button>
            <button onclick="quickBet(10)" ${controlsDisabled ? 'disabled' : ''}>+$10</button>
            <button onclick="quickBet(25)" ${controlsDisabled ? 'disabled' : ''}>+$25</button>
            <button onclick="quickBet(50)" ${controlsDisabled ? 'disabled' : ''}>+$50</button>
            <button onclick="quickBet(100)" ${controlsDisabled ? 'disabled' : ''}>+$100</button>
        </div>
        
        <div class="bet-actions">
            <button class="bet-action-btn btn-undo" onclick="undoBet()" ${betHistory.length > 0 && !controlsDisabled ? '' : 'disabled'}>
                Undo
            </button>
            <button class="bet-action-btn btn-rebet" onclick="rebet()" ${lastBet > 0 && bet === 0 && lastBet <= bankroll && !controlsDisabled ? '' : 'disabled'}>
                Rebet${lastBet > 0 ? ' $' + lastBet : ''}
            </button>
            <button class="bet-action-btn btn-double" onclick="doubleBet()" ${(() => {
                const currentBet = twoHandsMode ? (activeBox === 1 ? bet : hand2Bet) : bet;
                return currentBet > 0 && currentBet <= bankroll && !controlsDisabled;
            })() ? '' : 'disabled'}>
                2x Bet
            </button>
            <button class="bet-action-btn btn-allin" onclick="allIn()" ${bankroll > 0 && !controlsDisabled ? '' : 'disabled'}>
                All In
            </button>
            <button class="bet-action-btn btn-doubledown" onclick="doubleDown()" ${(() => {
                if (twoHandsMode) {
                    const currentSplit = getActiveSplit();
                    if (currentSplit) {
                        // Allow DD on split hands only if not already doubled
                        if (activeBox === 1) {
                            const splitHandBet = getCurrentSplitBet();
                            return splitHandBet > 0 && splitHandBet <= bankroll && betConfirmed && !getSplitDD(activeHand);
                        } else {
                            const splitHandBet = getHand2CurrentSplitBet();
                            return splitHandBet > 0 && splitHandBet <= bankroll && betConfirmed && !getHand2SplitDD(hand2ActiveHand);
                        }
                    }
                    const currentBet = getActiveBet();
                    return currentBet > 0 && currentBet <= bankroll && betConfirmed && !getActiveDD();
                }
                return bet > 0 && bet <= bankroll && betConfirmed && !isSplit && !isDoubleDown;
            })() ? '' : 'disabled'}>
                Double Down
            </button>
            <button class="bet-action-btn btn-split" onclick="splitHand()" ${(() => {
                if (twoHandsMode) {
                    if (activeBox === 1 && isSplit) {
                        // Can split again if splitCount < 3 (up to 4 hands)
                        const currentHandBet = getCurrentSplitBet();
                        return splitCount < 3 && currentHandBet > 0 && currentHandBet <= bankroll && betConfirmed;
                    } else if (activeBox === 2 && hand2IsSplit) {
                        const currentHandBet = getHand2CurrentSplitBet();
                        return hand2SplitCount < 3 && currentHandBet > 0 && currentHandBet <= bankroll && betConfirmed;
                    }
                    const currentBet = getActiveBet();
                    return currentBet > 0 && currentBet <= bankroll && betConfirmed && !getActiveSplit();
                }
                // Single hand mode - allow split if not split or splitCount < 3
                if (isSplit) {
                    const currentHandBet = getCurrentSplitBet();
                    return splitCount < 3 && currentHandBet > 0 && currentHandBet <= bankroll && betConfirmed;
                }
                return bet > 0 && bet <= bankroll && betConfirmed && !isDoubleDown;
            })() ? '' : 'disabled'}>
                Split
            </button>
            <button class="bet-action-btn btn-insurance" onclick="takeInsurance()" ${(() => {
                let totalBet = bet;
                if (twoHandsMode && hand2Bet > 0) totalBet += hand2Bet;
                const insAmount = Math.floor(totalBet / 2);
                return totalBet > 0 && betConfirmed && !hasInsurance && !isSplit && !hand2IsSplit && !isDoubleDown && !hand2IsDoubleDown && insAmount <= bankroll;
            })() ? '' : 'disabled'}>
                Insurance${(() => {
                    let totalBet = bet;
                    if (twoHandsMode && hand2Bet > 0) totalBet += hand2Bet;
                    return totalBet > 0 ? ' $' + Math.floor(totalBet / 2) : '';
                })()}
            </button>
            <button class="bet-action-btn btn-surrender" onclick="surrender()" ${(() => {
                if (twoHandsMode) {
                    const currentBet = getActiveBet();
                    const currentSurrender = activeBox === 1 ? hasSurrendered : hand2HasSurrendered;
                    return currentBet > 0 && betConfirmed && !getActiveSplit() && !getActiveDD() && !currentSurrender;
                }
                return bet > 0 && betConfirmed && !isSplit && !isDoubleDown && !hasSurrendered;
            })() ? '' : 'disabled'}>
                Surrender
            </button>
            <button class="bet-action-btn btn-clear" onclick="${twoHandsMode ? 'clearAllBets' : 'clearBet'}()" ${!controlsDisabled ? '' : 'disabled'}>
                Clear${twoHandsMode ? ' All' : ''}
            </button>
        </div>
        
        <div class="auto-rebet-toggle">
            <label class="toggle-label">
                <input type="checkbox" ${autoRebet ? 'checked' : ''} onchange="toggleAutoRebet()">
                <span class="toggle-text">Auto Rebet${lastBet > 0 ? ' $' + lastBet : ''}</span>
            </label>
        </div>
    `;
}

// Render Dealer Side (right)
function renderDealerSide() {
    const container = document.getElementById('dealerSide');
    
    let splitInfo = '';
    if (isDoubleDown) {
        splitInfo = `
            <div class="split-info dd-info">
                <div class="active-hand-display">DOUBLE DOWN</div>
                <div class="split-bet-total">$${bet} at risk</div>
            </div>
        `;
    }
    
    let roundDisplay = '';
    if (roundInProgress) {
        roundDisplay = `
            <div class="round-indicator active">
                <span class="round-dot"></span>
                Round ${roundNumber} in Progress
            </div>
        `;
    } else if (roundNumber > 0) {
        roundDisplay = `
            <div class="round-indicator">
                Rounds Played: ${roundNumber}
            </div>
        `;
    }
    
    // Disable result buttons if no bet confirmed, or if in split mode with no active bet
    let resultDisabled = !betConfirmed && !isSplit && !isDoubleDown;
    if (isSplit) {
        // In split mode, check if current hand has a bet
        if (getCurrentSplitBet() === 0) resultDisabled = true;
    }
    if (twoHandsMode && hand2IsSplit && activeBox === 2) {
        if (getHand2CurrentSplitBet() === 0) resultDisabled = true;
    }
    
    const winRate = stats.handsPlayed > 0 ? Math.round((stats.wins / stats.handsPlayed) * 100) : 0;
    const netProfit = stats.totalWon - stats.totalLost;
    
    container.innerHTML = `
        <div class="panel-title dealer-title">DEALER</div>
        
        ${roundDisplay}
        
        ${splitInfo}
        
        ${isDealing ? '<div class="dealer-dealing">🎴 Dealing cards...</div>' : ''}
        
        ${hasInsurance ? `
        <div class="insurance-active">
            <div class="insurance-label">🛡️ INSURANCE ACTIVE</div>
            <div class="insurance-amount">$${insuranceBet} (pays 2:1)</div>
            <div class="insurance-buttons">
                <button class="insurance-result-btn btn-ins-win" onclick="insuranceWins()">Dealer BJ (Win)</button>
                <button class="insurance-result-btn btn-ins-lose" onclick="insuranceLoses()">No BJ (Lose)</button>
            </div>
        </div>
        ` : ''}
        
        <div class="result-buttons">
            <button class="result-btn btn-win" onclick="win()" ${resultDisabled || hasInsurance ? 'disabled' : ''}>WIN</button>
            <button class="result-btn btn-blackjack" onclick="blackjack()" ${resultDisabled || hasInsurance ? 'disabled' : ''}>BLACKJACK</button>
            <button class="result-btn btn-push" onclick="push()" ${resultDisabled || hasInsurance ? 'disabled' : ''}>PUSH</button>
            <button class="result-btn btn-lose" onclick="lose()" ${resultDisabled || hasInsurance ? 'disabled' : ''}>LOSE</button>
        </div>
        
        ${stats.handsPlayed > 0 ? `
        <div class="stats-panel">
            <div class="stats-title">Session Stats</div>
            <div class="stats-grid">
                <div class="stat-item">
                    <span class="stat-label">Hands</span>
                    <span class="stat-value">${stats.handsPlayed}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Win Rate</span>
                    <span class="stat-value ${winRate >= 50 ? 'stat-positive' : 'stat-negative'}">${winRate}%</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">W/L/P</span>
                    <span class="stat-value">${stats.wins}/${stats.losses}/${stats.pushes}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Net</span>
                    <span class="stat-value ${netProfit >= 0 ? 'stat-positive' : 'stat-negative'}">${netProfit >= 0 ? '+' : ''}$${netProfit}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Biggest Win</span>
                    <span class="stat-value stat-positive">$${stats.biggestWin}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">BJs</span>
                    <span class="stat-value">${stats.blackjacks}</span>
                </div>
            </div>
            <div class="stats-actions">
                <button class="save-highscore-btn" onclick="saveHighscore()">💾 Save Highscore</button>
                <button class="view-leaderboard-btn" onclick="showLeaderboard()">🏆 Leaderboard</button>
                <button class="reset-stats-btn" onclick="resetStats()">Reset Stats</button>
            </div>
        </div>
        ` : `
        <div class="leaderboard-only">
            <button class="view-leaderboard-btn" onclick="showLeaderboard()">🏆 View Leaderboard</button>
        </div>
        `}
        
        <button class="new-game-btn" onclick="newGame()">New Game</button>
    `;
}

// Render Outcome Banner (disabled - using top status bar instead)
function renderOutcomeBanner() {
    const container = document.getElementById('outcomeBanner');
    container.innerHTML = '';
}

// Start the app
document.addEventListener('DOMContentLoaded', init);

// Toggle fullscreen
function toggleFullscreen() {
    playSound('push');
    if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen().catch(err => {
            // Silent fail for fullscreen
        });
    } else {
        document.exitFullscreen();
    }
}


