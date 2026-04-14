const ALARM_NAME = "cycle-tabs";

let paused = false;

// Open all URLs on install/startup
chrome.runtime.onInstalled.addListener(() => initialize());
chrome.runtime.onStartup.addListener(() => initialize());

// Cycle tabs on alarm
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === ALARM_NAME && !paused) {
    cycleToNextTab();
  }
});

// Alt+P to toggle pause/resume (message from content script)
chrome.runtime.onMessage.addListener((message) => {
  if (message.action === "toggle-pause") {
    paused = !paused;
    console.log("Monitor: tab switching", paused ? "paused" : "resumed");
  }
});

// Recreate alarm when settings change
chrome.storage.onChanged.addListener((changes) => {
  if (changes.intervalSeconds) {
    const seconds = changes.intervalSeconds.newValue || 30;
    chrome.alarms.create(ALARM_NAME, { periodInMinutes: seconds / 60 });
    console.log("Monitor: interval updated to", seconds, "seconds");
  }
});

async function loadConfig() {
  const response = await fetch(chrome.runtime.getURL("config.json"));
  return response.json();
}

async function getConfig() {
  const fileConfig = await loadConfig();
  const storageResult = await chrome.storage.local.get(["urls", "intervalSeconds"]);
  return {
    urls: storageResult.urls || fileConfig.urls || [],
    intervalSeconds: storageResult.intervalSeconds || fileConfig.intervalSeconds || 30,
  };
}

async function initialize() {
  const config = await getConfig();
  console.log("Monitor: opening", config.urls.length, "tabs");

  // Close all existing tabs except the first one (needed to keep the window open)
  const existingTabs = await chrome.tabs.query({});
  const keepTabId = existingTabs[0]?.id;

  // Create a tab for each URL
  for (const url of config.urls) {
    await chrome.tabs.create({ url, active: false });
  }

  // Close the original blank tab
  if (keepTabId) {
    chrome.tabs.remove(keepTabId);
  }

  // Activate the first tab
  const tabs = await chrome.tabs.query({ currentWindow: true });
  if (tabs.length > 0) {
    chrome.tabs.update(tabs[0].id, { active: true });
  }

  // Start the alarm for cycling
  chrome.alarms.create(ALARM_NAME, { periodInMinutes: config.intervalSeconds / 60 });
  console.log("Monitor: cycling every", config.intervalSeconds, "seconds");
}

async function cycleToNextTab() {
  const allTabs = await chrome.tabs.query({ currentWindow: true });
  if (allTabs.length === 0) return;

  // Pause cycling while an about: or chrome: tab is active
  const activeTab = allTabs.find((tab) => tab.active);
  if (activeTab?.url?.startsWith("about:") || activeTab?.url?.startsWith("chrome:")) {
    console.log("Monitor: paused, internal page is active");
    return;
  }

  const activeIndex = allTabs.findIndex((tab) => tab.active);
  let nextIndex = (activeIndex + 1) % allTabs.length;

  // Skip over about: and chrome: tabs
  const startIndex = nextIndex;
  while (allTabs[nextIndex].url?.startsWith("about:") || allTabs[nextIndex].url?.startsWith("chrome:")) {
    nextIndex = (nextIndex + 1) % allTabs.length;
    if (nextIndex === startIndex) return; // all tabs are internal pages
  }

  console.log("Monitor: switching to tab", nextIndex, "of", allTabs.length);
  chrome.tabs.update(allTabs[nextIndex].id, { active: true });
}
