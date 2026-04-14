const urlsTextarea = document.getElementById("urls");
const intervalInput = document.getElementById("interval");
const saveButton = document.getElementById("save");
const status = document.getElementById("status");

async function loadConfig() {
  const response = await fetch(chrome.runtime.getURL("config.json"));
  return response.json();
}

// Load saved settings, fall back to config.json defaults
async function loadSettings() {
  const fileConfig = await loadConfig();
  const result = await chrome.storage.local.get(["urls", "intervalSeconds"]);
  urlsTextarea.value = (result.urls || fileConfig.urls || []).join("\n");
  intervalInput.value = result.intervalSeconds || fileConfig.intervalSeconds || 30;
}

loadSettings();

saveButton.addEventListener("click", () => {
  const urls = urlsTextarea.value
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0);
  const intervalSeconds = Math.max(5, parseInt(intervalInput.value, 10) || 30);

  chrome.storage.local.set({ urls, intervalSeconds }, () => {
    status.classList.add("visible");
    setTimeout(() => status.classList.remove("visible"), 1500);
  });
});
