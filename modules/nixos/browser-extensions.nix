{ ... }:

{
  programs.chromium = {
    enable = true;
    extensions = [
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
      "dnhpnfgdlenaccegplpojghhmaamnnfp" # Augmented Steam
      "kbmfpngjjgdllneeigpgjifpgocmfgmb" # Reddit Enhancement Suite
    ];
  };

  programs.firefox.policies.ExtensionSettings = {
    "uBlock0@raymondhill.net" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      installation_mode = "force_installed";
    };
    "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
      installation_mode = "force_installed";
    };
    "addon@darkreader.org" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
      installation_mode = "force_installed";
    };
    "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
      installation_mode = "force_installed";
    };
    "{1be309c5-3e4f-4b99-927d-bb500eb4fa88}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/augmented-steam/latest.xpi";
      installation_mode = "force_installed";
    };
    "jid1-xUfzOsOFlzSOXg@jetpack" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/reddit-enhancement-suite/latest.xpi";
      installation_mode = "force_installed";
    };
  };
}
