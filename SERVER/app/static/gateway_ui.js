// Minimal GatewayWeb Admin Dashboard JS
const socket = io();
let gatewayMessages = {};
let outputMessages = {};
let cachedData = [];
let isConnected = true;

function formatMessage(data, type) {
  const messageEl = document.createElement("div");
  messageEl.className = `message ${type}`;
  const pre = document.createElement("pre");
  pre.textContent = JSON.stringify(data, null, 2);
  const timestamp = document.createElement("div");
  timestamp.className = "timestamp";
  timestamp.textContent = data.timeline ? `Timeline: ${data.timeline}` : new Date().toLocaleTimeString();
  messageEl.appendChild(pre);
  messageEl.appendChild(timestamp);
  return messageEl;
}

// Listen for Gateway Input
socket.on("gateway_input", function (data) {
  // On new input: update Gateway Input, clear Gateway Output
  gatewayMessages = {};
  Object.entries(data).forEach(([key, value]) => {
    gatewayMessages[key] = value;
  });
  
  // Clear Gateway Output when new input arrives
  outputMessages = {};
  renderGatewayInput();
  renderGatewayOutput();
});

// Listen for Gateway Output (Firebase Output)
socket.on("firebase_output", function (data) {
  // On successful send: move Gateway Input to Gateway Output (for comparison)
  if (data.cached && Array.isArray(data.cached)) {
    // If there's cached data, include it in output
    cachedData = data.cached;
  }
  
  // Set output messages to current gateway messages for comparison
  outputMessages = { ...gatewayMessages };
  renderGatewayOutput();
  // Keep gatewayMessages so user can compare
  renderGatewayInput();
});

// Listen for cache size updates
socket.on("cache_size_update", function (data) {
  document.getElementById("cache-size").textContent = data.cache_size || 0;
});

// Listen for uptime
socket.on("admin_metrics", function (data) {
  document.getElementById("uptime").textContent = data.uptime || "00:00:00";
  if (data.cache_size !== undefined) {
    document.getElementById("cache-size").textContent = data.cache_size;
  }
});

// Connection status button logic
const connectionBtn = document.getElementById("connection-status-btn");
socket.on("connection_status", function(data) {
  const wasConnected = isConnected;
  isConnected = data.connected;
  
  if (data.connected) {
    connectionBtn.textContent = "Connection: On";
    connectionBtn.classList.add("on");
    connectionBtn.classList.remove("off");
  } else {
    connectionBtn.textContent = "Connection: Off";
    connectionBtn.classList.add("off");
    connectionBtn.classList.remove("on");
    
    // When connection is lost, show cached data + gateway input in output
    if (wasConnected && !isConnected) {
      handleConnectionLost();
    }
  }
});

// Handle connection lost - show cached data and gateway input in output
function handleConnectionLost() {
  // Combine cached data and current gateway input
  const combinedOutput = {};
  
  // Add cached data first
  if (cachedData && cachedData.length > 0) {
    cachedData.forEach((cached, index) => {
      Object.entries(cached).forEach(([key, value]) => {
        combinedOutput[`cached_${index}_${key}`] = value;
      });
    });
  }
  
  // Add current gateway input
  Object.entries(gatewayMessages).forEach(([key, value]) => {
    combinedOutput[`current_${key}`] = value;
  });
  
  outputMessages = combinedOutput;
  renderGatewayOutput();
}

// Request initial connection status
socket.emit("get_connection_status");
// Periodically request connection status every 5 seconds
setInterval(() => {
  socket.emit("get_connection_status");
}, 5000);

function renderGatewayInput() {
  const container = document.getElementById("gateway-data");
  container.innerHTML = "";
  Object.entries(gatewayMessages).forEach(([key, value]) => {
    const messageEl = formatMessage(value, "gateway");
    messageEl.setAttribute("data-key", key);
    container.appendChild(messageEl);
  });
}

function renderGatewayOutput() {
  const container = document.getElementById("firebase-data");
  container.innerHTML = "";
  Object.entries(outputMessages).forEach(([key, value]) => {
    const messageEl = formatMessage(value, "firebase");
    messageEl.setAttribute("data-key", key);
    container.appendChild(messageEl);
  });
}

// Request initial metrics and cache size
socket.emit("get_metrics");
socket.emit("get_cache_size"); 

// Request and display cached data log
function updateCacheLog(logLines) {
  const logDiv = document.getElementById("cache-log");
  if (!logLines || logLines.length === 0) {
    logDiv.textContent = "No cached data.";
    return;
  }
  logDiv.innerHTML = logLines.map(line => `<div class='log-entry'>${line}</div>`).join("");
}

socket.on("cache_log", function(data) {
  updateCacheLog(data.lines);
});

function requestCacheLog() {
  socket.emit("get_cache_log");
}
// Request on page load
requestCacheLog();
// Periodically update cache log every 10 seconds
setInterval(requestCacheLog, 10000);