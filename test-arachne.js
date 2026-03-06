// Test file with intentional issues for Arachne to catch

// Security issue: hardcoded password
const DB_PASSWORD = 'super_secret_12345';

// Bug: potential null pointer
function getUserName(user) {
  return user.profile.name; // No null check
}

// Performance issue: blocking loop
function processItems(items) {
  const results = [];
  for (let i = 0; i < items.length; i++) {
    // Simulating blocking operation
    const start = Date.now();
    while (Date.now() - start < 100) {} // Bad: blocking sleep
    results.push(items[i] * 2);
  }
  return results;
}

// Security: eval usage
function parseConfig(configString) {
  return eval(configString); // Dangerous!
}

// Missing error handling
async function fetchData(url) {
  const response = await fetch(url);
  return response.json(); // No check for response.ok
}

module.exports = { getUserName, processItems, parseConfig, fetchData, DB_PASSWORD };
