#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║         W A Y Y  T O O L B O X  — Installer             ║
# ║                      v5.0.0                             ║
# ╚══════════════════════════════════════════════════════════╝
#
# CARA INSTALL:
#   curl -sL https://raw.githubusercontent.com/Wayy1702/mytoolbox/main/install.sh | bash

REPO="https://raw.githubusercontent.com/Wayy1702/mytoolbox/refs/heads/main"
BIN="$PREFIX/bin/wayy"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; M='\033[0;35m'; D='\033[0;90d'; N='\033[0m'

clear
echo ""
echo -e "${M}  ╔══════════════════════════════════════╗${N}"
echo -e "${M}  ║   W A Y Y  T O O L B O X  v5.0.0    ║${N}"
echo -e "${M}  ║           by Wayy1702                ║${N}"
echo -e "${M}  ╚══════════════════════════════════════╝${N}"
echo ""

# ── Cek Termux ──────────────────────────────────────────────
if [[ -z "$PREFIX" || ! -d "/data/data/com.termux" ]]; then
    echo -e "${R}  [✗] Script ini hanya untuk Termux!${N}"
    exit 1
fi

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
pkg update -y -q 2>/dev/null
pkg install -y -q curl wget termux-tools 2>/dev/null

# ── Install Package Tambahan ──────────────────────────────────
echo -e "${C}  [+]   Install package tambahan...${N}"
# openssl-tool diperlukan untuk dekripsi AES di sisi klien
pkg install -y -q sqlite binutils python openssl-tool xxd 2>/dev/null

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
    echo -e "${Y}  [!] Beberapa package mungkin perlu install manual:${N}"
    echo -e "${Y}      pkg install sqlite binutils python openssl-tool xxd -y${N}"
fi

# ── Hapus launcher lama jika ada ─────────────────────────────
rm -f "$PREFIX/bin/toolbox" 2>/dev/null

# ── Download wayy launcher dari public repo ──────────────────
# mytoolbox.sh TIDAK di-download di sini — akan di-fetch dari
# Cloudflare Worker (terenkripsi) setiap kali 'wayy' dijalankan.
echo ""
echo -e "${C}  [2/3] Download launcher 'wayy'...${N}"
_dl "$REPO/wayy.sh" "$BIN" "wayy launcher" || exit 1

# ── Selesai ──────────────────────────────────────────────────
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
