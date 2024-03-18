#!/Usr/bin/env bash


if [ "$EUID" -ne 0 ]; then
    echo "You must run this script with root or sudo."
    exit 1
fi


script_ver=1.0
archive_dir=sed-4.9
archive_url=https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz
archive_ext="$archive_url//*."
archive_name="$archive_dir.tar.$archive_ext"
cwd="$PWD/sed-build-script"
install_dir=/usr/local
web_repo=https://github.com/slyfox1186/script-repo

printf "%s\n%s\n\n" \
    "sed build script - v$script_ver" \
    '==============================================='


if [ -d "$cwd" ]; then
    rm -fr "$cwd"
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

    printf "\n%s\n%s\n%s\n\n%s\n%s\n\n" \
        "============================================" \
        "  Do you want to clean up the build files?  " \
        "============================================" \
        "[1] Yes" \
        "[2] No"
    read -p "Your choices are (1 or 2): " choice

    case "$choice" in
        1)      rm -fr "$cwd" ;;
        2)      return ;;
        *)      unset choice
                clear
                cleanup_fn
                ;;
    esac
}


pkgs_fn() {
    pkgs=(
    autoconf autoconf-archive autogen automake autopoint autotools-dev build-essential bzip2
    ccache curl git libaudit-dev libintl-perl libticonv-dev libtool libtool-bin lzip pkg-config
    valgrind zlib1g-dev librust-polling-dev
)

    for i in ${pkgs[@]}
    do
        missing_pkg="$(dpkg -l | grep -o "$i")"

        if [ -z "$missing_pkg" ]; then
            missing_pkgs+=" $i"
        fi
    done

    if [ -n "$missing_pkgs" ]; then
        apt install $missing_pkgs
        apt -y autoremove
        clear
    fi
}

if [ ! -f "$cwd/$archive_name" ]; then
    curl -A "$user_agent" -Lso "$cwd/$archive_name" "$archive_url"
fi

if [ -d "$cwd/$archive_dir" ]; then
    rm -fr "$cwd/$archive_dir"
fi
mkdir -p "$cwd/$archive_dir/build"

if ! tar -xf "$cwd/$archive_name" -C "$cwd/$archive_dir" --strip-components 1; then
    printf "%s\n\n" "Failed to extract: $cwd/$archive_name"
    exit 1
fi

if [ -f "/usr/local/bin/iconv" ]; then
    pkgs_fn
    iconv_prefix=/usr/local
elif [ -f /usr/bin/iconv ]; then
    pkgs_fn
    iconv_prefix=/usr
else
    pkgs_fn "libticonv-dev"
    iconv_prefix=/usr
fi

cd "$cwd/$archive_dir" || exit 1
cd build || exit 1
../configure --prefix="$install_dir" \
             --{build,host}=$(../build-aux/config.guess) \
             --enable-threads=posix \
             --disable-nls \
             --with-libiconv-prefix=/usr \
             --with-libintl-prefix=/usr
echo
if ! make "-j$(nproc --all)"; then
    fail_fn "Failed to execute: make -j$(nproc --all). Line $LINENO"
    exit 1
fi
echo
if ! make install; then
    fail_fn "Failed to execute: make install. Line $LINENO"
    exit 1
fi

cleanup_fn

exit_fn