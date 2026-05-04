#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║         W A Y Y  T O O L B O X  — Installer             ║
# ║                      v5.0.0                             ║
# ╚══════════════════════════════════════════════════════════╝
#
# CARA INSTALL:
#   curl -sL https://raw.githubusercontent.com/Wayy1702/Rejoin-Wayy/main/install.sh | bash

REPO="https://raw.githubusercontent.com/Wayy1702/Rejoin-Wayy/refs/heads/main"
BIN="$PREFIX/bin/wayy"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; M='\033[0;35m'; D='\033[0;90m'; W='\033[1;37m'; N='\033[0m'

clear
echo ""
echo -e "${C}  ██╗    ██╗ █████╗ ██╗   ██╗██╗   ██╗${N}"
echo -e "${C}  ██║    ██║██╔══██╗╚██╗ ██╔╝╚██╗ ██╔╝${N}"
echo -e "${C}  ██║ █╗ ██║███████║ ╚████╔╝  ╚████╔╝ ${N}"
echo -e "${C}  ██║███╗██║██╔══██║  ╚██╔╝    ╚██╔╝  ${N}"
echo -e "${C}  ╚███╔███╔╝██║  ██║   ██║      ██║   ${N}"
echo -e "${C}   ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝      ╚═╝  ${N}"
echo -e "  ${M}         T O O L B O X  v5.0.0${N}"
echo -e "  ${M}──────────────────────────────────────${N}"
echo -e "  ${D}           Installer by Wayy${N}"
echo -e "  ${M}──────────────────────────────────────${N}"
echo ""

# ── Cek Termux ──────────────────────────────────────────────
if [[ -z "$PREFIX" || ! -d "/data/data/com.termux" ]]; then
    echo -e "${R}  [✗] Script ini hanya untuk Termux!${N}"
    exit 1
fi

# ════════════════════════════════════════════════════════════
#  STEP 0 — Setup Storage (wajib sebelum apapun)
# ════════════════════════════════════════════════════════════
echo -e "${C}  [0/4] Setup storage permission...${N}"
if [[ ! -d "$HOME/storage/downloads" && ! -d "$HOME/storage/shared" ]]; then
    termux-setup-storage
    echo -e "${D}  [i] Izinkan akses storage di popup, lalu tunggu...${N}"
    sleep 5
fi
if [[ -d "$HOME/storage/downloads" || -d "$HOME/storage/shared" ]]; then
    echo -e "${G}  [✓] Storage OK${N}"
else
    echo -e "${Y}  [!] Storage belum diizinkan — fitur cookies mungkin terbatas${N}"
fi

# ════════════════════════════════════════════════════════════
#  STEP 1 — Fix SSL / curl
# ════════════════════════════════════════════════════════════
echo -e "${C}  [1/4] Fix SSL & update package...${N}"

# Ganti mirror ke Cloudflare (paling stabil)
echo "deb https://packages-cf.termux.dev/apt/termux-main stable main" \
    > "$PREFIX/etc/apt/sources.list" 2>/dev/null
echo -e "${D}  [i] Mirror → Cloudflare${N}"

apt-get update -y -q 2>/dev/null || true
apt-get full-upgrade -y -q 2>/dev/null || true
apt-get install -y -q --fix-broken curl 2>/dev/null || true

if ! curl --version &>/dev/null; then
    echo -e "${R}  [✗] curl rusak. Jalankan manual: apt-get update && apt-get full-upgrade -y${N}"
    exit 1
fi
echo -e "${G}  [✓] curl OK${N}"

# ════════════════════════════════════════════════════════════
#  STEP 2 — Install semua dependencies rejoin
# ════════════════════════════════════════════════════════════
echo -e "${C}  [2/4] Install dependencies...${N}"
echo -e "${D}  [i] Ini mungkin butuh beberapa menit...${N}"
echo ""

# Semua package sekaligus — sama persis dengan yang dibutuhkan rejoin
pkg install -y \
    curl \
    wget \
    termux-tools \
    tsu \
    python \
    sqlite \
    openssl-tool \
    android-tools \
    binutils \
    xxd \
    2>/dev/null || true

# Fallback apt-get jika pkg gagal
apt-get install -y -q \
    curl wget tsu python sqlite3 openssl xxd \
    2>/dev/null || true

# Fallback per-package
_pkg_fallback() {
    local _pname="$1" _cmd="$2"
    if ! command -v "$_cmd" &>/dev/null; then
        echo -e "${Y}  [!] ${_pname} belum ada, retry...${N}"
        pkg install -y "$_pname" 2>/dev/null \
            || apt-get install -y -q "$_pname" 2>/dev/null \
            || true
    fi
}
_pkg_fallback "tsu"          "su"
_pkg_fallback "python"       "python3"
_pkg_fallback "sqlite"       "sqlite3"
_pkg_fallback "openssl-tool" "openssl"
_pkg_fallback "android-tools" "adb"
_pkg_fallback "xxd"          "xxd"

# pip packages (opsional — untuk tampilan rich)
echo -e "${D}  [i] Install pip packages...${N}"
pip install --quiet --break-system-packages pyfiglet rich 2>/dev/null \
    || pip install --quiet pyfiglet rich 2>/dev/null \
    || true

# ── Verifikasi ───────────────────────────────────────────────
echo ""
echo -e "  ${D}Verifikasi package:${N}"
_all_ok=true
for _dep_cmd in curl python3 sqlite3 openssl; do
    if command -v "$_dep_cmd" &>/dev/null; then
        echo -e "  ${G}[✓]${N} ${_dep_cmd}"
    else
        echo -e "  ${R}[✗]${N} ${_dep_cmd} ${D}— tidak ditemukan${N}"
        _all_ok=false
    fi
done
if command -v su &>/dev/null; then
    echo -e "  ${G}[✓]${N} su/root"
else
    echo -e "  ${Y}[!]${N} su/root ${D}— tidak ada, fitur cookies & rejoin butuh root${N}"
fi

echo ""
if [[ "$_all_ok" == "true" ]]; then
    echo -e "${G}  [✓] Semua dependency wajib OK${N}"
else
    echo -e "${Y}  [!] Ada dependency kurang. Install manual:${N}"
    echo -e "${Y}      pkg install python sqlite openssl-tool tsu android-tools -y${N}"
fi

# ════════════════════════════════════════════════════════════
#  STEP 3 — Buat folder WayyCookies di sdcard
# ════════════════════════════════════════════════════════════
echo -e "${C}  [3/4] Buat folder WayyCookies...${N}"
_cookies_created=false
for _dl_try in "/storage/emulated/0/Download" "/sdcard/Download" "$HOME/storage/downloads"; do
    if [[ -d "$_dl_try" && -w "$_dl_try" ]]; then
        mkdir -p "${_dl_try}/WayyCookies" 2>/dev/null
        echo -e "${G}  [✓] Folder: ${_dl_try}/WayyCookies${N}"
        _cookies_created=true
        break
    fi
done
if [[ "$_cookies_created" == "false" ]]; then
    echo -e "${Y}  [!] Gagal buat folder — storage belum siap${N}"
fi

# ════════════════════════════════════════════════════════════
#  STEP 4 — Download wayy launcher
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${C}  [4/4] Download launcher 'wayy'...${N}"

_dl() {
    local _url="$1" _out="$2" _label="$3"
    local _tmp; _tmp=$(mktemp)
    for _t in 1 2 3; do
        echo -e "${D}  [~] Download ${_label}... (${_t}/3)${N}"
        if curl -fsSL --max-time 30 --retry 2 --retry-delay 3 \
            --connect-timeout 10 "$_url" -o "$_tmp" 2>/dev/null \
            && [[ -s "$_tmp" ]]; then
            mv "$_tmp" "$_out"
            chmod +x "$_out"
            echo -e "${G}  [✓] ${_label} OK${N}"
            return 0
        fi
        echo -e "${Y}  [!] Percobaan ${_t} gagal...${N}"
        [[ $_t -lt 3 ]] && sleep 3
    done
    rm -f "$_tmp" 2>/dev/null
    echo -e "${R}  [✗] Gagal download ${_label}!${N}"
    return 1
}

# Hapus launcher lama jika ada
rm -f "$PREFIX/bin/rejoin" 2>/dev/null

_dl "$REPO/wayy.sh" "$BIN" "wayy launcher" || exit 1

# ════════════════════════════════════════════════════════════
#  SELESAI
# ════════════════════════════════════════════════════════════
echo ""
echo -e "  ${M}──────────────────────────────────────${N}"
echo -e "  ${G}[✓] Instalasi selesai!${N}"
echo ""
echo -e "  Ketik ${Y}wayy${N} untuk membuka rejoin"
echo -e "  ${D}Kamu akan diminta memasukkan license key${N}"
echo -e "  ${D}saat pertama kali menjalankan.${N}"
echo ""
echo -e "  ${D}Cookies backup disimpan di:${N}"
echo -e "  ${W}  /sdcard/Download/WayyCookies/${N}"
echo -e "  ${D}(kompatibel dengan file JSON dari Kaeru)${N}"
echo ""
echo -e "  ${C}Butuh key? Hubungi admin.${N}"
echo -e "  ${M}──────────────────────────────────────${N}"
echo ""
