#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; WARN=0; FAIL=0
REMOTE_OK=false
DAEMON=false
SCRIPT_NAME="$(basename "$0")"

pass() { PASS=$((PASS+1)); }
_warn() { WARN=$((WARN+1)); echo -e "  ${YELLOW}[WARN]${NC} $1"; }
warn() { _warn "$1"; $DAEMON && _notify normal "Warning" "$1"; return 0; }
_fail() { FAIL=$((FAIL+1)); echo -e "  ${RED}[FAIL]${NC} $1"; }
fail() { _fail "$1"; $DAEMON && _notify critical "Compromise Found" "$1"; return 0; }
info() { echo -e "  ${CYAN}[INFO]${NC} $1"; }

_notify() {
  local urgency="$1" summary="$2" body="$3"
  command -v notify-send &>/dev/null && notify-send -u "$urgency" -a "Atomic Arch Infection Checker" "$summary" "${body:0:200}"
}

# Remote sources for the latest known-infected package list
REMOTE_LISTS=(
  "https://gist.githubusercontent.com/quantenProjects/3f768dce7331618310f016d975bf8547/raw/beef579f8a8efeed6ccf60788e5b768775550095/packages"
  "https://cscs.pastes.sh/raw/aurvulnlist20260611.txt"
  "https://md.archlinux.org/s/SxbqukK6IA/download"
)

# Local fallback list used when remote fetch fails
# Last updated: 2026-06-14 (merged from md.archlinux.org HedgeDoc + community reports)
KNOWN_INFECTED=(
123pan-bin 1code 8188eu-dkms 8192eu-dkms-git abntex acpitool actual-ai adapta-gtk-theme-git adblock2privoxy adom-noteye
adsuck aion-git akira-git akonadi-git aksusbd albion-online-launcher-bin alfont algorand-devtools-bin alienfx alienfx-lite
alock-git alternating-layouts-git alttab-git alvr alvr-git ambiance-radiance-colors-suite amdgpu-fancontrol-git amdguid-wayland-bin amfora-favicons-git amide
amide-git amtterm amule-dlp-git android-backup-extractor android-docs android-google-play-apk-expansion android-google-play-licensing android-signapk android-signapk-gui android-support-repository
androidscreencast-bin angularjs annobin ansible-language-server ant-dracula-gtk-theme antfs-cli-git antichamber antileech anythingllm-appimage anythingllm-cli-bin
apache-ant-contrib apk-installer-gui apm_planner-bin apothem apple-music-desktop apprenticevrsrc-bin apwal aquaria-ose ar-smileys arachnophilia
arcadia arch-palemoon-search arch-update-vai archivemail archjh archlinux-themes-balou archlinux-themes-slim archmage archtex-git arduino-git
argouml aria2fe ariang-allinone arm-linux-gnueabihf-binutils arm-linux-gnueabihf-glibc-headers arm-linux-gnueabihf-linux-api-headers armitage-git artanis-git ascii-rain-git asciiworld-git
astah-uml astro-editor-appimage asus-fan-dkms-git atlassian-confluence atlassian-plugin-sdk atolm-openbox-theme atomicwalet atomicwalllet atto-bin audible-activator-git
audiere audiotube-git aura-browser aura-browser-git auryo autohand-cli autolabel autolatex autologin autozen
avarice-git avogadro2-git avra awesome-cinnamon awesome-revelation-git awoken-icons aws-cli-git aws-sam-cli ayatana-indicator-application azurlaneautoscript
backup2l backwild balena-cli bangin-server-node barrier-git basilisk-gtk2-bin batman-adv bazel-buildtools bbswitch-git bcachefs-kernel-dkms-git
bcalc bcnc bcoin-git bdf-creep beaker-browser-git beaker-ng-bin beancount-git beebeep beef beets-copyartifacts-git
bibtex2html bicon-git bin32-jre bing-wallpaper-git binnavi biosdevname bitcanna-wallet-bin bitcoin-core-git bittube-wallet-gui blackcoin-git
blackfire-agent blender-plugin-bim-git blender-plugin-vectex bleufear-gtk-theme blinkenlib blogc blt blueprint-compiler-git blueproximity-py3-git bonsai-browser
booklore boostnote-bin borg-git bouml bpytop-git bracket brightness-controller-git brother-hl3150cdw brother-hll6200dw brow6el
brow6el-git browserpass-git brscan3 bs-platform bsnes-plus-git btdex btdex-git burn-cd c++-gtk-utils-gtk2 c+gtk-utils-gtk2
caelum caja-deja-dup-bzr camotics camunda-modeler-plugin-bpmn-js-token-simulation canon-pixma-mg3000-complete-fixed capt-src capture cardano-addresses cardano-node cardano-wallet
cardano-wallet-bin carto-sql-api cartridge-cli castawesome castersoundboard-git catalyst5-browser cattle cavestory+-hb cb2bib ccase-bin
cccc ccl-git ccminer-git ccsm-gtk3 cdo centerim5-git cerbere-git cerebro certbox-bin cgminer
cgvg charcoal chexquest3-wad chez-scheme-git chia-cli-git chia-git chicken-srfi-180 chipmachine chipmunk chisel
chromeos-apk-git cinny-desktop-system-tray cint cjs-git cl-javascript cl-parenscript cl-parse-js clai clamfs clang15
clang19 clash-mi claude-code-router claymore-miner-bin clevo-xsm-wmi cling-git cling-jupyter-git clipgrab-kde cmake-modules-webos-git cmospwd
cmuclmtk cnijfilter-common cnijfilter-common-mg5400 cnijfilter-ip110 cnijfilter-mp550 code-git code-notes-bin codeclimate codeigniter codenomad-bin
codeql-cli-bin coffeescript-git cogpit-bin colorhug-client colorsvn colorz compiler-rt19 compiz-fusion-plugins-experimental compiz-fusion-plugins-experimental-git compiz-fusion-plugins-extra
compiz-fusion-plugins-extra-git compizconfig-python compizconfig-python-git complexity concordium-desktop-wallet-appimage concordium-desktop-wallet-bin concordium-desktop-wallet-testnet-bin concordium-node-bin connman-ncurses connman-ncurses-git
connman-ui-git containerd-git contemporary-cursors controllermap coolreader coolreader3-git coppeliasim-bin cowdancer coyim cpp-netlib
cppreference-devhelp cpu-monitor-extension-lxpanel-plugin cpufreqd cpuminer-git cpuminer-multi cpuminer-multi-git cpuminer-opt cpuminer-opt-sugarchain cpuset craftbukkit-plugin-worldedit
create-next-app createvm cross-mingw-w64-gdb cryptoplugin cryptowatch-desktop-bin ctjs-bin cubieboard-livesuit cura cura-plugin-octoprint-git curecoin-qt-git
curecoind-git curseradio-git cutefish-calculator cutefish-core cutefish-dock cutefish-filemanager cutefish-icons cutefish-launcher cutefish-qt-plugins cutefish-screenlocker
cutefish-screenshot cutefish-settings cutefish-statusbar cutefish-wallpapers cutemarked-git cvs-feature-bin cvs2svn cwiid cxo cynthiune.app
d1x-rebirth daala-git daggerfall-addons dagu-bin dahdi-linux dalbum darwinia dashcore datatype99 davtools
dbxcli deepin-mail-bin deepin-wine6-stable deheader delaycut denaro deno-git dep desktopnova desync-git
dexed-ide-bin dfhack dfhack-bin dh-python dianara dibuja difi difi-bin digikam-without-akonadi digitemp
discord-qt distrho-ports-lv2-git dkopp dmg2dir docker-gc-git docopts doctoc doom3-inhell doomsday dot-git
dots-hyprland-fork-git dptf drascula drbl-experimental drkonqi-git drm_tools droopy-git dropbox-kde-systray-icons dsd dsdcc-git
dub-git dukto dvbcut dvdrip dvorak7min dyad-bin dynamodb e4rat-lite-git easy_spice easymp3gain-qt4-bin
easytag-git echinus-git echo-icon-theme-git eclipse-checkstyle eclipse-i18n-de eclipse-i18n-fr eclipse-markdown edconv-bin edfbrowser-git edx-downloader-git
eel-language efiboots-git eisl electron-cash-slp electroneum electrum-bin electrum-nmc electrum-ravencoin-appimage elements-project elements-project-bin
elinks-git elixirscript elm-format-bin elm-platform elmerfem emacs-color-theme emacs-d-mode emacs-ess-git emacs-find-recursive emacs-icicles
emacs-identica-mode emacs-jabber emacs-jabber-git emacs-js2-mode-git emacs-magit emacs-mew emacs-mmm-mode emacs-paredit emacs-pkgbuild-mode-git emacs-popup-el
emacs-sml-mode emacs-solidity-mode-git emacs-yasnippet-git emerald-wallet-bin emms-git encryptr energyplus envoy-git envypn-font eperiodique
epson-inkjet-printer-escpr2-clos-bin errut eslint-plugin-promise eslint-plugin-react eslint-plugin-vue esteem-bin etherpad-lite ethlint-git etmtk eviacam
evilvte-git evilwm evopedia-git evopop-gtk-theme evopop-icon-theme exact-image exiftags exodas exodis exodud
exodus-wallet exodus-wallet-bin exodusae exoduss exoduswallet exodux exoduz exodys exouds fanicontrol
fantom farmmod-hub fasd-git fastjet fastoggenc fatx fbctrl fbff-git fcitx fcitx-baidupinyin
fcitx5-pinyin-sougou-dict-git featherwallet-appimage felida-bin felinks-python fengoffice ffdiaporama-texturemate ffmpeg-bitrate-stats ffmpeg-quality-metrics ffmpeg3.4 fifth
fifth-git filebot47 findpkg-git firebird firefox-babble firefox-esr-extension-privacybadger firefox-esr-globalmenu firefox-esr-noscript firefox-esr-ublock-origin firefox-extension-adnauseam-bin-amo
firefox-extension-duckduckgo-privacy-essentials firefox-extension-gooreplacer firefox-floccus firefox-librejs firefox-user-agent-switcher-and-manager-bin firmium-desktop-git firmware-mod-kit fisher-git fishui fishui-git
flashbrowser flashfocus flatcam-git flexiblas flow flow-browser-git flow-git flow-pomodoro flowblade-git flv2x264
flynarwhal fmlib fontfinder fontweak forgecode-bin formidable-bin fortune-mod-firefly fpp-git frame freemind-git
freeter frutool fs2-knossos fs2_open-mediavps fspy fstar-git ft232r_prog ftl fuego-svn fuel
fusion-icon fusion-icon-git futhark-bin fwlogwatch g2 g3data gahshomar gaiaui-amd galaxy2 gameflow-deck-git
gamma-launcher ganyremote garlium-git garmindev gavrasm gcal gcccpuopt gcstar gcstar-gitlab gdl
gdlmm gdlmm-docs gecode geekcode geforcenow-electron gemistdownloader get_flash_videos getlive gfxbench ggoban
gimp-plugin-arrow gist-git gisto git-annex-standalone git-flow-completion-git git-open git-remote-hg-git git-time-machine gitflow-avh gitfs
gitinspector gitosis-git gitso gitter-bin gjs-git gkraken gle-graphics globalplatform globalprotect-bin glosstex
glsl-debugger-git gminer-bin gmp4 gmt-coast gmt-cpt-city gnomato gnome-battery-bench-git gnome-contacts-git gnome-directory-thumbnailer gnome-pass-search-provider-git
gnome-randr-rust gnome-rdp gnome-shell-extension-cpufreq-git gnome-shell-extension-custom-hot-corners-extended gnome-shell-extension-dynamic-top-bar gnome-shell-extension-hibernate-status-git gnome-shell-extension-topicons-plus gnome-shell-extension-transmission-daemon-git gnome-shell-extension-x11gestures gnome-shell-theme-arc-clearly-dark-git
gnome-specimen gnome-terminal-fedora gnome-usage-git gnome-xcf-thumbnailer gnuplot-git gnutls3.8.9 gobyte-qt gog-the-witcher-2-assassins-of-kings gogs-git gohufont-powerline
google-authenticator-libpam-git gopenvpn-git gopher2600 gopher2600-bin goqat gosh gpicsync gpshell gpx-viewer gr-osmosdr-git
graal-bin graal-nodejs-jdk17-bin graal-nodejs-jdk20-bin gram-wallet-bin graveman green-tunnel-bin greenisland greetd-wlgreet-git gridmgr-git grim-git
grpn grub-luks-keyfile grub4dos gsettings-desktop-schemas-git gsettings-system-schemas-git gtk-theme-bsm-simple gtk-theme-metagrip gtk-theme-windows10-dark gtk-vnc-gtk2 gtkimageview
gtksetpwc gtkterm-git guake-colors-solarized-git guile-git guile-reader guile-ssh guiscrcpy gulden-appimage gummy gummy-git
gutenpy gxemul ha-pacemaker-git hack-browser-data-git hackmatrix-git halberd happy-cli hardcode-tray harminv harmony-wad
haskell-asn1-data haskell-chart haskell-failure haskell-hscurses haskell-hssyck hattrick_organizer haunt haxe-git hd2u hdx-512-git
headphones hearthstone-linux-gui-appimage hearthstone-linux-gui-bin hepmc2 hexchat-otr hfstospell hifive1-sdk-git hister-git hnswlib-git homeassistant-osagent
homeassistant-supervised hop horst hotlinemiami howm-x11-git howto-bin hp-health hpgcc hpoj htbrowser-bin
htdig htop-vim-solarized-git httpry huawei-stat-e220 hudkit-wayland humen-mcp-git hunter hydownloader-git hydrapaper-git hydrus-git
hypervc-qt4 hypr-git i2c-ch341-dkms i3-gnome-git i3bar-river i3lock-fancy-dualmonitors-git ianny-bin ibc ibm-sw-tpm2 ibus-uniemoji-git
icdiff-git ice-ssb iceweasel ideviceinstaller-git ifcopenshell-git igdm ihaskell-git ijavascript ike ikos
imageglass img2djvu-git inadyn inadyn-mt indicator-session infinity-background infnoise-openssl-git inform7 inkslides-git intelmetool-git
intelpwm-udev interface99 ios-webkit-debug-proxy ipfs-desktop-bin ipsw iptrafvol iron-heart-git irssistats isight-firmware-tools itop
j4-make-config-git ja2-stracciatella-git jade-application-kit jade-application-kit-git janusvr jasmin jasp-desktop java-berkeleydb java-flexdock java-qdox
javahelp2 jd-gui jdk-openj9-bin jdk11-openj9-bin jdk17-jetbrains-bin jdk8-graalvm-bin jetbrains-mps jflex jin joxi
joy joycon-git joymouse jreen-git js-design js-design-agent-bin js-design-appimage jspm-cli jstock jupyter-nbextension-rise
just-js just-js-completion jzip k3sup k4dirstat kalu-git kapacitor kapidox-git katrain kcmlaptop
kdb kddockwidgets-git kde-svn2git kdelibs kdevelop-pg-qt-git keep keepass-fr keepass-plugin-qualitycolumn keepassx2 keeperrl-git
kexi kibana5 kibana6 kicad-library-ab2-git kiconedit kimageformats-git kio_gopher kiss kmarkdownwebview kmorph
kodi-addon-inputstream-adaptive-git kokua-secondlife kompare-git kookbook kopano-core kotatogram-desktop koules kproperty krakatau-git kreport
kristforge-bin ktea kubo-git kvirc-git kwin-effects-blur-respect-rounded-decorations-git kwin-scripts-quarter-tiling-git kwplayer lab-bin ladish laditools
lash lastfmlib latex-digsig latex-make latex-mk lazylpsolverlibs-git lbench ledger-udev-bin ledgerlive ledgerlive-bin
legofy-git leocad-git lesstif lexmark_pro700 lib32-egl-wayland lib32-fftw lib32-freeimage lib32-gimp lib32-gnome-themes-extra lib32-graphene
lib32-libfmod lib32-libjson lib32-libmad lib32-libreplaygain lib32-libxpm lib32-libxxf86dga lib32-mtdev lib32-tk libafterimage libakonadi-git
libarcus-git libavif-noglycin libbobcat libcompizconfig-git libcsa-git libcss-git libcutefish libdill libdivecomputer-git libevdevc
libffi-static libfprint-vfs_proprietary-git libfreenect-git libgdata libgtkhtml libheif-noglycin libhugetlbfs libisl15 libjxl-noglycin libjxl-noglycin-doc
libkarma libkdcraw-git libkomparediff2-git libmrss libnautilus-extension-git libnbcompat libntru libnxml libopenaptx-git libprelude
libptp2 libpurple-carbons-git libpurple-lurch libpurple-lurch-git libpurple-meanwhile libpuzzle libquvi libquvi-scripts libreoffice-extension-coooder librep
librep-git libretro-hatari-enhanced-git libretro-mame-git libretro-mednafen-supergrafx-git librewolf-extension-duckduckgo-privacy-essentials librewolf-extension-protonpass-bin librewolf-extension-vimiumc-bin libsingularity-git libsmi libspatialindex-git
libtcd libtorrent-ps libtrash libuiohook libviper libwapcaplet-git libxaw3dxft libxdiff libxml-ruby libyami
lightdm-webkit-theme-userdock lilypond-git limbo-hib limesuite-git linkerd linphone-desktop-all linphone-desktop-all-git linphone-plugin-msx264 linux-bcachefs-git linux-bcachefs-git-headers
linux-cachyos-deckify-native linux-cachyos-deckify-native-headers linux-cachyos-native linux-cachyos-native-headers linux-cachyos-native-nvidia-open linux-cachyos-rc-native linux-cachyos-rc-native-headers linux-cachyos-rc-native-nvidia-open linux-manjaro-xanmod linux-manjaro-xanmod-headers
linux-rc linux-rc-headers linux-steam-integration linux-tool linux-xanmod-rog linux-xanmod-rog-headers linux_logo_archcustom linvst liri-cmake-shared-git liri-shell-git
lite lld19 lll llvm-cbe-git lndhub lorem-ipsum-generator love09 lowfi-bin lrexlib-pcre5.1 ls++
lsx lttng-modules lua51-sql-sqlite luazip5.1 lucidvideo luksipc-git lure lv lwan-git lwxc-git
lxdvdrip lxqt-qt5ct lynis-git lyvi-git lzham m5rcode mac-os-lion-cursors machinarium madsonic magicassistant-gtk
magiwallet-magid-ruckard-raspi4 magpie-wm make-3.81 mako-center-git mantissa manuskript mapbox-studio mapcrafter-git marcfs-git markmywords-git
marytts masari maszyna-git mathsat-5 mato-icons-git matrixbrandy maxima-git mbm-gpsd-pl4nkton-git mc-skin-modarin-debian mcp-probe
mcpatcher mdbook-compress me_cleaner-git meliora-openbox-themes melis-wallet-bin melvor-mod-manager menu-cache-git menumaker-compiz mermaid-ascii-git mermark-editor
mesa-dlss-reflex-git mesecons-git mesos meteo mictray mikidown-git milena milena-data milton-git mime-archpkg
mimic-node-git minder-git minecraft-overviewer minecraft-overviewer-docs minecraft-overviewer-docs-git minecraft-overviewer-git minergate-cli minergate-gui minetest-subway-miner mingw-w64-adwaita-icon-theme
mingw-w64-duktape mingw-w64-geos mingw-w64-gtk2 mingw-w64-laz-perf mingw-w64-libcroco mingw-w64-libidn mingw-w64-libsndfile mingw-w64-libtasn1 mingw-w64-libtheora mingw-w64-pcre
mingw-w64-sdl mingw-w64-sdl2_ttf minichrome minify-js-bin minimax-bin-hardened miniongg minitube miro-video-converter mirrorlist-rankmirrors-hook misuzu-music-bin
mkdocs-bootswatch mkgmap-svn mmc-utils-git mobac-svn mojave-ct-icon-theme mon2cam-git mongo-cxx-driver-legacy-0.0-26compat mongrel2 mono-addins mono-addins-git
monochrome monochrome-git montecarlo-font moonshiner moor-git mopen mopidy-moped mopidy-youtube mount-gtk movgrab
mp3guessenc mpir mqttfx-bin ms-office-online msieve multimon-ng-git multiwinia murmur-git mwc-qt-wallet-bin mxnet
mxnet-cuda mxnet-mkl mxnet-mkl-cuda mygnuhealth mysqltuner-git mythes-cs n-ninja n1-translator naemon naemon-livestatus
nanocurrency nanocurrency-node natapp nautilus-folder-icons nautilus-git nautilus-mediainfo nautilus-renamer ncl ncursesfm-git ndyndns
nebuchadnezzar-git necpp-git nem-wallet nemerle neochat-git neovim-autopairs-git neovim-gtk-git neovim-nvim-treesitter neovim-telescope-file-browser-git nerf-pi
netmenu netmon-git netrik networkmanager-dispatcher-pdnsd networkmanager-ssh-git neuro-karaoke-wrapper-git neuron-zettelkasten-bin neuropolitical-ttf new-api-privacy-filter new-api-privacy-filter-git
nextcloud-app-audioplayer nextcloud-app-carnet nextcloud-app-facerecognition nextcloud-app-gpoddersync nextcloud-app-integration-dropbox nextcloud-app-integration-google nextcloud-app-repod nextcloud-app-twofactor-gateway nextcloud-git nexus-bin
nginx-mod-vts nhentai-git nheqminer-cuda-git nikki nikola-git nip2 nipaplay-reload-bin nitrogen-git nixnote2 nixnote2-git
nocodb noctyra-dotfiles-git noctyra-meta-git nodejs-broccoli-cli nodejs-browser-sync nodejs-budo nodejs-color-convert nodejs-dicy-cli nodejs-docs nodejs-elm
nodejs-forever nodejs-hotel nodejs-how2 nodejs-ionic nodejs-istanbul nodejs-js2coffee nodejs-jscs nodejs-jsdoc nodejs-jsfmt nodejs-json-to-js
nodejs-markserv nodejs-mathjs nodejs-mkdirp nodejs-mssql nodejs-node-lambda nodejs-nodemailer nodejs-nodeppt nodejs-nodeunit nodejs-passport nodejs-pkg
nodejs-qunit nodejs-redis-commander nodejs-sails nodejs-shelljs nodejs-sweet nodejs-telegraf nodejs-triton nodejs-vim-debugger nodejs-webpack nodejs-ws
nody-greeter non-daw-git nordnm notepad---bin notify-desktop-git notion-app-enhanced nox-bin npm-accel nrpe ntk-git
num-utils numix-gtk-theme numix-themes-electric numix-themes-green nuxhash-git nvdock-bumblebee nvidia-xrun-git nwchem nwchem-bin nx3-all
ob-xd ob-xd-common ob-xd-lv2 ob-xd-standalone ob-xd-vst3 obfs4proxy-bin ocaml-js_of_ocaml ocaml-lambda-term ocaml-sexplib ocaml-textutils_kernel
ocaml-typerex ocaml-xmlm oclint octave-hg octave-miscellaneous octocode oh-my-git ohcount ohcount-git olivia-git
omnidb-server open-axiom open-hexagon-git openav-sorcer-git openclaude-bin opencode-codebase-index-bin opencorsairlink-git opendrop openhab2 openhab3
openlayers openms openmsx-catapult opennebula openpyn-nordvpn openssh-gui-git openstego openui5 openxray opl-synth
optimizevideo-git oracle-bin organize-bin orientdb-community osmose osvr-libfunctionality-git otcl oterm otf-inconsolata-g-powerline-git otf-sauce-code-powerline-git
ovras owncloud-client-git oxefmsynth oxygen-gtk3-git pacforge pacgem pandacoin-git panopticon-git pantheon-applications-menu-git pantheon-print-git
pantheon-session-git pantum-driver panwriter paper-desktop-bin papirus-color-scheme papirus-maia-icon-theme-git paq8o parallel-python pass-cli pb-for-desktop
pbincli pcb2gcode pcsxr-git pdf2book pdf4qt-git pdi-ce peepdf pelican-git pencil-android-lollipop-stencils-git pencil-material-icons-git
penguin-subtitle-player perl-css perl-datetime-format-sqlite perl-debug-client perl-getopt-euclid perl-graph perl-gtk2-ex-podviewer perl-gtk2-ex-simple-list perl-gtk2-gladexml-simple perl-http-request-ascgi
perl-io-capture perl-javascript-packer perl-lwp-protocol-http10 perl-lwp-useragent-determined perl-lyrics-fetcher perl-orlite perl-proc-parallelloop perl-set-object perl-term-extendedcolor perl-test-corpus-audio-mpd
perl-text-aspell perl-xml-dom petri-foo pfstools pg2ipset-git pgcli-git pgl pgpool-ii phantom-wallet pharo-bin
phoenix phonon-qt4 phonon-qt5-vlc php-blackfire php-geoip php-legacy-geoip php-legacy-memcache php-memcache php-openswoole-git php-xdiff
phpdocumentor2 phpredis-git picom-ftlabs-git picpuz pidgin-cmds pidgin-im-gnome-shell-extension pidgin-kwallet pidgin-nudge-svn pine64-rkdeveloptool-git pinegrow
pipetoys pipewire-visualizer-git pk2cmd-plus pkgdistcache pktd pktstat planck plank-theme-arc plasma5-wallpapers-video-git plasma6-applets-fancytasks
plasma6-splashscreen-kuro-git playhouse playhouse-git plex-media-player-custom plex-media-player-mod plex-media-player-v2 plex-trakt-scrobbler plowshare-git pluma-plugins plymouth-theme-asphyxia-git
plymouth-theme-chain plymouth-theme-monoarch pmount-safe-removal pmus-git png22pnm pnmixer-gtk3 poi-nightly-bin poldi polkadot-js-desktop-bin polkit-qt4
powwow ppcoin-qt premake-git prisma4postgres-bin privacy-redirect-git profile-sync-daemon-zen protoc-gen-ts psi-plus-plugins-git psi-plus-resources-git pulseaudio-dlna-cygn
pulsemixer-git puppy-browser purescript purple-facebook-git pygist-git pyload-ng pymacs pymedusa pypi-cli pypiserver
pypy-setuptools pyrescene-git python-affine python-apt python-argdispatch python-autopep8-git python-avalon_framework python-awkward python-axolotl-git python-browserid
python-calmjs python-celery python-cerealizer python-chompjs python-ci-info python-coolname python-coremltools python-cu2qu-git python-dataproperty python-dbapi-compliance
python-dictobject python-dj-database-url python-django-js-asset python-django-js-asset-git python-django-modelcluster python-django-rest-knox python-dugong python-epc python-fastmcp-slim python-finnhub-python
python-firebase-admin python-fmu_manipulation_toolbox python-future python-g4f python-gmpy python-hist python-histoprint python-hnswlib-git python-hsaudiotag3k python-iminuit
python-iminuit-docs python-iso3166 python-isounidecode python-isr-git python-jsmin python-json2xml python-kiss-headers python-luckydonald-utils python-miio python-milvus-lite-bin
python-mmcif python-monotonic python-mplhep python-mplhep_data python-netaudio-git python-netaudio-lib python-newspaper4k python-nipype python-nodejs-wheel python-nodejs-wheel-binaries
python-openai-harmony python-orange python-pdf2docx python-piecash python-pluginmgr python-poetry-plugin-dotenv python-privy-git python-pushbullet.py python-pychromecast-git python-pydns
python-pylsp-rope python-pymilvus python-pyrogram python-pysocks-git python-quamash-git python-rembg python-resvg python-resvg_py python-scikit-hep-testdata python-single-version
python-sklearn-pandas python-sqliteschema python-stagger-git python-starlette-compress python-starsessions python-steamcontroller-git python-tabledata python-tarantool python-tradingeconomics python-uhi
python-uproot python-uproot-docs python-vector python-vincenty python-webassets python-xtarfile python2-appdirs python2-cffi python2-chardet python2-cssselect
python2-ctypes python2-fusepy python2-gobject python2-lazr-uri python2-lhafile python2-mutagen python2-notify python2-packaging python2-paver python2-pyparsing
python2-simplejson python2-simpleparse python2-stomper python2-twodict-git python2-xlib pytomtom pyxplot qbittorrent-enhanced-qt5 qconf-git qemacs
qemu-android-x86 qeven qhttpengine qinfo qlementine qmdnsengine qmltermwidget-git qnapi qobuz-player-bin qpitch
qrfcview qscite qshntoolsplit qt-inspector-git qt-solutions-git qt5-3d qtum-core qtvkbd quack qucs
quickrdp quickswitch-i3 qutepart-git qv2ray-git qwt-qt4 r-dbplyr r2-iaito-git r8101-dkms rabbitvcs-cli raccoon
raccoon-git raceintospace radare2-bindings radare2-bindings-git radare2-pipe-git radium rainbarf-git rainloop rarian ratox-git
raven-qt rayforge rbutil-git rdm-bin rdup reactphysics3d reactphysics3d-docs realtimeconfigquickscan-git refind-theme-dreary-git remotemouse
rep-gtk repoporge resetmsmice retibbs-client-git retrovol rgain3 rhythmbox-git rhythmbox-llyrics rhythmbox-plugin-alternative-toolbar-git rimworld
rke rkflashtool rkward-git roccat-dkms rock rodentbane-git rog-helper-git rolo ros2-arch-deps ros2-humble-nav2-msgs
rstudio-server-git rtags rtags-git rtbth-dkms rtf2latex2e rtorrent-ps rtorrent-pyro-git rtspeccy-git ruah-orch ruby-actionmailer
ruby-actionview ruby-activemodel ruby-activerecord ruby-blankslate-2 ruby-classifier ruby-colored ruby-commander ruby-compass ruby-excon ruby-execjs
ruby-fast-stemmer ruby-haste ruby-kramdown-rfc2629 ruby-libvirt ruby-mpd ruby-oauth ruby-parslet-1.5 ruby-pusher-client ruby-pygments.rb ruby-railties
ruby-rubysdl ruby-selenium-webdriver ruby-sprockets ruby-sprockets-rails ruby-thread_safe ruby-travis rumor run-mailcap runescape-launcher rxvt-unicode-256xresources
sachesi-bin sakura-launcher-gui saleae-logic saleae-logic-beta salt-git samba-mounter-git samsungctl sandlock satanic-icon-themes sawfish-git
sbt-extras-git scallion scangearmp-mg3500series scanssh scavenger scm screenpipe-bin sdcc-bin sddm-stellar-theme sdformat
seahorse-nautilus selenium-server-standalone sentry sequencer64-git sex sfarkxtc sfnt2woff shadow-tech shadowgrounds sheeplifter
shellcheck-git shellinabox-git shhmsg shhopt shifty-git shrinkpdf sickrage-git sidplay2-libs signald silver-searcher-git
sixfireusb-dkms skanlite-git skdet slim-unicode slime-git slipnet slipnet-bin smartsim-git smenu smenu-git
smolrtsp smolrtsp-libevent snapd-git snis-git snowman-git snry-shell-bin snry-shell-qs so-synth-lv2-git soapyptezuka socnetv
softethervpn-client-manager sogo2 solara-kernel-headers soldat-git sonar-icon-theme sonixd sonosano sope2 soundpaad-bin soxt
spigot-plugin-essentials splashtop-business spring-ba sqliteman sqsh squirrelmail sshuttlee sshuttlee-bin stable-diffusion-webui-git staden
staden-io_lib stag-git statusnotifier stegsolve stencyl stlarch_font stompbox-jack-git streetsofrageremake stripe-cli structuresynth
stylelint-config-recommended stylelint-config-standard subbrute sublime-music sublist3r-git submarine subprocess subsync sunclock sundtek
svu sway-screenshot sway-xkb-switcher switchboard-git sword-svn sync-my-l2p syslog-notify t4kcommon tack taipan
taoframework tarantool taskunifier tasmotizer-git tbs-dvb-drivers tbsecp3-driver-git-dkms tcpstat tdesktop-nolimit telegram-desktop-dev telegram-tdlib-purple-git
telepresence termbox-git terminusmod tesseract-gui test-malicious-nuke test-malicious-reset texlive-moderncv-git textsuggest-git thinkingrock thinkwatt
thunar-nextcloud-plugin thunderbird-conversations thunderbird-sieve tiemu tif22pnm tiger tinyemu tllocalmgr-git tlpui-git tnote
toggldesktop toggldesktop-bin tomighty toolsched toontown-rewritten tor-messenger-bin tora torch7-cutorch-git torch7-git torch7-image-git
torch7-trepl-git tortoisehg-hg touchhle touchosc-bin toybox tpp trace-cmd-git tracks tramp transcreen
translate-shell-git transmission-gtk-git truestudio trytond tsm tsocks-tools ttcp ttf-consolas-powerline ttf-dejavu-emojiless ttf-dejavu-sans-mono-powerline-git
ttf-essays ttf-impallari-dosis ttf-lcsmith-typewriter ttf-material-design-icons-git ttf-mutant-emoji ttf-pizzadude-bullets ttf-roboto-fontconfig ttf2eot tunacode-cli tup-git
tuxboot-git tvnamer tweeny typing-game-cli ucsf-chimera udev-browse-git udfclient uget-integrator ukui-notification-daemon undistract-me-git
uni2ascii unifi-beta unyaffs uplink-hib upower-nocritical urbanbrawl-wad urho3d urjtag-git usbmount v2ray-geoip-custom
vapoursynth-preview-git vbam-git vcp-git vdirsyncer-git vdrift vectr veracrypt-git verso-git vertx vidalia
vidcutter video-contact-sheet viennacl vim-clang-complete-git vim-delimitmate vim-easymotion vim-fortran vim-gitgutter vim-hexman vim-indent-object
vim-lighttpd vim-live-latex-preview vim-manpageview vim-molokai vim-molokai-git vim-octave vim-omlet vim-pandoc-syntax-git vim-pathogen-git vim-perl-support
vim-pythonhelper vim-solidity vim-vital vinetto violetland-git virtscreen virustotal visualstudio vlc-arc-dark-git vms-empire
vnote vocalinux-git volumeicon-git voquill-gpu vte-legacy vtigercrm vuze-extreme-mod vuze-plugin-countrylocator vuze-plugin-mldht wallpaper-generator-next
wally watchman watsup wavbreaker wayland-static wcalc wds we-layerd-git webilder-gtk-patched webui-aria2-git
wechat-devtools weex wemux-git wesnoth-git whatsie-git whisper2tr whisper2tr-git whitebox whysynth windowmaker-git
windows2usb-git wine-nine wineasio-git wings2 wire-desktop wiringpi-git wlroots-nvidia wmtop word-snatchers-cli workbench
workbuddy-bin wrestic-bin writefreely writefull-bin wrystr-git wsjtx-beta wunderline wxbase x2vnc-no-xinerama xapian-omega
xarchiver-assume-name xcursor-gt3 xerox-phaser-6000-6010 xevdevserver xf86-input-cmt xf86-input-joystick xf86-input-mtrack xf86-input-mtrack-git xf86-input-wizardpen xfce-theme-bluebird
xforms xorg-transset xorg-xfsinfo xorg-xinit-git xosview xplot xpra-html5 xray-domain-list-community xsp xspin
xss-lock-git xsvg xsynth-dssi yafaray yafaray-git yarg yay4 yersinia yii yofrankie
yokadi yt6801-dkms yy z-push zafiro-icon-theme zaproxy-weekly zathura-gruvbox-git zdoom-git zecwallet zelda-roth-se
zenbound2 zenmonitor zenphoto zenpower-dkms zephyr zeroinstall-injector zerx-lab-dida-bin zerx-lab-zed-nightly-bin zing-17-bin zing-21-bin
zing-8-bin zinnia-python zrythm-git zsdx zxtune-git
)

# Fetch latest infected package list from remote sources
fetch_remote_list() {
  local tmpfile
  tmpfile=$(mktemp)
  local url
  for url in "${REMOTE_LISTS[@]}"; do
    if command -v curl &>/dev/null; then
      if curl -sfL "$url" 2>/dev/null > "$tmpfile"; then
        REMOTE_OK=true
        break
      fi
    elif command -v wget &>/dev/null; then
      if wget -qO- "$url" 2>/dev/null > "$tmpfile"; then
        REMOTE_OK=true
        break
      fi
    fi
  done
  if $REMOTE_OK && [ -s "$tmpfile" ]; then
    local added=0
    while IFS= read -r pkg; do
      [ -z "$pkg" ] && continue
      [[ "$pkg" =~ ^[a-zA-Z0-9][a-zA-Z0-9@._+-]*$ ]] || continue
      # Check if already in KNOWN_INFECTED
      local already=false
      for existing in "${KNOWN_INFECTED[@]}"; do
        [ "$existing" = "$pkg" ] && { already=true; break; }
      done
      if ! $already; then
        KNOWN_INFECTED+=("$pkg")
        added=$((added + 1))
        [ "$added" -ge 500 ] && break
      fi
    done < "$tmpfile"
    info "Merged $added new entries from remote list"
  fi
  rm -f "$tmpfile"
}

# --- Install / Remove / Notify helpers ---
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_NAME="check-atomic-arch"
SERVICE_FILE="$SERVICE_DIR/$SERVICE_NAME.service"
TIMER_FILE="$SERVICE_DIR/$SERVICE_NAME.timer"
AUTOSTART_LUA="$HOME/.config/hypr/autostart.lua"

_install() {
  local script_path
  script_path="$(realpath "$0")"
  mkdir -p "$SERVICE_DIR"

  cat > "$SERVICE_FILE" << EOF2
[Unit]
Description=Atomic Arch Infection Checker
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$script_path --daemon
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF2

  cat > "$TIMER_FILE" << EOF2
[Unit]
Description=Periodic Atomic Arch Infection Check

[Timer]
OnBootSec=5min
OnUnitActiveSec=6h
Persistent=true

[Install]
WantedBy=timers.target
EOF2

  if systemctl --user daemon-reload 2>/dev/null; then
    systemctl --user enable --now "$SERVICE_NAME.service" 2>/dev/null || true
    systemctl --user enable --now "$SERVICE_NAME.timer" 2>/dev/null || true
  else
    echo "  (systemd user bus not available - service files created but not enabled)"
  fi

  if [ -f "$AUTOSTART_LUA" ] && ! grep -q "$SERVICE_NAME" "$AUTOSTART_LUA" 2>/dev/null; then
    echo "o.launch_on_start(\"$script_path --daemon\")" >> "$AUTOSTART_LUA"
    echo "  Added autostart entry to $AUTOSTART_LUA"
  fi

  echo -e "${GREEN}Installed:${NC} systemd $SERVICE_NAME.service + $SERVICE_NAME.timer"
  echo "  Service will run at every boot and every 6 hours."
  echo "  Notifications will appear via mako if issues found."
}

_remove() {
  if systemctl --user daemon-reload 2>/dev/null; then
    systemctl --user disable --now "$SERVICE_NAME.service" 2>/dev/null || true
    systemctl --user disable --now "$SERVICE_NAME.timer" 2>/dev/null || true
  fi
  rm -f "$SERVICE_FILE" "$TIMER_FILE"

  if [ -f "$AUTOSTART_LUA" ]; then
    sed -i "/$SERVICE_NAME/d" "$AUTOSTART_LUA"
  fi

  echo -e "${GREEN}Removed:${NC} systemd $SERVICE_NAME.service + $SERVICE_NAME.timer"
}

_send_report() {
  local summary
  if [ "$FAIL" -gt 0 ]; then
    summary="COMPROMISED: $FAIL failures, $WARN warnings (of $((PASS+FAIL+WARN)) checks)"
    _notify critical "Infection Checker" "$summary"
  elif [ "$WARN" -gt 0 ]; then
    summary="Clean with warnings: $WARN warnings (of $((PASS+FAIL+WARN)) checks)"
    _notify normal "Infection Checker" "$summary"
  else
    summary="All $PASS checks passed - no indicators found"
    _notify low "Infection Checker" "$summary"
  fi
}

# --- Argument parsing ---
case "${1:-}" in
  --install)
    _install
    exit 0
    ;;
  --remove)
    _remove
    exit 0
    ;;
  --daemon)
    DAEMON=true
    mkdir -p "$HOME/.local/share"
    exec >> "$HOME/.local/share/$SCRIPT_NAME.log" 2>&1
    echo "=== $(date) ==="
    ;;
esac

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Atomic Arch Infection Checker${NC}"
echo -e "${CYAN}============================================${NC}"

# Auto-update from remote sources
echo -ne "${CYAN}[0/13]${NC} Fetching latest known-infected package list... "
fetch_remote_list
if $REMOTE_OK; then
  echo -e "${GREEN}OK${NC} (${#KNOWN_INFECTED[@]} packages loaded)"
else
  echo -e "${YELLOW}offline${NC} (${#KNOWN_INFECTED[@]} packages from local list)"
fi

# --- 1. Check installed AUR packages against known-infected list ---
echo -ne "${CYAN}[1/13]${NC} Checking installed AUR packages against known-infected list... "
PKG_NAMES=$(pacman -Qqm 2>/dev/null || true)
FOUND_INFECTED=""
for infected in "${KNOWN_INFECTED[@]}"; do
  while IFS= read -r pkg; do
    if [[ "$pkg" == "$infected" ]]; then
      FOUND_INFECTED+=" $pkg"
    fi
  done <<< "$PKG_NAMES"
done
if [ -n "$FOUND_INFECTED" ]; then
  echo -e "${RED}FAIL${NC}"
  fail "Installed known-infected package(s):$FOUND_INFECTED"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- 2. Check for malicious npm/bun packages in global installs and .INSTALL files ---
echo -ne "${CYAN}[2/13]${NC} Checking for malicious npm/bun packages... "
MALICIOUS_NPM_FOUND=false
DETAILS=""

# Known malicious npm packages used in AUR supply-chain attacks
MALICIOUS_NPM_PKGS=("atomic-lockfile" "ansi-colors" "nextfile-js")

# Check global npm packages
if command -v npm &>/dev/null; then
  for pkg in "${MALICIOUS_NPM_PKGS[@]}"; do
    if npm list -g "$pkg" 2>/dev/null | grep -q "$pkg"; then
      MALICIOUS_NPM_FOUND=true
      DETAILS+=" npm:${pkg}"
    fi
  done
fi

# Check global bun packages
if command -v bun &>/dev/null; then
  for pkg in "${MALICIOUS_NPM_PKGS[@]}"; do
    if bun pm ls 2>/dev/null | grep -q "$pkg"; then
      MALICIOUS_NPM_FOUND=true
      DETAILS+=" bun:${pkg}"
    fi
  done
fi

# Check .INSTALL files for known malicious packages
for pkg in "${MALICIOUS_NPM_PKGS[@]}"; do
  while IFS= read -r -d '' install_file; do
    if grep -q "$pkg" "$install_file" 2>/dev/null; then
      MALICIOUS_NPM_FOUND=true
      DETAILS+=" ${pkg}(.INSTALL)"
    fi
  done < <(find /var/lib/pacman/local -name 'install' -type f 2>/dev/null || true)
done

# Check for obfuscated hex/octal escapes ($'\xNN' or $'\NNN') in .INSTALL files
# used to hide package manager commands (as seen in htbrowser-bin and similar attacks)
while IFS= read -r -d '' install_file; do
  if grep -qP "\$'\\\\[x0]" "$install_file" 2>/dev/null; then
    MALICIOUS_NPM_FOUND=true
    DETAILS+=" obfuscated-script(.INSTALL)"
    break
  fi
done < <(find /var/lib/pacman/local -name 'install' -type f 2>/dev/null || true)

# Check for 'bun add' in .INSTALL files (new supply-chain delivery mechanism)
while IFS= read -r -d '' install_file; do
  if grep -q "bun add" "$install_file" 2>/dev/null; then
    MALICIOUS_NPM_FOUND=true
    DETAILS+=" bun-add(.INSTALL)"
    break
  fi
done < <(find /var/lib/pacman/local -name 'install' -type f 2>/dev/null || true)

if $MALICIOUS_NPM_FOUND; then
  echo -e "${RED}FAIL${NC}"
  fail "Malicious npm/bun indicator(s) found:$DETAILS"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- 3. Check eBPF artifacts ---
echo -ne "${CYAN}[3/13]${NC} Checking eBPF artifacts... "
BPF_ISSUES=false
if [ -d /sys/fs/bpf ]; then
  # Filter out entries owned by Chrome/Chromium renderer processes (seccomp-BPF sandbox)
  # Those are pinned under paths like /sys/fs/bpf/... and owned by chrome PIDs.
  BPF_ENTRIES=$(ls -A /sys/fs/bpf/ 2>/dev/null | grep -v '^$' || true)
  SUSPICIOUS_BPF=""
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    full_path="/sys/fs/bpf/$entry"
    owner_pid=$(stat -c '%u' "$full_path" 2>/dev/null || true)
    owner_cmd=""
    # Try to identify owning process by inode/fd scan only if we have a UID match
    # Simpler heuristic: skip entries whose name pattern matches Chrome sandbox tokens
    # (numeric-only names are used by Chrome's seccomp-BPF sandbox)
    if [[ "$entry" =~ ^[0-9]+$ ]]; then
      continue  # Chrome/Chromium seccomp sandbox pins numeric-named maps/progs
    fi
    SUSPICIOUS_BPF+=" $entry"
  done <<< "$BPF_ENTRIES"
  if [ -n "$SUSPICIOUS_BPF" ]; then
    warn "Non-empty /sys/fs/bpf/ (non-browser entries:$SUSPICIOUS_BPF)"
    BPF_ISSUES=true
  fi
fi
if command -v bpftool &>/dev/null; then
  RAW=$(bpftool prog list 2>/dev/null | grep -i "atomic\|hide\|hook\|scales" || true)
  if [ -n "$RAW" ]; then
    fail "Suspicious BPF program names: $RAW"
    BPF_ISSUES=true
  fi
fi
if ! $BPF_ISSUES; then
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- 4. Hidden processes check ---
echo -ne "${CYAN}[4/13]${NC} Checking for hidden processes... "
FP_COUNT=0
if [ -d /proc ]; then
  proc_pids=$(ls /proc/ | grep -E '^[0-9]+$')
  for pid in $proc_pids; do
    if [ ! -f "/proc/$pid/status" ]; then
      continue
    fi
    name=$(cat "/proc/$pid/comm" 2>/dev/null || true)
    if [ -z "$name" ]; then
      continue
    fi
    if ! ps -p "$pid" >/dev/null 2>&1; then
      FP_COUNT=$((FP_COUNT + 1))
    fi
  done
  if [ "$FP_COUNT" -gt 0 ]; then
    echo -e "${RED}FAIL${NC}"
    fail "$FP_COUNT process(es) in /proc but hidden from ps"
  else
    echo -e "${GREEN}PASS${NC}"
    pass
  fi
else
  echo -e "${YELLOW}SKIP${NC}"
  pass
fi

# --- 5. Suspicious systemd services ---
echo -ne "${CYAN}[5/13]${NC} Checking for suspicious systemd services... "
SUSPECT=""
if command -v systemctl &>/dev/null; then
  # Extract only the unit name (first field) to avoid matching service descriptions
  SUSPECT=$(systemctl list-units --type=service --state=running --no-legend --plain 2>/dev/null \
    | awk '{print $1}' \
    | grep -iE "\brat\b|systemd-initd" || true)
fi
if grep -rsl "atomic-lockfile" /etc/systemd/system /usr/lib/systemd/system 2>/dev/null | grep -q .; then
  SUSPECT+=" unit-file-ref"
fi
if [ -n "$SUSPECT" ]; then
  echo -e "${RED}FAIL${NC}"
  fail "Suspicious systemd artifacts found"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- 6. Network checks ---
echo -ne "${CYAN}[6/13]${NC} Checking for suspicious network connections... "
C2=""
if command -v ss &>/dev/null; then
  C2=$(ss -tnaup 2>/dev/null | grep -E ":(8080|4443|8443|1337|4444|4445|5555|6666|7777|9001|9050|31337)\s" | grep ESTAB || true)
fi
if [ -n "$C2" ]; then
  echo -e "${YELLOW}WARN${NC}"
  warn "Established connection(s) on suspicious ports (8080/4443/8443/1337/4444/4445/5555/6666/7777/9001/9050/31337)"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi
# Check for shell interpreters with ESTABLISHED TCP connections on suspicious ports only
SHELL_C2=""
if command -v ss &>/dev/null; then
  SHELL_C2=$(ss -tnaup 2>/dev/null \
    | grep ESTAB \
    | grep -E ":(8080|4443|8443|1337|4444|4445|5555|6666|7777|9001|9050|31337)\s" \
    | grep -F -e 'users:(("bash' -e 'users:(("sh"' -e 'users:(("dash' -e 'users:(("python' -e 'users:(("perl' || true)
fi
if [ -n "$SHELL_C2" ]; then
  echo -e "${RED}FAIL${NC}"
  fail "Shell interpreter(s) with established TCP connection on suspicious port: $SHELL_C2"
else
  pass
fi

# --- 7. Pacman log for infected packages ---
echo -ne "${CYAN}[7/13]${NC} Checking pacman log for known-infected packages... "
LOG_HITS=""
if [ -f /var/log/pacman.log ]; then
  # Extract package names that were ever installed/upgraded from the log
  LOGPKGS=$(grep -oP ']\s+(installed|upgraded)\s+\K\S+' /var/log/pacman.log 2>/dev/null || true)
  # Only care about packages currently installed (from AUR)
  INSTALLED_AUR=$(pacman -Qqm 2>/dev/null || true)
  for infected in "${KNOWN_INFECTED[@]}"; do
    # Must appear in the log AND still be installed now
    if grep -qxF "$infected" <<< "$LOGPKGS" && grep -qxF "$infected" <<< "$INSTALLED_AUR"; then
      LOG_HITS+=" $infected"
    fi
  done
fi
if [ -n "$LOG_HITS" ]; then
  echo -e "${RED}FAIL${NC}"
  fail "Known-infected packages in pacman log:$LOG_HITS"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- 8. /etc/ld.so.preload injection ---
echo -ne "${CYAN}[8/13]${NC} Checking /etc/ld.so.preload... "
if [ -f /etc/ld.so.preload ] && [ -s /etc/ld.so.preload ]; then
  echo -e "${RED}FAIL${NC}"
  fail "/etc/ld.so.preload exists and is non-empty ($(tr '\n' ' ' < /etc/ld.so.preload))"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- 9. Executables running from volatile paths ---
echo -ne "${CYAN}[9/13]${NC} Checking for executables in volatile paths... "
VOLATILE=""
if [ -d /proc ]; then
  for pid_dir in /proc/[0-9]*/; do
    pid=${pid_dir%/}
    pid=${pid##*/}
    exe=$(readlink "$pid_dir/exe" 2>/dev/null || true)
    [ -z "$exe" ] && continue
    # Skip anonymous memfd mappings (legitimate: Electron, JIT runtimes)
    [[ "$exe" == memfd:* ]] && continue
    if [[ "$exe" == *"(deleted)" ]]; then
      # Browsers and Electron apps legitimately show (deleted) exes when they are
      # updated on disk while running, or for helper/renderer subprocesses.
      # Identify the process by its comm name and skip known-safe binaries.
      comm=$(cat "$pid_dir/comm" 2>/dev/null || true)
      case "$comm" in
        chrome|google-chrome|chromium|chromium-browser|\
        electron|electron[0-9]*|\
        firefox|firefox-bin|\
        brave|brave-browser|\
        opera|opera-browser|\
        vivaldi|vivaldi-bin|\
        msedge|microsoft-edge|\
        nacl_helper|chrome_crashpad|chrome_sandbox|\
        PepperFlash|renderer|gpu-process|utility)
          continue  # Legitimate browser/Electron helper with replaced on-disk binary
          ;;
      esac
      VOLATILE+="\n $pid(deleted):$exe"
      continue
    fi
    case "$exe" in
      /tmp/*|/dev/shm/*|/var/tmp/*) VOLATILE+=" $pid:$exe" ;;
    esac
  done
fi
if [ -n "$VOLATILE" ]; then
  echo -e "${RED}FAIL${NC}"
  fail "Process(es) with suspicious executable path:$VOLATILE"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- 10. User-level persistence ---
echo -ne "${CYAN}[10/13]${NC} Checking user-level persistence... "
PERSIST=""
for dir in "$HOME/.config/systemd/user" "$HOME/.config/autostart" /etc/pacman.d/hooks; do
  [ -d "$dir" ] || continue
  hits=$(grep -rsl 'Exec=' "$dir" 2>/dev/null | xargs grep -l 'curl\|wget\|bash -c\|python -c\|base64 -d\|bun add' 2>/dev/null || true)
  if [ -n "$hits" ]; then
    PERSIST+=" $dir"
  fi
done
if [ -n "$PERSIST" ]; then
  echo -e "${RED}FAIL${NC}"
  fail "Suspicious persistence artifacts found in:$PERSIST"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- 11. Shell config injection ---
echo -ne "${CYAN}[11/13]${NC} Checking shell config injection... "
SHELL_BAD=""
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.config/fish/config.fish"; do
  [ -f "$rc" ] || continue
  if grep -qE '(curl\s+\S+\s*\||bash\s*<\(curl|eval\s*\$\(|base64\s+-d\s*\|)' "$rc" 2>/dev/null; then
    SHELL_BAD+=" $rc"
  fi
  if grep -q 'LD_PRELOAD=' "$rc" 2>/dev/null; then
    SHELL_BAD+=" $rc(LD_PRELOAD)"
  fi
  if grep -q 'bun add' "$rc" 2>/dev/null; then
    SHELL_BAD+=" $rc(bun-add)"
  fi
done
for rc in "$HOME/.config/fish/conf.d/"*.fish; do
  [ -f "$rc" ] || continue
  if grep -qE '(curl\s+\S+\s*\||bash\s*<\(curl|eval\s*\$\(|base64\s+-d\s*\|)' "$rc" 2>/dev/null; then
    SHELL_BAD+=" $rc"
  fi
done
if [ -n "$SHELL_BAD" ]; then
  echo -e "${RED}FAIL${NC}"
  fail "Shell config(s) with suspicious content:$SHELL_BAD"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- 12. npm/bun global hook scripts ---
echo -ne "${CYAN}[12/13]${NC} Checking npm/bun global hook scripts... "
NPM_BAD=""
if command -v npm &>/dev/null; then
  NPM_ROOT=$(npm root -g 2>/dev/null || true)
  if [ -n "$NPM_ROOT" ] && [ -d "$NPM_ROOT" ]; then
    for pkg_dir in "$NPM_ROOT"/*/; do
      [ -f "$pkg_dir/package.json" ] || continue
      scripts=$(python3 -c "
import json, sys
try:
  with open('${pkg_dir}package.json') as f:
    pkg = json.load(f)
  scripts = pkg.get('scripts', {})
  for hook in ['preinstall', 'install', 'postinstall']:
    s = scripts.get(hook, '')
    if any(kw in s for kw in ['curl ', 'wget ', 'eval ', 'exec(']):
      print(hook + ':' + s[:120])
except: pass
" 2>/dev/null)
      if [ -n "$scripts" ]; then
        pkg_name=$(basename "$pkg_dir")
        NPM_BAD+=" $pkg_name($scripts)"
      fi
    done
  fi
fi
# Check bun global packages
if command -v bun &>/dev/null; then
  BUN_GLOBAL_DIR="$HOME/.bun/install/global"
  if [ -d "$BUN_GLOBAL_DIR" ]; then
    for pkg_dir in "$BUN_GLOBAL_DIR"/node_modules/*/; do
      [ -f "$pkg_dir/package.json" ] || continue
      scripts=$(python3 -c "
import json, sys
try:
  with open('${pkg_dir}package.json') as f:
    pkg = json.load(f)
  scripts = pkg.get('scripts', {})
  for hook in ['preinstall', 'install', 'postinstall']:
    s = scripts.get(hook, '')
    if any(kw in s for kw in ['curl ', 'wget ', 'eval ', 'exec(']):
      print(hook + ':' + s[:120])
except: pass
" 2>/dev/null)
      if [ -n "$scripts" ]; then
        pkg_name=$(basename "$pkg_dir")
        NPM_BAD+=" $pkg_name(bun:$scripts)"
      fi
    done
  fi
fi
if [ -n "$NPM_BAD" ]; then
  echo -e "${RED}FAIL${NC}"
  fail "Suspicious npm/bun global hook scripts:$NPM_BAD"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- 13. SSH authorized_keys ---
echo -ne "${CYAN}[13/13]${NC} Checking SSH authorized_keys... "
SSH_BAD=""
for f in "$HOME/.ssh/authorized_keys" /root/.ssh/authorized_keys; do
  [ -f "$f" ] || continue
  count=$(wc -l < "$f")
  if [ "$count" -gt 0 ]; then
    SSH_BAD+=" $f($count keys)"
  fi
  if grep -q 'command=' "$f" 2>/dev/null; then
    SSH_BAD+=" $f(command=)"
  fi
done
if [ -n "$SSH_BAD" ]; then
  echo -e "${YELLOW}WARN${NC}"
  warn "SSH authorized_keys present:$SSH_BAD"
else
  echo -e "${GREEN}PASS${NC}"
  pass
fi

# --- Summary ---
echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Results: ${GREEN}$PASS passed${NC}, ${YELLOW}$WARN warnings${NC}, ${RED}$FAIL failures${NC}"
echo -e "${CYAN}============================================${NC}"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo -e "${RED}  Indicators of compromise found.${NC}"
  echo -e "${YELLOW}  If atomic-lockfile was installed, treat the system as fully compromised.${NC}"
  echo -e "${YELLOW}  The malware deploys an eBPF rootkit capable of hiding processes, files,"
  echo -e "${YELLOW}  and network connections from all userspace tools.${NC}"
  echo -e "${YELLOW}  Recommended: back up data, clean reinstall.${NC}"
  echo -e "${YELLOW}  Change all credentials (GitHub, SSH, Vault, browser sessions, Slack, Discord, etc.).${NC}"
fi

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  echo ""
  echo -e "${GREEN}  No indicators of compromise found.${NC}"
fi

if [ "$FAIL" -gt 0 ] || [ "$WARN" -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}  DISCLAIMER: This script is a best-effort scanning tool and may produce"
  echo -e "${YELLOW}  false positives or miss sophisticated threats. Any FAIL or WARN result"
  echo -e "${YELLOW}  should not be taken as definitive proof — always investigate manually"
  echo -e "${YELLOW}  and consult with a security professional before taking action.${NC}"
fi

$DAEMON && _send_report; true
