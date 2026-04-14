// Alt+P to toggle pause/resume
document.addEventListener("keydown", (event) => {
  if (event.altKey && event.code === "KeyP") {
    event.preventDefault();
    chrome.runtime.sendMessage({ action: "toggle-pause" });
  }
});
