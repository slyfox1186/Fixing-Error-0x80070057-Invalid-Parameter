#!/Usr/bin/env bash


clear

if [ "$EUID" -eq '0' ]; then
    echo "You must run this script without root or sudo."
    exit 1
fi


script_ver=1.2
archive_dir=systemd-253
archive_url=https://github.com/systemd/systemd/archive/refs/tags/v253.tar.gz
archive_ext="$archive_url//*."
archive_name="$archive_dir.tar.$archive_ext"
cwd="$PWD"/systemd-build-script
install_dir=/usr/local
user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36'
web_repo=https://github.com/slyfox1186/script-repo

printf "%s\n%s\n\n" \
    "systemd build script - v$script_ver" \
    '==============================================='


if [ -d "$cwd" ]; then
    sudo rm -fr "$cwd"
fi
mkdir -p "$cwd"


export CC=gcc CXX=g++


export {CFLAGS,CXXFLAGS}='-g -O3 -pipe -fno-plt -march=native'


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


LD_LIBRARY_PATH="\
/usr/local/lib64:\
/usr/local/lib:\
/usr/lib64:\
/usr/lib:\
/lib64:\
/lib:\
/usr/local/cuda-12.2/nvvm/lib64\
"
export LD_LIBRARY_PATH


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
        1)      sudo rm -fr "$cwd";;
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


pkgs=("$1" autoconf autoconf-archive autogen automake binutils bpftool build-essential ccache clang cmake curl git gnu-efi golang-gir-gio-2.0-dev golang-gir-gobject-2.0-dev
      gperf jekyll kexec-tools libacl1-dev libapparmor-dev libaudit-dev libbinutils libblkid-dev libblkid1 libbpf-dev libbz2-dev libcap-dev
      libcryptsetup-dev libcryptsetup12 libcurl4-openssl-dev libdbus-1-dev libdrpm-dev libdw-dev libfdisk-dev libfido2-dev libglib2.0-dev
      libgnutls28-dev libidn11-dev libidn2-0-dev libidn2-dev libiptc-dev libkrb5-dev libkmod-dev liblz4-dev libmicrohttpd-dev libmount-dev libnacl-dev libnss-myhostname
      libp11-kit-dev libpam0g-dev libpolkit-gobject-1-dev libpwquality-dev libqrencode-dev libquota-perl libquotient-dev librpm-dev librust-pam-dev
      librust-quote-dev libseccomp-dev libssl-dev libtss2-dev libsystemd-dev libtool libtool-bin libxen-dev libxkbcommon-dev m4 meson nasm ninja-build
      openssl python3 python3-evdev python3-jinja2 python3-pyparsing quota strace valgrind xsltproc yasm)

for i in ${pkgs[@]}
do
    missing_pkg="$(sudo dpkg -l | grep -o "$i")"

    if [ -z "$missing_pkg" ]; then
        missing_pkgs+=" $i"
    fi
done
unset i

if [ -n "$missing_pkgs" ]; then
    sudo apt install $missing_pkgs
    sudo apt -y autoremove
    clear
fi


if [ ! -f "$cwd/$archive_name" ]; then
    curl -A "$user_agent" -Lso "$cwd/$archive_name" "$archive_url"
fi


if [ -d "$cwd/$archive_dir" ]; then
    sudo rm -fr "$cwd/$archive_dir"
fi
mkdir -p "$cwd/$archive_dir/build"


if ! tar -xf "$cwd/$archive_name" -C "$cwd/$archive_dir" --strip-components 1; then
    printf "%s\n\n" "Failed to extract: $cwd/$archive_name"
    exit 1
fi


cd "$cwd/$archive_dir" || exit 1
meson setup build --prefix="$install_dir" \
                  --buildtype=release       \
                  --default-library=both    \
                  --strip                   \
                  -Dzstd=true
make "-j$(nproc --all)"
if ! sudo make install; then
    fail_fn "Failed to execute: sudo make install:Line $LINENO"
    exit 1
fi

cleanup_fn

exit_fn