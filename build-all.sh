#!/bin/bash
#
# Build semua variant LineageOS GSI.
#
# Cara pakai (dari root source Android):
#   bash LineageOS_gsi/build-all.sh
#   bash LineageOS_gsi/build-all.sh bvNE bgNE
#   bash LineageOS_gsi/build-all.sh vanilla-erofs gapps-ext4
#   bash LineageOS_gsi/build-all.sh --list
#   bash LineageOS_gsi/build-all.sh --dry-run bgNE
#
# Memakai cache build yang sudah ada (incremental, tanpa make clean)
# dan ccache. Tiap variant yang sukses langsung di-zip agar tidak
# tertimpa variant berikutnya (semua variant memakai
# out/target/product/generic_arm64/system.img yang sama).

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# variant -> lunch target (urutan default build)
DEFAULT_VARIANTS=(bvNE bvN4 bgNE bgN4)

lunch_for() {
    case "$1" in
        bvNE) echo "lineage_arm64_bvNE-bp4a-userdebug" ;;
        bvN4) echo "lineage_arm64_bvN4-bp4a-userdebug" ;;
        bgNE) echo "lineage_arm64_bgNE-bp4a-userdebug" ;;
        bgN4) echo "lineage_arm64_bgN4-bp4a-userdebug" ;;
    esac
}

desc_for() {
    case "$1" in
        bvNE) echo "VANILLA erofs" ;;
        bvN4) echo "VANILLA ext4" ;;
        bgNE) echo "GAPPS erofs" ;;
        bgN4) echo "GAPPS ext4" ;;
    esac
}

usage() {
    cat <<'EOF'
Usage: bash LineageOS_gsi/build-all.sh [OPTIONS] [VARIANT...]

Build GSI per variant (incremental, pakai cache yang sudah ada).
Tanpa argumen variant = build semua (bvNE bvN4 bgNE bgN4).

VARIANT (case-insensitive, boleh campur):
  bvNE | vanilla-erofs | lineage_arm64_bvNE-bp4a-userdebug   (VANILLA erofs)
  bvN4 | vanilla-ext4  | lineage_arm64_bvN4-bp4a-userdebug   (VANILLA ext4)
  bgNE | gapps-erofs   | lineage_arm64_bgNE-bp4a-userdebug   (GAPPS erofs)
  bgN4 | gapps-ext4    | lineage_arm64_bgN4-bp4a-userdebug   (GAPPS ext4)
  all                                                           (semua variant)

OPTIONS:
  -h, --help        tampilkan bantuan ini
  --list            tampilkan daftar variant lalu keluar
  --dry-run         cetak perintah build tanpa mengeksekusi
  -j N, --jobs N    jumlah job make (default: nproc --all)
  --src DIR         root source Android berisi build/envsetup.sh
                    (default: auto-detect: $PWD, lalu dir script/..)
  --out-dir DIR     direktori hasil zip
                    (default: ~/public bila ada/bisa dibuat,
                     fallback: <src>/out/gsi-zips)
  --no-ccache       jangan setup ccache otomatis
  --stop-on-fail    berhenti pada variant pertama yang gagal
                    (default: lanjut ke variant berikut)

Contoh:
  bash LineageOS_gsi/build-all.sh
  bash LineageOS_gsi/build-all.sh bvNE bgNE
  bash LineageOS_gsi/build-all.sh --jobs 8 bvN4
  bash LineageOS_gsi/build-all.sh --out-dir ~/gsi --dry-run

Env yang dihormati: ANDROID_ROOT (sama dgn --src),
  OUT_ZIP_DIR (sama dgn --out-dir), JOBS (sama dgn --jobs).
EOF
}

list_variants() {
    printf '%-6s %-38s %s\n' "SHORT" "LUNCH" "DESC"
    for v in "${DEFAULT_VARIANTS[@]}"; do
        printf '%-6s %-38s %s\n' "$v" "$(lunch_for "$v")" "$(desc_for "$v")"
    done
}

# Normalisasi input user -> short name (bvNE/bvN4/bgNE/bgN4). Return 1 bila tak dikenal.
normalize_variant() {
    case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
        bvne|vanilla-erofs|vanilla_erofs|vanillaerofs|lineage_arm64_bvne-bp4a-userdebug|lineage_arm64_bvne) echo "bvNE" ;;
        bvn4|vanilla-ext4|vanilla_ext4|vanillaext4|lineage_arm64_bvn4-bp4a-userdebug|lineage_arm64_bvn4) echo "bvN4" ;;
        bgne|gapps-erofs|gapps_erofs|gappserofs|lineage_arm64_bgne-bp4a-userdebug|lineage_arm64_bgne) echo "bgNE" ;;
        bgn4|gapps-ext4|gapps_ext4|gappsext4|lineage_arm64_bgn4-bp4a-userdebug|lineage_arm64_bgn4) echo "bgN4" ;;
        *) return 1 ;;
    esac
}

# ---------- parse args ----------
JOBS="${JOBS:-$(nproc --all 2>/dev/null || echo 4)}"
ANDROID_ROOT="${ANDROID_ROOT:-}"
OUT_ZIP_DIR="${OUT_ZIP_DIR:-}"
USE_CCACHE_SETUP=1
STOP_ON_FAIL=0
DRY_RUN=0
declare -a WANT=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --list) list_variants; exit 0 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --no-ccache) USE_CCACHE_SETUP=0; shift ;;
        --stop-on-fail) STOP_ON_FAIL=1; shift ;;
        -j|--jobs)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 butuh nilai" >&2; exit 2; }
            JOBS="$2"; shift 2 ;;
        --jobs=*) JOBS="${1#--jobs=}"; shift ;;
        --src)
            [[ $# -lt 2 ]] && { echo "ERROR: --src butuh DIR" >&2; exit 2; }
            ANDROID_ROOT="$2"; shift 2 ;;
        --src=*) ANDROID_ROOT="${1#--src=}"; shift ;;
        --out-dir)
            [[ $# -lt 2 ]] && { echo "ERROR: --out-dir butuh DIR" >&2; exit 2; }
            OUT_ZIP_DIR="$2"; shift 2 ;;
        --out-dir=*) OUT_ZIP_DIR="${1#--out-dir=}"; shift ;;
        all) WANT+=(bvNE bvN4 bgNE bgN4); shift ;;
        -*) echo "ERROR: opsi tak dikenal: $1 (lihat --help)" >&2; exit 2 ;;
        *)
            if v="$(normalize_variant "$1")"; then
                WANT+=("$v")
            else
                echo "ERROR: variant tak dikenal: $1 (lihat --list)" >&2
                exit 2
            fi
            shift ;;
    esac
done

# default: semua variant
if [[ ${#WANT[@]} -eq 0 ]]; then
    WANT=(bvNE bvN4 bgNE bgN4)
fi
# dedup tapi jaga urutan
declare -a VARIANTS=()
for v in "${WANT[@]}"; do
    skip=0
    for seen in "${VARIANTS[@]+"${VARIANTS[@]}"}"; do
        [[ "$seen" == "$v" ]] && { skip=1; break; }
    done
    [[ $skip -eq 0 ]] && VARIANTS+=("$v")
done

# ---------- detect source root ----------
if [[ -z "$ANDROID_ROOT" ]]; then
    if [[ -f "$PWD/build/envsetup.sh" ]]; then
        ANDROID_ROOT="$PWD"
    elif [[ -f "$SCRIPT_DIR/../build/envsetup.sh" ]]; then
        ANDROID_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    elif [[ -f "$SCRIPT_DIR/build/envsetup.sh" ]]; then
        ANDROID_ROOT="$SCRIPT_DIR"
    else
        echo "ERROR: build/envsetup.sh tidak ditemukan." >&2
        echo "Jalankan dari root source Android:  bash LineageOS_gsi/build-all.sh" >&2
        echo "atau: bash LineageOS_gsi/build-all.sh --src /path/ke/source" >&2
        exit 2
    fi
fi
if [[ ! -f "$ANDROID_ROOT/build/envsetup.sh" ]]; then
    echo "ERROR: $ANDROID_ROOT/build/envsetup.sh tidak ada (--src salah?)" >&2
    exit 2
fi

# ---------- out dir ----------
if [[ -z "$OUT_ZIP_DIR" ]]; then
    if [[ -d "$HOME/public" ]] || mkdir -p "$HOME/public" 2>/dev/null; then
        OUT_ZIP_DIR="$HOME/public"
    else
        OUT_ZIP_DIR="$ANDROID_ROOT/out/gsi-zips"
    fi
fi

log()  { printf '[build-all] %s\n' "$*"; }
run()  { if [[ $DRY_RUN -eq 1 ]]; then printf '+ %s\n' "$*"; else log "$*"; "$@"; fi; }

log "Source   : $ANDROID_ROOT"
log "Variant  : ${VARIANTS[*]}"
log "Jobs     : $JOBS"
log "Out dir  : $OUT_ZIP_DIR"
[[ $DRY_RUN -eq 1 ]] && log "Mode     : DRY-RUN (tidak ada yang dieksekusi)"

if [[ $DRY_RUN -eq 0 ]]; then
    mkdir -p "$OUT_ZIP_DIR"
fi

# ---------- ccache (reuse cache) ----------
if [[ $USE_CCACHE_SETUP -eq 1 ]]; then
    export USE_CCACHE=1
    export CCACHE_COMPRESS=1
    export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-50G}"
    if command -v ccache >/dev/null 2>&1; then
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "+ ccache -M 50G -F 0"
        else
            ccache -M 50G -F 0 || log "peringatan: 'ccache -M' gagal, lanjutkan"
        fi
    else
        log "peringatan: ccache tidak ditemukan, lanjut tanpa ccache"
    fi
fi

cd "$ANDROID_ROOT"

# envsetup harus di-source di shell ini (menyediakan breakfast & get_build_var)
if [[ $DRY_RUN -eq 1 ]]; then
    echo "+ . build/envsetup.sh"
else
    # shellcheck disable=SC1091
    . build/envsetup.sh
fi

declare -a OK=()
declare -a FAILED=()

build_one() {
    local short="$1"
    local lunch; lunch="$(lunch_for "$short")"
    local desc; desc="$(desc_for "$short")"
    local img="out/target/product/generic_arm64/system.img"

    log "===== $short ($desc) : $lunch ====="

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "+ breakfast $lunch"
        echo "+ make systemimage -j$JOBS"
        echo "+ LINEAGE_VERSION=\$(get_build_var LINEAGE_VERSION)"
        echo "+ zip -j $OUT_ZIP_DIR/lineage_\${LINEAGE_VERSION}_${short}_arm64_userdebug.zip $img"
        return 0
    fi

    local build_log="$OUT_ZIP_DIR/build-${short}.log"
    {
        echo "### build-all $short ($desc) $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        echo "### lunch: $lunch | jobs: $JOBS | src: $ANDROID_ROOT"
        set -x
        # NOTE: sengaja tanpa make clean -> incremental, pakai cache yang ada.
        breakfast "$lunch" && make systemimage -j"$JOBS"
    } 2>&1 | tee "$build_log"
    local st="${PIPESTATUS[0]}"
    { set +x; } 2>/dev/null

    if [[ $st -ne 0 ]]; then
        log "GAGAL: $short (lihat $build_log)"
        FAILED+=("$short")
        return 1
    fi
    if [[ ! -f "$img" ]]; then
        log "GAGAL: $short: $img tidak ditemukan setelah build"
        FAILED+=("$short")
        return 1
    fi

    local ver; ver="$(get_build_var LINEAGE_VERSION 2>/dev/null || echo unknown)"
    local zip="$OUT_ZIP_DIR/lineage_${ver}_${short}_arm64_userdebug.zip"
    log "Packaging: $img -> $zip"
    if zip -j "$zip" "$img"; then
        log "OK: $short -> $zip"
        OK+=("$short:$zip")
        return 0
    else
        log "GAGAL zip: $short"
        FAILED+=("$short")
        return 1
    fi
}

for v in "${VARIANTS[@]}"; do
    if ! build_one "$v"; then
        if [[ $STOP_ON_FAIL -eq 1 ]]; then
            log "Berhenti (--stop-on-fail) setelah $v gagal"
            break
        fi
        log "Lanjut ke variant berikutnya..."
    fi
done

echo
log "===== RINGKASAN ====="
if [[ ${#OK[@]} -gt 0 ]]; then
    log "Sukses (${#OK[@]}):"
    for s in "${OK[@]}"; do log "  - $s"; done
fi
if [[ ${#FAILED[@]} -gt 0 ]]; then
    log "Gagal (${#FAILED[@]}): ${FAILED[*]}"
    exit 1
fi
if [[ $DRY_RUN -eq 1 ]]; then
    log "Dry-run selesai (tidak ada build dieksekusi)."
else
    log "Semua variant sukses."
fi
