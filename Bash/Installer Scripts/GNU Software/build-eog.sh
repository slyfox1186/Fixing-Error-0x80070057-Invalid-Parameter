#!/Usr/bin/env bash


if [ "$EUID" -eq 0 ]; then
    echo "You must run this script without root or sudo."
    exit 1
fi


script_ver=1.1
archive_dir=eog
archive_url=https://download.gnome.org/sources/eog/44/eog-44.3.tar.xz
archive_ext="$archive_url//*."
archive_name="$archive_dir.tar.$archive_ext"
cwd="$PWD"/eog-build-script
install_dir=/usr/local
user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36'
web_repo=https://github.com/slyfox1186/script-repo
debug=OFF

printf "%s\n%s\n\n" \
    "eog build script - v$script_ver" \
    '==============================================='

if [ -d "$cwd" ]; then
    sudo rm -fr "$cwd"
fi
mkdir -p "$cwd"

set_compiler_options() {
    CC="ccache gcc"
    CXX="ccache g++"
    CFLAGS="-g -O3 -pipe -fno-plt -march=native"
    CXXFLAGS="-g -O3 -pipe -fno-plt -march=native"
    export CC CFLAGS CXX CXXFLAGS
}

PATH="\
/usr/lib/ccache:\
$HOME/perl5/bin:\
$HOME/.cargo/bin:\
$HOME/.local/bin:\
/usr/local/sbin:\
/usr/local/cuda/bin:\
/usr/local/x86_64-linux-gnu/bin:\
/usr/local/bin:\
/usr/sbin:\
/usr/bin:\
/sbin:\
/bin:\
/usr/local/games:\
/usr/games:\
/snap/bin\
"
export PATH


PKG_CONFIG_PATH="\
/usr/local/lib64/pkgconfig:\
/usr/local/lib/pkgconfig:\
/usr/local/lib/x86_64-linux-gnu/pkgconfig:\
/usr/local/share/pkgconfig:\
/usr/lib64/pkgconfig:\
/usr/lib/pkgconfig:\
/usr/lib/x86_64-linux-gnu/pkgconfig:\
/usr/share/pkgconfig:\
/lib64/pkgconfig:\
/lib/pkgconfig:\
/lib/x86_64-linux-gnu/pkgconfig\
"
export PKG_CONFIG_PATH


LIBRARY_PATH="\
/usr/lib/x86_64-linux-gnu:\
$LIBRARY_PATH\
"
export LIBRARY_PATH


exit_fn() {
    printf "\n%s\n\n%s\n\n" \
        'Make sure to star this repository to show your support!' \
        "$web_repo"
    exit 0
}

fail_fn() {
    printf "\n%s\n\n%s\n\n" \
        "$1" \
        "To report a bug create an issue at: $web_repo/issues"
    exit 1
}

cleanup_fn() {
    local choice

    printf "%s\n%s\n%s\n\n%s\n%s\n\n" \
        '============================================' \
        '  Do you want to clean up the build files?  ' \
        '============================================' \
        '[1] Yes' \
        '[2] No'
    read -p 'Your choices are (1 or 2): ' choice

    case "$choice" in
        1)      sudo rm -fr "$cwd" "$0";;
        2)      echo;;
        *)
                clear
                printf "%s\n\n" 'Bad user input. Reverting script...'
                sleep 3
                unset choice
                clear
                cleanup_fn
                ;;
    esac
}


pkgs=(autoconf autoconf-archive autogen automake binutils build-essential ccache clang
      cmake curl git libgnome-desktop-3-dev libexempi-dev libportal-dev libportal-gtk3-dev
      libportal-gtk4-dev libgnome-desktop-4-dev libhandy-1-dev libpeas-dev libpeasd-3-dev
      libtool libtool-bin m4 meson nasm ninja-build python3 yasm itstool)

for i in ${pkgs[@]}
do
    missing_pkg="$(sudo dpkg -l | grep -o "$i")"

    if [ -z "$missing_pkg" ]; then
        missing_pkgs+=" $i"
    fi
done

if [ -n "$missing_pkgs" ]; then
    sudo apt install $missing_pkgs
    sudo apt -y autoremove
    clear
fi


if [ ! -f "$cwd/$archive_name" ]; then
    curl -Lso "$cwd/$archive_name" "$archive_url"
fi
mkdir -p "$cwd/$archive_dir/build"


if ! tar -xf "$cwd/$archive_name" -C "$cwd/$archive_dir" --strip-components 1; then
    fail_fn "Failed to extract: $cwd/$archive_name"
    exit 1
fi


clear
cd "$cwd/$archive_dir" || exit 1
meson setup build --prefix="$install_dir" \
                  --buildtype=release       \
                  --default-library=static  \
                  --strip
ninja "-j$(nproc --all)" -C build
if ! sudo ninja "-j$(nproc --all)" -C build install; then
    fail_fn "Failed to execute: sudo ninja -j$(nproc --all) -C build install:Line $LINENO"
    exit 1
fi

cleanup_fn

exit_fn