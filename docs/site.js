/* Empty = early-access mailto. Set to the App Store URL when you have it. */
const APP_STORE_URL = "";

(function () {
  const el = document.querySelector("[data-store-cta]");
  if (!el) return;
  const url = APP_STORE_URL.trim();
  if (url) {
    el.innerHTML =
      '<a class="btn" href="' +
      url +
      '">Download on the App Store</a>';
    return;
  }
  el.innerHTML =
    '<p class="kicker">Coming to the App Store</p>' +
    '<a class="btn" href="mailto:hello@lumenow.app?subject=Lume%20early%20access">Get early access</a>';
})();
