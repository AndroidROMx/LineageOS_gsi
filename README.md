English | [Русский](README-RU.md)
### To get started with building the unofficial LineageOS 23.2 GSI together with the patches,
You'll need to get familiar with [Git and Repo](https://source.android.com/source/using-repo.html) as well as [How to build a GSI](https://github.com/phhusson/treble_experimentations/wiki/How-to-build-a-GSI%3F).

### Create the directories

As a first step, you'll have to create and enter a folder with the appropriate name
To do that, run these commands:

```bash
mkdir LineageOS
cd LineageOS
```

### To initialize your local repository, run this command:

```bash
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
```

### Clone the Manifest to add necessary dependencies for gsi:
 
    git clone https://github.com/AndroidROMx/treble_manifest.git .repo/local_manifests -b lineage-23.2
  
### Afterwards, sync the source by running this command:

```bash
repo sync --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j4
```

### Next, apply patches:


```
bash LineageOS_gsi/patches/apply-patches.sh .
```

### Building treble_app

treble_app is now used from your compiled version.  
First, make sure that Java 17 is set as your default. How to do this on [Arch Linux](https://wiki.archlinux.org/title/Java#List_compatible_Java_environments_installed)  
The compilation itself,

or use
```
wget https://github.com/AndroidROMx/vendor_hardware_overlay/raw/refs/heads/main/TrebleApp/app.apk -O treble_app/TrebleApp.apk
```

### Use ccache to speed up Android rebuilds

You can add these lines to the ~/.bashrc or ~/.zshrc file to avoid typing them again:

```
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CCACHE_MAXSIZE=50G # 50 GB
``` 

### Building Android 

VANILLA version with erofs:

 ```
. build/envsetup.sh
ccache -M 50G -F 0
breakfast lineage_arm64_bvNE-bp4a-userdebug
make systemimage -j$(nproc --all)
 ```
or
 ```
 . build/envsetup.sh; breakfast lineage_arm64_bvNE-bp4a-userdebug; make systemimage -j$(nproc --all); LINEAGE_VERSION=$(get_build_var LINEAGE_VERSION); ZIP_NAME="lineage_${LINEAGE_VERSION}_arm64_userdebug.zip"; zip -j ~/public/${ZIP_NAME} out/target/product/generic_arm64/system.img
 ```
 

VANILLA version with ext4:

 ```
. build/envsetup.sh
ccache -M 50G -F 0
breakfast lineage_arm64_bvN4-bp4a-userdebug
make systemimage -j$(nproc --all)
 ```
or
 ```
 . build/envsetup.sh; breakfast lineage_arm64_bvN4-bp4a-userdebug; make systemimage -j$(nproc --all); LINEAGE_VERSION=$(get_build_var LINEAGE_VERSION); ZIP_NAME="lineage_${LINEAGE_VERSION}_arm64_userdebug.zip"; zip -j ~/public/${ZIP_NAME} out/target/product/generic_arm64/system.img
 ```

 
GAPPS version with erofs:

 ```
. build/envsetup.sh
ccache -M 50G -F 0
breakfast lineage_arm64_bgNE-bp4a-userdebug
make systemimage -j$(nproc --all)
 ```
 or
 ```
 . build/envsetup.sh; breakfast lineage_arm64_bgNE-bp4a-userdebug; make systemimage -j$(nproc --all); LINEAGE_VERSION=$(get_build_var LINEAGE_VERSION); ZIP_NAME="lineage_${LINEAGE_VERSION}_arm64_userdebug.zip"; zip -j ~/public/${ZIP_NAME} out/target/product/generic_arm64/system.img
 ```
 

GAPPS version with ext4:

 ```
. build/envsetup.sh
ccache -M 50G -F 0
breakfast lineage_arm64_bgN4-bp4a-userdebug
make systemimage -j$(nproc --all)
 ```
 or
 ```
 . build/envsetup.sh; breakfast lineage_arm64_bgN4-bp4a-userdebug; make systemimage -j$(nproc --all); LINEAGE_VERSION=$(get_build_var LINEAGE_VERSION); ZIP_NAME="lineage_${LINEAGE_VERSION}_arm64_userdebug.zip"; zip -j ~/public/${ZIP_NAME} out/target/product/generic_arm64/system.img
 ```
 

### Compress

After compilation,
If you want to compress the build, i recommend use [7-zip](https://aur.archlinux.org/packages/7-zip), for a fast and safe way
In rom folder,

   ```
cd out/target/product/generic_arm64/
7z a system.img.xz "system.img"
   ```
or
   ```
zip -j ~/lineage-gsi.zip out/target/product/generic_arm64/system.img
   ```
or
   ```
   LINEAGE_VERSION=$(get_build_var LINEAGE_VERSION)
   ZIP_NAME="lineage_${LINEAGE_VERSION}_arm64_userdebug.zip"

   zip -j ~/public/${ZIP_NAME} out/target/product/generic_arm64/system.img
   ```

### Troubleshoot
 
If you face any conflicts while applying patches, apply the patch manually

### Credits
These people have helped this project in some way or another, so they should be the ones who receive all the credit:
- [LineageOS Team](https://github.com/LineageOS)
- [Phhusson](https://github.com/phhusson)
- [AndyYan](https://github.com/AndyCGYan)
- [Ponces](https://github.com/ponces)
- [Peter Cai](https://github.com/PeterCxy)
- [Iceows](https://github.com/Iceows)
- [ChonDoit](https://github.com/ChonDoit)
- [Nazim N ](https://github.com/naz664)
- [Ahnet](https://github.com/ahnet-69)
- [mytja](https://github.com/mytja)
- [cawilliamson](https://github.com/cawilliamson)
- [Doze-off](https://github.com/Doze-off)
