{ pkgs, ... }:

let
  cacheDir = "$HOME/.cache/wallpapers";
  archiveDir = "$HOME/Pictures/wallpapers/archive";

  # Seed set (public-domain NASA/ESA imagery, pinned via fetchurl + sha256 —
  # Constitution Principle II) so there's always something to show immediately after
  # a rebuild, before the first Wallhaven fetch completes, and as a fallback if the
  # API/network is ever unreachable when wallpaper-fetch runs.
  seedWallpapers = [
    (pkgs.fetchurl {
      name = "pillars-of-creation.jpg";
      url = "https://images-assets.nasa.gov/image/PIA25433/PIA25433~large.jpg";
      sha256 = "08r4ignh4gd1b2gxp4c45sjwwaqk7hrq3v9wri03fqm2c1z5hc4c";
    })
    (pkgs.fetchurl {
      name = "saturn-rings-cassini.jpg";
      url = "https://images-assets.nasa.gov/image/PIA06193/PIA06193~large.jpg";
      sha256 = "1301x3q1ahn3b5s3zhzyz78whlf0vsc18cdzmyi0g7rv774i70d3";
    })
    (pkgs.fetchurl {
      name = "mars-panorama-perseverance.jpg";
      url = "https://images-assets.nasa.gov/image/PIA24264/PIA24264~large.jpg";
      sha256 = "1r2jw30vh4vhjwmpxq3g36zcc9vym4s662sk8daw7sygn6nr8y00";
    })
    (pkgs.fetchurl {
      name = "aurora-from-iss.jpg";
      url = "https://images-assets.nasa.gov/image/iss072e159172/iss072e159172~large.jpg";
      sha256 = "0944j4mlsxnz5lh00hzsbh9m66gnlhi6z581d9fajxlw5ngg05w0";
    })
    (pkgs.fetchurl {
      name = "andromeda-galaxy-hubble.jpg";
      url = "https://images-assets.nasa.gov/image/GSFC_20171208_Archive_e000833/GSFC_20171208_Archive_e000833~orig.jpg";
      sha256 = "1x2bmm7l5xnhq10g1plvkw40mbwrjvk3xhkb63w2s2swqrxyvz65";
    })
    (pkgs.fetchurl {
      name = "sculptor-galaxies-hubble.jpg";
      url = "https://images-assets.nasa.gov/image/hubble-sees-a-legion-of-galaxies_25608651281_o/hubble-sees-a-legion-of-galaxies_25608651281_o~orig.jpg";
      sha256 = "1k0dcmy2v7sz39d11mwwgqv2yr9svpfwgm7lrjavkpnh7j3fzads";
    })
  ];

  seedDir = pkgs.linkFarm "scifi-wallpapers-seed" (
    map (w: {
      name = w.name;
      path = w;
    }) seedWallpapers
  );

  # Wallhaven search: anime category, "sci-fi" tag
  # applied at all — confirmed via a live test query to return more results, 577
  # total vs. the "111" form, with no API key needed).
  wallhavenQuery = "https://wallhaven.cc/api/v1/search?q=sci-fi&categories=010&purity=0&sorting=random";

  # Fetches new matches into ~/.cache/wallpapers (genuinely mutable runtime data —
  # can't live in the immutable Nix store), seeding from the pinned set on first run,
  # and prunes the cache back down to 40 images (oldest first) so it doesn't grow
  # unbounded. Falls back to leaving the existing cache untouched if the API/network
  # is unreachable, rather than failing. Capped at 12 new downloads per run (a fresh
  # set roughly matches the hourly fetch cadence without over-fetching).
  fetchWallpapers = pkgs.writeShellScript "fetch-wallpapers" ''
    set -euo pipefail
    ${pkgs.coreutils}/bin/mkdir -p ${cacheDir}

    if [ -z "$(${pkgs.findutils}/bin/find ${cacheDir} -type f -name '*.jpg' 2>/dev/null)" ]; then
      ${pkgs.coreutils}/bin/cp ${seedDir}/*.jpg ${cacheDir}/ 2>/dev/null || true
      ${pkgs.coreutils}/bin/chmod u+w ${cacheDir}/*.jpg 2>/dev/null || true
    fi

    response=$(${pkgs.curl}/bin/curl -fsSL "${wallhavenQuery}" || echo "")
    if [ -z "$response" ]; then
      echo "wallhaven API unreachable, keeping existing cache" >&2
      exit 0
    fi

    echo "$response" | ${pkgs.jq}/bin/jq -r '.data[0:12][] | "\(.id) \(.path)"' | while read -r id url; do
      dest="${cacheDir}/wallhaven-$id.jpg"
      [ -f "$dest" ] && continue
      ${pkgs.curl}/bin/curl -fsSL "$url" -o "$dest.tmp" && ${pkgs.coreutils}/bin/mv "$dest.tmp" "$dest" || ${pkgs.coreutils}/bin/rm -f "$dest.tmp"
    done

    ${pkgs.findutils}/bin/find ${cacheDir} -type f -name '*.jpg' -printf '%T@ %p\n' \
      | ${pkgs.coreutils}/bin/sort -rn | ${pkgs.coreutils}/bin/tail -n +41 | ${pkgs.coreutils}/bin/cut -d' ' -f2- \
      | ${pkgs.findutils}/bin/xargs -r ${pkgs.coreutils}/bin/rm -f
  '';

  rotateWallpaper = pkgs.writeShellScript "rotate-wallpaper" ''
    set -euo pipefail
    pic=$(${pkgs.findutils}/bin/find ${cacheDir} -type f -name '*.jpg' | ${pkgs.coreutils}/bin/shuf -n1)
    if [ -z "$pic" ]; then
      echo "no cached wallpapers yet" >&2
      exit 0
    fi
    ${pkgs.awww}/bin/awww img "$pic" --transition-type fade --transition-fps 60
  '';

  # Copies the currently-displayed wallpaper into a permanent archive
  # (~/Pictures/wallpapers/archive) that the fetch script's cache-pruning never
  # touches, so images you like survive even after they age out of the rotating
  # cache. Bound to a Hyprland keybind below.
  archiveWallpaper = pkgs.writeShellScript "archive-wallpaper" ''
    set -euo pipefail
    ${pkgs.coreutils}/bin/mkdir -p ${archiveDir}
    pic=$(${pkgs.awww}/bin/awww query -j | ${pkgs.jq}/bin/jq -r '.[""][0].displaying.image')
    if [ -z "$pic" ] || [ ! -f "$pic" ]; then
      ${pkgs.libnotify}/bin/notify-send "Wallpaper" "Nothing to archive"
      exit 0
    fi
    ${pkgs.coreutils}/bin/cp -n "$pic" ${archiveDir}/
    ${pkgs.libnotify}/bin/notify-send "Wallpaper archived" "$(${pkgs.coreutils}/bin/basename "$pic")"
  '';
in
{
  services.awww.enable = true;

  wayland.windowManager.hyprland.settings.exec-once = [
    "${fetchWallpapers} && ${rotateWallpaper}"
  ];

  # Archive the currently-displayed wallpaper permanently.
  wayland.windowManager.hyprland.settings.bind = [
    "$mainMod, W, exec, ${archiveWallpaper}"
  ];

  systemd.user.services.wallpaper-fetch = {
    Unit.Description = "Fetch new sci-fi/anime wallpapers from Wallhaven";
    Service = {
      Type = "oneshot";
      ExecStart = "${fetchWallpapers}";
    };
  };

  systemd.user.timers.wallpaper-fetch = {
    Unit.Description = "Fetch new wallpapers from Wallhaven hourly";
    Timer = {
      OnStartupSec = "30s";
      OnUnitActiveSec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.wallpaper-rotate = {
    Unit = {
      Description = "Rotate sci-fi desktop wallpaper";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${rotateWallpaper}";
    };
  };

  systemd.user.timers.wallpaper-rotate = {
    Unit.Description = "Rotate sci-fi desktop wallpaper every 5 minutes";
    Timer = {
      OnStartupSec = "1m";
      OnUnitActiveSec = "5m";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
