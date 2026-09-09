#!/bin/bash
# Build semua variant, persis dari perintah yang diberikan.
# Jalankan dari root source Android:
#   bash LineageOS_gsi/build-all.sh
mkdir -p ~/public
. build/envsetup.sh && breakfast lineage_arm64_bvNE-bp4a-userdebug && make systemimage -j$(nproc --all) && LINEAGE_VERSION=$(get_build_var LINEAGE_VERSION) && ZIP_NAME="lineage_${LINEAGE_VERSION}_arm64_userdebug.zip" && zip -j ~/public/${ZIP_NAME} out/target/product/generic_arm64/system.img
. build/envsetup.sh && breakfast lineage_arm64_bvN4-bp4a-userdebug && make systemimage -j$(nproc --all) && LINEAGE_VERSION=$(get_build_var LINEAGE_VERSION) && ZIP_NAME="lineage_${LINEAGE_VERSION}_arm64_userdebug.zip" && zip -j ~/public/${ZIP_NAME} out/target/product/generic_arm64/system.img
. build/envsetup.sh && breakfast lineage_arm64_bgNE-bp4a-userdebug && make systemimage -j$(nproc --all) && LINEAGE_VERSION=$(get_build_var LINEAGE_VERSION) && ZIP_NAME="lineage_${LINEAGE_VERSION}_arm64_userdebug.zip" && zip -j ~/public/${ZIP_NAME} out/target/product/generic_arm64/system.img
. build/envsetup.sh && breakfast lineage_arm64_bgN4-bp4a-userdebug && make systemimage -j$(nproc --all) && LINEAGE_VERSION=$(get_build_var LINEAGE_VERSION) && ZIP_NAME="lineage_${LINEAGE_VERSION}_arm64_userdebug.zip" && zip -j ~/public/${ZIP_NAME} out/target/product/generic_arm64/system.img
