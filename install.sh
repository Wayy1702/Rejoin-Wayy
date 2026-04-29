#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║         W A Y Y  T O O L B O X  — Installer             ║
# ║                      v5.0.0                             ║
# ╚══════════════════════════════════════════════════════════╝
#
# CARA INSTALL:
#   curl -sL https://raw.githubusercontent.com/Wayy1702/mytoolbox/main/install.sh | bash

REPO="https://raw.githubusercontent.com/Wayy1702/Rejoin-Wayy/refs/heads/main"
BIN="$PREFIX/bin/wayy"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; M='\033[0;35m'; D='\033[0;90m'; N='\033[0m'

clear
echo ""
echo -e "${M}  ╔══════════════════════════════════════╗${N}"
echo -e "${M}  ║        W A Y Y  T O O L B O X        ║${N}"
echo -e "${M}  ║                by Wayy               ║${N}"
echo -e "${M}  ╚══════════════════════════════════════╝${N}"
echo ""

# ── Cek Termux ──────────────────────────────────────────────
if [[ -z "$PREFIX" || ! -d "/data/data/com.termux" ]]; then
    echo -e "${R}  [✗] Script ini hanya untuk Termux!${N}"
    exit 1
fi

# ── Fix SSL / curl rusak — WAJIB dilakukan pertama ───────────
echo -e "${C}  [0/3] Fix SSL & curl...${N}"

# Ganti mirror ke Cloudflare (paling stabil)
if command -v termux-change-repo &>/dev/null; then
    # Non-interaktif: tulis langsung ke sources.list
    echo "deb https://packages-cf.termux.dev/apt/termux-main stable main" \
        > "$PREFIX/etc/apt/sources.list"
    echo -e "${G}  [✓] Mirror diganti ke Cloudflare${N}"
fi

# Update + full-upgrade untuk memperbaiki libcurl / libngtcp2
apt-get update -y -q 2>/dev/null || true
apt-get full-upgrade -y -q 2>/dev/null || true

# Pastikan curl & libcurl versi terbaru
apt-get install -y -q --fix-broken curl libcurl openssl 2>/dev/null || true

# Verifikasi curl bisa jalan
if ! curl --version &>/dev/null; then
    echo -e "${R}  [✗] curl masih rusak setelah fix. Coba jalankan secara manual:${N}"
    echo -e "${Y}      apt-get update && apt-get full-upgrade -y${N}"
    exit 1
fi
echo -e "${G}  [✓] curl OK${N}"

# ── Fungsi download dengan retry ─────────────────────────────
_dl() {
    local _url="$1" _out="$2" _label="$3"
    local _tmp; _tmp=$(mktemp)
    for _t in 1 2 3; do
        echo -e "${C}  [~] Download ${_label}... (${_t}/3)${N}"
        if curl -fsSL --max-time 20 --retry 3 --retry-delay 3 \
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

# ── Setup Storage ────────────────────────────────────────────
if [[ ! -d "$HOME/storage" ]]; then
    echo -e "${C}  [~] Setup storage...${N}"
    termux-setup-storage 2>/dev/null || true
    sleep 1
fi

# ── Install Dependencies ─────────────────────────────────────
echo -e "${C}  [1/3] Install dependencies...${N}"
pkg install -y -q curl wget termux-tools 2>/dev/null

# ── Install Package Tambahan ──────────────────────────────────
echo -e "${C}  [+]   Install package tambahan...${N}"
pkg install -y -q sqlite binutils python openssl-tool xxd 2>/dev/null

# Fallback: coba apt-get jika pkg gagal
for _pkg in sqlite3 openssl xxd; do
    if ! command -v "$_pkg" &>/dev/null; then
        echo -e "${Y}  [!] $_pkg belum ada, coba install via apt-get...${N}"
        apt-get install -y -q "$_pkg" 2>/dev/null || true
    fi
done

_missing=0
for _cmd in curl sqlite3 python3 openssl xxd; do
    if ! command -v "$_cmd" &>/dev/null; then
        echo -e "${Y}  [!] $_cmd belum tersedia${N}"
        _missing=1
    fi
done
if [[ $_missing -eq 0 ]]; then
    echo -e "${G}  [✓] Semua package OK${N}"
else
    echo -e "${Y}  [!] Beberapa package perlu install manual:${N}"
    echo -e "${Y}      pkg install sqlite binutils python openssl-tool xxd -y${N}"
fi

# ── Hapus launcher lama jika ada ─────────────────────────────
rm -f "$PREFIX/bin/toolbox" 2>/dev/null

# ── Download wayy launcher dari public repo ──────────────────
echo ""
echo -e "${C}  [2/3] Download launcher 'wayy'...${N}"
_dl "$REPO/wayy.sh" "$BIN" "wayy launcher" || exit 1

# ── Selesai ──────────────────────────────────────════════════
echo ""
echo -e "${M}  ══════════════════════════════════════${N}"
echo -e "${G}  [✓] Instalasi selesai!${N}"
echo ""
echo -e "  Ketik ${Y}wayy${N} untuk membuka toolbox"
echo -e "  ${D}Kamu akan diminta memasukkan license key${N}"
echo -e "  ${D}saat pertama kali menjalankan.${N}"
echo ""
echo -e "  ${C}Butuh key? Hubungi admin.${N}"
echo -e "${M}  ══════════════════════════════════════${N}"
echo ""
