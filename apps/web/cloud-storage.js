// ==================== CLOUD STORAGE SERVICE ====================
// Handles all data persistence via Firebase with anonymous authentication

// User state
let currentUser = null;
let userDataRef = null;
let isCloudReady = false;
let pendingSaves = [];
let saveDebounceTimer = null;

// Initialize cloud storage with anonymous auth
async function initCloudStorage() {
    return new Promise((resolve, reject) => {
        // Check if Firebase is available
        if (typeof firebase === 'undefined') {
            console.error('Firebase not loaded');
            reject('Firebase not loaded');
            return;
        }

        // Set a timeout in case Firebase auth is slow
        const authTimeout = setTimeout(() => {
            console.warn('Firebase auth timeout - proceeding without cloud storage');
            resolve(null);
        }, 3000);

        // Listen for auth state changes
        firebase.auth().onAuthStateChanged(async (user) => {
            clearTimeout(authTimeout);
            if (user) {
                // User is signed in
                currentUser = user;
                userDataRef = database.ref('users/' + user.uid);
                isCloudReady = true;
                
                // Process any pending saves
                processPendingSaves();
                
                resolve(user);
            } else {
                // No user signed in, sign in anonymously
                try {
                    await firebase.auth().signInAnonymously();
                    // The onAuthStateChanged callback will handle the rest
                } catch (error) {
                    console.error('Anonymous auth failed:', error);
                    resolve(null); // Don't reject, just continue without cloud
                }
            }
        });
    });
}

// Process any saves that were queued before auth was ready
function processPendingSaves() {
    if (pendingSaves.length > 0) {
        pendingSaves.forEach(({ key, data }) => {
            saveToCloud(key, data);
        });
        pendingSaves = [];
    }
}

// Save data to cloud (debounced to prevent excessive writes)
function saveToCloud(key, data) {
    if (!isCloudReady || !userDataRef) {
        // Queue the save for later
        pendingSaves.push({ key, data });
        return Promise.resolve();
    }

    return userDataRef.child(key).set({
        ...data,
        lastUpdated: firebase.database.ServerValue.TIMESTAMP
    }).catch((error) => {
        // Silent fail for production
    });
}

// Load data from cloud
function loadFromCloud(key) {
    if (!isCloudReady || !userDataRef) {
        return Promise.resolve(null);
    }

    return userDataRef.child(key).once('value').then((snapshot) => {
        return snapshot.val();
    }).catch((error) => {
        return null;
    });
}

// Delete data from cloud
function deleteFromCloud(key) {
    if (!isCloudReady || !userDataRef) {
        return Promise.resolve();
    }

    return userDataRef.child(key).remove().catch((error) => {
        // Silent fail for production
    });
}

// Listen for real-time updates on a key
function listenToCloud(key, callback) {
    if (!isCloudReady || !userDataRef) {
        return () => {}; // Return empty unsubscribe function
    }

    const ref = userDataRef.child(key);
    ref.on('value', (snapshot) => {
        const data = snapshot.val();
        callback(data);
    });

    // Return unsubscribe function
    return () => ref.off('value');
}

// Get current user ID
function getUserId() {
    return currentUser ? currentUser.uid : null;
}

// Check if cloud is ready
function isCloudStorageReady() {
    return isCloudReady;
}

// ==================== BLACKJACK DATA MANAGEMENT ====================

const BLACKJACK_KEY = 'blackjack';

// Save blackjack state to cloud
function saveBlackjackToCloud() {
    const data = {
        bankroll: typeof bankroll !== 'undefined' ? bankroll : 0,
        bet: typeof bet !== 'undefined' ? bet : 0,
        lastBet: typeof lastBet !== 'undefined' ? lastBet : 0,
        autoRebet: typeof autoRebet !== 'undefined' ? autoRebet : false,
        gameStarted: typeof gameStarted !== 'undefined' ? gameStarted : false,
        roundNumber: typeof roundNumber !== 'undefined' ? roundNumber : 0,
        stats: typeof stats !== 'undefined' ? stats : { 
            wins: 0, losses: 0, pushes: 0, blackjacks: 0, 
            totalWon: 0, totalLost: 0, biggestWin: 0, handsPlayed: 0 
        },
        twoHandsMode: typeof twoHandsMode !== 'undefined' ? twoHandsMode : false,
        hand2Bet: typeof hand2Bet !== 'undefined' ? hand2Bet : 0,
        leaderboard: typeof leaderboard !== 'undefined' ? leaderboard : []
    };
    
    // Debounce saves
    if (saveDebounceTimer) {
        clearTimeout(saveDebounceTimer);
    }
    saveDebounceTimer = setTimeout(() => {
        saveToCloud(BLACKJACK_KEY, data);
    }, 500);
}

// Load blackjack state from cloud
async function loadBlackjackFromCloud() {
    const data = await loadFromCloud(BLACKJACK_KEY);
    if (data) {
        if (typeof bankroll !== 'undefined') bankroll = data.bankroll || 0;
        if (typeof bet !== 'undefined') bet = data.bet || 0;
        if (typeof lastBet !== 'undefined') lastBet = data.lastBet || 0;
        if (typeof autoRebet !== 'undefined') autoRebet = data.autoRebet || false;
        if (typeof gameStarted !== 'undefined') gameStarted = data.gameStarted || false;
        if (typeof roundNumber !== 'undefined') roundNumber = data.roundNumber || 0;
        if (typeof stats !== 'undefined') {
            stats = data.stats || { 
                wins: 0, losses: 0, pushes: 0, blackjacks: 0, 
                totalWon: 0, totalLost: 0, biggestWin: 0, handsPlayed: 0 
            };
        }
        if (typeof twoHandsMode !== 'undefined') twoHandsMode = data.twoHandsMode || false;
        if (typeof hand2Bet !== 'undefined') hand2Bet = data.hand2Bet || 0;
        if (typeof leaderboard !== 'undefined') leaderboard = data.leaderboard || [];
        return true;
    }
    return false;
}

// ==================== POKER DATA MANAGEMENT ====================

const POKER_KEY = 'poker';

// Save poker state to cloud
function savePokerToCloud() {
    const data = {
        pokerPlayers: typeof pokerPlayers !== 'undefined' ? pokerPlayers : [],
        pokerPot: typeof pokerPot !== 'undefined' ? pokerPot : 0,
        pokerPhase: typeof pokerPhase !== 'undefined' ? pokerPhase : 'setup',
        pokerGameStarted: typeof pokerGameStarted !== 'undefined' ? pokerGameStarted : false,
        pokerRound: typeof pokerRound !== 'undefined' ? pokerRound : 0,
        pokerSmallBlind: typeof pokerSmallBlind !== 'undefined' ? pokerSmallBlind : 5,
        pokerBigBlind: typeof pokerBigBlind !== 'undefined' ? pokerBigBlind : 10,
        pokerDealerIndex: typeof pokerDealerIndex !== 'undefined' ? pokerDealerIndex : 0,
        pokerStreet: typeof pokerStreet !== 'undefined' ? pokerStreet : 'preflop',
        pokerActivePlayerIndex: typeof pokerActivePlayerIndex !== 'undefined' ? pokerActivePlayerIndex : 0,
        pokerLastAggressor: typeof pokerLastAggressor !== 'undefined' ? pokerLastAggressor : -1,
        pokerMinRaise: typeof pokerMinRaise !== 'undefined' ? pokerMinRaise : 10,
        pokerCurrentBet: typeof pokerCurrentBet !== 'undefined' ? pokerCurrentBet : 0,
        pokerBlindsPosted: typeof pokerBlindsPosted !== 'undefined' ? pokerBlindsPosted : false,
        pokerLastResult: typeof pokerLastResult !== 'undefined' ? pokerLastResult : null,
        pokerBurnCardPending: typeof pokerBurnCardPending !== 'undefined' ? pokerBurnCardPending : false,
        pokerBurnCardStreet: typeof pokerBurnCardStreet !== 'undefined' ? pokerBurnCardStreet : '',
        pokerSeriesStats: typeof pokerSeriesStats !== 'undefined' ? pokerSeriesStats : {},
        currentGameMode: typeof currentGameMode !== 'undefined' ? currentGameMode : 'blackjack'
    };
    
    // Debounce saves
    if (saveDebounceTimer) {
        clearTimeout(saveDebounceTimer);
    }
    saveDebounceTimer = setTimeout(() => {
        saveToCloud(POKER_KEY, data);
    }, 500);
}

// Load poker state from cloud
async function loadPokerFromCloud() {
    const data = await loadFromCloud(POKER_KEY);
    if (data) {
        if (typeof pokerPlayers !== 'undefined') {
            pokerPlayers = data.pokerPlayers || [];
            // Ensure all players have stats object and totalBuyIn
            pokerPlayers = pokerPlayers.map(p => {
                const oldStats = p.stats || {};
                return {
                    ...p,
                    stats: {
                        handsWon: oldStats.handsWon || oldStats.wins || 0,
                        handsLost: oldStats.handsLost || oldStats.losses || 0,
                        handsTied: oldStats.handsTied || oldStats.ties || 0
                    },
                    totalBuyIn: p.totalBuyIn || p.bankroll + (p.bet || 0)
                };
            });
        }
        if (typeof pokerPot !== 'undefined') pokerPot = data.pokerPot || 0;
        if (typeof pokerPhase !== 'undefined') pokerPhase = data.pokerPhase || 'setup';
        if (typeof pokerGameStarted !== 'undefined') pokerGameStarted = data.pokerGameStarted || false;
        if (typeof pokerRound !== 'undefined') pokerRound = data.pokerRound || 0;
        if (typeof pokerSmallBlind !== 'undefined') pokerSmallBlind = data.pokerSmallBlind || 5;
        if (typeof pokerBigBlind !== 'undefined') pokerBigBlind = data.pokerBigBlind || 10;
        if (typeof pokerDealerIndex !== 'undefined') pokerDealerIndex = data.pokerDealerIndex || 0;
        if (typeof pokerStreet !== 'undefined') pokerStreet = data.pokerStreet || 'preflop';
        if (typeof pokerActivePlayerIndex !== 'undefined') pokerActivePlayerIndex = data.pokerActivePlayerIndex || 0;
        if (typeof pokerLastAggressor !== 'undefined') pokerLastAggressor = data.pokerLastAggressor ?? -1;
        if (typeof pokerMinRaise !== 'undefined') pokerMinRaise = data.pokerMinRaise || 10;
        if (typeof pokerCurrentBet !== 'undefined') pokerCurrentBet = data.pokerCurrentBet || 0;
        if (typeof pokerBlindsPosted !== 'undefined') pokerBlindsPosted = data.pokerBlindsPosted || false;
        if (typeof pokerLastResult !== 'undefined') pokerLastResult = data.pokerLastResult || null;
        if (typeof pokerBurnCardPending !== 'undefined') pokerBurnCardPending = data.pokerBurnCardPending || false;
        if (typeof pokerBurnCardStreet !== 'undefined') pokerBurnCardStreet = data.pokerBurnCardStreet || '';
        if (typeof pokerSeriesStats !== 'undefined') pokerSeriesStats = data.pokerSeriesStats || {};
        if (typeof currentGameMode !== 'undefined') currentGameMode = data.currentGameMode || 'blackjack';
        
        if (!Array.isArray(pokerPlayers) || (pokerGameStarted && pokerPlayers.length === 0)) {
            pokerPlayers = [];
            pokerGameStarted = false;
            pokerPhase = 'setup';
        }
        return true;
    }
    return false;
}

// ==================== GLOBAL LEADERBOARD ====================

const GLOBAL_LEADERBOARD_KEY = 'globalLeaderboard';

// Save score to global leaderboard
async function saveToGlobalLeaderboard(entry) {
    const leaderboardRef = database.ref('leaderboard');
    return leaderboardRef.push({
        ...entry,
        oderId: getUserId(),
        timestamp: firebase.database.ServerValue.TIMESTAMP
    });
}

// Get global leaderboard
async function getGlobalLeaderboard(limit = 50) {
    const leaderboardRef = database.ref('leaderboard');
    const snapshot = await leaderboardRef.orderByChild('bankroll').limitToLast(limit).once('value');
    const scores = [];
    snapshot.forEach((child) => {
        scores.push({
            id: child.key,
            ...child.val()
        });
    });
    // Sort descending
    scores.sort((a, b) => b.bankroll - a.bankroll);
    return scores;
}

// ==================== INITIALIZATION ====================

// Auto-initialize when script loads
document.addEventListener('DOMContentLoaded', async () => {
    try {
        await initCloudStorage();
        // Trigger a custom event that other scripts can listen for
        window.dispatchEvent(new CustomEvent('cloudStorageReady'));
    } catch (error) {
        // Silent fail for production - app will work offline
        window.dispatchEvent(new CustomEvent('cloudStorageReady'));
    }
});
