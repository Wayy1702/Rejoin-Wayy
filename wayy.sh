#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║         W A Y Y  T O O L B O X  — Launcher              ║
# ║   File ini di-download dari GitHub setiap install        ║
# ║   Jangan edit manual — akan ditimpa saat update          ║
# ╚══════════════════════════════════════════════════════════╝

# ── Ganti dengan URL Cloudflare Worker kamu ──────────────────
WORKER_URL="https://wayykeys.cloudwayy69.workers.dev"

SELF_BIN="$PREFIX/bin/wayy"
SELF_URL="https://raw.githubusercontent.com/Wayy1702/Rejoin-Wayy/refs/heads/main/wayy.sh"
KEY_FILE="$HOME/.wayy_key"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; M='\033[0;35m'; D='\033[0;90m'; N='\033[0m'

# ════════════════════════════════════════════════════════════
#  Helper
# ════════════════════════════════════════════════════════════

# Konversi hex string → binary (tanpa xxd agar portable)
_hex2bin() {
    # Gunakan python3 sebagai decoder (sudah pasti ada karena di-install oleh install.sh)
    python3 -c "import sys,binascii; sys.stdout.buffer.write(binascii.unhexlify(sys.stdin.read().strip()))"
}

# Decode AES-256-CBC menggunakan openssl
# Usage: _aes_decrypt <hex_key> <hex_iv> <hex_ciphertext>
_aes_decrypt() {
    local _key="$1" _iv="$2" _cipher="$3"
    echo "$_cipher" | _hex2bin | \
        openssl enc -aes-256-cbc -d -K "$_key" -iv "$_iv" -nosalt 2>/dev/null
}

# XOR dua hex string (sama panjang) menggunakan python3
_xor_hex() {
    python3 -c "
a = bytes.fromhex('$1')
b = bytes.fromhex('$2')
print(bytes(x^y for x,y in zip(a,b)).hex())
"
}

# Buat HMAC-SHA256 dari secret + data, return hex
# Usage: _hmac_hex <secret_str_padded32> <data_str>
_hmac_hex() {
    python3 -c "
import hmac, hashlib
secret = '$1'.encode()[:32].ljust(32, b' ')
data   = '$2'.encode()
h = hmac.new(secret, data, hashlib.sha256).digest()
print(h[:32].hex())
"
}

# ════════════════════════════════════════════════════════════
#  Cek dependency
# ════════════════════════════════════════════════════════════
for _dep in curl python3 openssl; do
    if ! command -v "$_dep" &>/dev/null; then
        echo -e "${R}  [✗] Dependency tidak ditemukan: $_dep${N}"
        echo -e "${Y}      Jalankan: pkg install openssl-tool python -y${N}"
        exit 1
    fi
done

# ════════════════════════════════════════════════════════════
#  1. Self-update launcher
# ════════════════════════════════════════════════════════════
echo -e "${C}  [~] Cek update launcher...${N}"
_new_launcher=$(mktemp)
if curl -fsSL --max-time 20 --connect-timeout 10 \
    "$SELF_URL" -o "$_new_launcher" 2>/dev/null \
    && [[ -s "$_new_launcher" ]]; then
    if ! diff -q "$SELF_BIN" "$_new_launcher" &>/dev/null; then
        mv "$_new_launcher" "$SELF_BIN"
        chmod +x "$SELF_BIN"
        echo -e "${G}  [✓] Launcher diperbarui — reload...${N}"
        exec bash "$SELF_BIN" "$@"
    else
        echo -e "${D}  [=] Launcher sudah terbaru.${N}"
        rm -f "$_new_launcher" 2>/dev/null
    fi
else
    echo -e "${Y}  [!] Gagal cek launcher, lanjut dengan versi lokal.${N}"
    rm -f "$_new_launcher" 2>/dev/null
fi

# ════════════════════════════════════════════════════════════
#  2. Baca / minta license key
# ════════════════════════════════════════════════════════════

# Generate HWID dari Android ID (unik per device)
_get_hwid() {
    local _id
    _id=$(settings get secure android_id 2>/dev/null | tr -dc 'a-f0-9')
    if [[ -z "$_id" || "$_id" == "null" ]]; then
        # Fallback: hash dari kombinasi info device
        _id=$(cat /proc/cpuinfo 2>/dev/null | sha256sum | cut -c1-16)
    fi
    echo "$_id"
}

HWID=$(_get_hwid)

# Baca key dari file jika sudah pernah disimpan
if [[ -f "$KEY_FILE" ]]; then
    LICENSE_KEY=$(cat "$KEY_FILE" | tr -d '[:space:]')
fi

# Jika belum ada atau flag --rekey
if [[ -z "$LICENSE_KEY" || "$1" == "--rekey" ]]; then
    echo ""
    echo -e "${M}  ╔══════════════════════════════════════╗${N}"
    echo -e "${M}  ║        AKTIVASI LICENSE KEY          ║${N}"
    echo -e "${M}  ╚══════════════════════════════════════╝${N}"
    echo ""
    echo -e "  HWID Device kamu: ${Y}${HWID}${N}"
    echo ""
    echo -ne "  Masukkan license key (WAYY-XXXX-XXXX-XXXX): "
    read -r LICENSE_KEY
    LICENSE_KEY=$(echo "$LICENSE_KEY" | tr '[:lower:]' '[:upper:]' | tr -d ' ')
fi

if [[ -z "$LICENSE_KEY" ]]; then
    echo -e "${R}  [✗] License key tidak boleh kosong!${N}"
    exit 1
fi

# ════════════════════════════════════════════════════════════
#  3. Request rejoin terenkripsi dari Worker
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${C}  [~] Memverifikasi key & mengunduh rejoin...${N}"

_resp=$(curl -fsSL --max-time 30 --connect-timeout 10 \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"key\":\"${LICENSE_KEY}\",\"hwid\":\"${HWID}\"}" \
    "${WORKER_URL}/get-rejoin" 2>/dev/null)

if [[ -z "$_resp" ]]; then
    echo -e "${R}  [✗] Tidak bisa terhubung ke server. Cek koneksi!${N}"
    exit 1
fi

# Parse status dari JSON
_status=$(echo "$_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null)

case "$_status" in
    "not_found")
        echo -e "${R}  [✗] License key tidak ditemukan!${N}"
        rm -f "$KEY_FILE" 2>/dev/null
        exit 1
        ;;
    "banned")
        echo -e "${R}  [✗] License key kamu telah di-ban!${N}"
        echo -e "${R}      Hubungi admin untuk info lebih lanjut.${N}"
        rm -f "$KEY_FILE" 2>/dev/null
        exit 1
        ;;
    "hwid_mismatch")
        _dev=$(echo "$_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('device','Unknown'))" 2>/dev/null)
        echo -e "${R}  [✗] Key sudah terikat ke device lain: ${_dev}${N}"
        echo -e "${Y}      Hubungi admin untuk reset HWID.${N}"
        rm -f "$KEY_FILE" 2>/dev/null
        exit 1
        ;;
    "error")
        _msg=$(echo "$_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('msg',''))" 2>/dev/null)
        echo -e "${R}  [✗] Error dari server: ${_msg}${N}"
        exit 1
        ;;
    "ok")
        echo -e "${G}  [✓] Key valid!${N}"
        ;;
    *)
        echo -e "${R}  [✗] Respons tidak dikenal dari server.${N}"
        exit 1
        ;;
esac

# ════════════════════════════════════════════════════════════
#  4. Decrypt payload AES-256-CBC
# ════════════════════════════════════════════════════════════

# Ambil field dari JSON
_iv=$(echo "$_resp"         | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('iv',''))" 2>/dev/null)
_masked_key=$(echo "$_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_key',''))" 2>/dev/null)
_payload=$(echo "$_resp"    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('payload',''))" 2>/dev/null)

if [[ -z "$_iv" || -z "$_masked_key" || -z "$_payload" ]]; then
    echo -e "${R}  [✗] Payload tidak lengkap dari server!${N}"
    exit 1
fi

# !! PENTING: ENCRYPT_SECRET harus sama persis dengan env var di Worker
# Hardcode di sini karena ini sisi klien (tersembunyi di binary / obfuscated)
# Ganti nilai ini sesuai env var ENCRYPT_SECRET di Worker kamu
_ENCRYPT_SECRET="WayyEncrypt2025SecretKey12345678"

# Rekonstruksi mask: HMAC(secret, hwid:key)
echo -e "${C}  [~] Mendekripsi rejoin...${N}"
_mask=$(_hmac_hex "$_ENCRYPT_SECRET" "${HWID}:${LICENSE_KEY}")

# Un-XOR masked key untuk dapatkan AES session key asli
_session_key=$(_xor_hex "$_masked_key" "$_mask")

# Decrypt script
_decrypted=$(_aes_decrypt "$_session_key" "$_iv" "$_payload")

if [[ -z "$_decrypted" ]]; then
    echo -e "${R}  [✗] Gagal mendekripsi rejoin! Key atau payload rusak.${N}"
    exit 1
fi

echo -e "${G}  [✓] Rejoin siap!${N}"

# ════════════════════════════════════════════════════════════
#  5. Simpan key & exec rejoin langsung dari memori
# ════════════════════════════════════════════════════════════

# Simpan key ke file untuk sesi berikutnya
echo "$LICENSE_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

echo ""
# Jalankan rejoin langsung dari variabel (tidak ditulis ke disk)
exec bash <(echo "$_decrypted") "$@"
