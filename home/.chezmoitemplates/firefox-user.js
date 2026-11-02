// Firefox: Wayland, multimedia, privacy and developer-friendly defaults.
// Preferences that Firefox controls dynamically are deliberately not forced.

// Desktop integration and appearance. Firefox follows the system color scheme
// dynamically through GTK and xdg-desktop-portal.
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);
user_pref("widget.use-xdg-desktop-portal.mime-handler", 1);
user_pref("widget.use-xdg-desktop-portal.settings", 1);
// Plasma supplies the scrollbar style; avoid GTK overlay scrollbars in Firefox.
user_pref("widget.gtk.overlay-scrollbars.enabled", false);

// Keep scrolling behavior explicit while rendering, WebRender, DMABUF and
// hardware video decoding remain automatic.
user_pref("general.smoothScroll", true);

// Balanced privacy: strong tracking protection without disabling DRM, WebRTC,
// password storage or other APIs commonly needed during web development.
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.globalprivacycontrol.enabled", true);
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_pbm", true);
user_pref("privacy.query_stripping.enabled", true);
user_pref("privacy.query_stripping.enabled.pbmode", true);
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);
user_pref("browser.urlbar.trimHttps", true);

// Reduce background reporting while retaining crash reports as an explicit
// user choice and keeping developer tools fully functional.
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("browser.discovery.enabled", false);
user_pref("browser.ping-centre.telemetry", false);

// Daily use and development.
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.tabs.loadBookmarksInTabs", true);
user_pref("browser.tabs.closeWindowWithLastTab", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.download.useDownloadDir", true);
user_pref("browser.download.alwaysOpenPanel", false);
user_pref("pdfjs.disabled", false);
user_pref("devtools.theme", "auto");
user_pref("devtools.chrome.enabled", true);
user_pref("devtools.debugger.remote-enabled", true);

// Hunspell dictionaries already installed on the system.
user_pref("spellchecker.dictionary", "es-ES,en-US,it-IT");
user_pref("layout.spellcheckDefault", 2);

// Discover client certificates exposed by the Linux system/OpenSC stack.
user_pref("security.osclientcerts.autoload", true);
