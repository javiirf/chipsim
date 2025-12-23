// Firebase Configuration for Chip Simulator
const firebaseConfig = {
    apiKey: "AIzaSyCbTKMXKkiL3J9br6ch44iH6dmJnloR6TY",
    authDomain: "chip-simulator.firebaseapp.com",
    databaseURL: "https://chip-simulator-default-rtdb.firebaseio.com",
    projectId: "chip-simulator",
    storageBucket: "chip-simulator.firebasestorage.app",
    messagingSenderId: "490020206168",
    appId: "1:490020206168:web:ab05095e1abff8c4eebc2d"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Get a reference to the database
const database = firebase.database();

// ==================== FIREBASE SYNC UTILITIES ====================

// Generate a unique session ID for multiplayer rooms
function generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

// Current room reference
let currentRoomRef = null;
let currentRoomCode = null;
let isHost = false;

// ==================== POKER REALTIME SYNC ====================

// Create a new poker room
function createPokerRoom() {
    const roomCode = generateRoomCode();
    currentRoomCode = roomCode;
    isHost = true;
    
    currentRoomRef = database.ref('pokerRooms/' + roomCode);
    
    // Initialize room data
    currentRoomRef.set({
        created: Date.now(),
        host: 'host',
        gameState: null,
        players: {},
        status: 'waiting'
    });
    
    // Listen for changes
    setupRoomListeners();
    
    return roomCode;
}

// Join an existing poker room
function joinPokerRoom(roomCode) {
    return new Promise((resolve, reject) => {
        const roomRef = database.ref('pokerRooms/' + roomCode);
        
        roomRef.once('value', (snapshot) => {
            if (snapshot.exists()) {
                currentRoomRef = roomRef;
                currentRoomCode = roomCode;
                isHost = false;
                
                setupRoomListeners();
                resolve(true);
            } else {
                reject('Room not found');
            }
        });
    });
}

// Setup listeners for room changes
function setupRoomListeners() {
    if (!currentRoomRef) return;
    
    // Listen for game state changes
    currentRoomRef.child('gameState').on('value', (snapshot) => {
        const state = snapshot.val();
        if (state && !isHost) {
            // Apply state from host
            applyPokerState(state);
        }
    });
}

// Sync poker state to Firebase
function syncPokerStateToFirebase() {
    if (!currentRoomRef || !isHost) return;
    
    const state = {
        players: pokerPlayers,
        pot: pokerPot,
        phase: pokerPhase,
        round: pokerRound,
        street: pokerStreet,
        activePlayerIndex: pokerActivePlayerIndex,
        dealerIndex: pokerDealerIndex,
        currentBet: pokerCurrentBet,
        lastResult: pokerLastResult,
        burnCardPending: pokerBurnCardPending,
        burnCardStreet: pokerBurnCardStreet,
        timestamp: Date.now()
    };
    
    currentRoomRef.child('gameState').set(state);
}

// Apply poker state from Firebase
function applyPokerState(state) {
    if (!state) return;
    
    pokerPlayers = state.players || [];
    pokerPot = state.pot || 0;
    pokerPhase = state.phase || 'setup';
    pokerRound = state.round || 0;
    pokerStreet = state.street || 'preflop';
    pokerActivePlayerIndex = state.activePlayerIndex || 0;
    pokerDealerIndex = state.dealerIndex || 0;
    pokerCurrentBet = state.currentBet || 0;
    pokerLastResult = state.lastResult || null;
    pokerBurnCardPending = state.burnCardPending || false;
    pokerBurnCardStreet = state.burnCardStreet || '';
    
    renderPoker();
}

// Leave current room
function leavePokerRoom() {
    if (currentRoomRef) {
        currentRoomRef.off();
        if (isHost) {
            currentRoomRef.remove();
        }
        currentRoomRef = null;
        currentRoomCode = null;
        isHost = false;
    }
}

// ==================== BLACKJACK LEADERBOARD SYNC ====================

// Save blackjack highscore to Firebase
function saveHighscoreToFirebase(name, score) {
    const leaderboardRef = database.ref('blackjackLeaderboard');
    leaderboardRef.push({
        name: name,
        score: score,
        timestamp: Date.now()
    });
}

// Get top blackjack scores
function getTopScores(limit = 10) {
    return new Promise((resolve) => {
        const leaderboardRef = database.ref('blackjackLeaderboard');
        leaderboardRef.orderByChild('score').limitToLast(limit).once('value', (snapshot) => {
            const scores = [];
            snapshot.forEach((child) => {
                scores.push({
                    id: child.key,
                    ...child.val()
                });
            });
            // Sort descending
            scores.sort((a, b) => b.score - a.score);
            resolve(scores);
        });
    });
}

// ==================== POKER SERIES LEADERBOARD ====================

// Save poker series stats to Firebase
function syncPokerSeriesToFirebase() {
    const seriesRef = database.ref('pokerSeries');
    seriesRef.set(pokerSeriesStats);
}

// Load poker series stats from Firebase
function loadPokerSeriesFromFirebase() {
    return new Promise((resolve) => {
        const seriesRef = database.ref('pokerSeries');
        seriesRef.once('value', (snapshot) => {
            const data = snapshot.val();
            if (data) {
                pokerSeriesStats = data;
            }
            resolve(data);
        });
    });
}

// Listen for series updates in realtime
function listenForSeriesUpdates() {
    const seriesRef = database.ref('pokerSeries');
    seriesRef.on('value', (snapshot) => {
        const data = snapshot.val();
        if (data) {
            pokerSeriesStats = data;
            if (typeof renderPoker === 'function') {
                renderPoker();
            }
        }
    });
}

// ==================== CONNECTION STATUS ====================

// Monitor connection status
const connectedRef = database.ref('.info/connected');
let isOnline = false;

connectedRef.on('value', (snap) => {
    isOnline = snap.val() === true;
    
    // Update UI indicator if exists
    const indicator = document.getElementById('connectionIndicator');
    if (indicator) {
        indicator.className = isOnline ? 'online' : 'offline';
        indicator.title = isOnline ? 'Connected to server' : 'Offline mode';
    }
});

// Check if online
function isConnectedToFirebase() {
    return isOnline;
}
