(function () {
    const lastUpdated = document.getElementById("lastUpdated");
    if (!lastUpdated) {
        return;
    }

    const now = new Date();
    lastUpdated.textContent = `Last refreshed: ${now.toLocaleString()}`;
})();
