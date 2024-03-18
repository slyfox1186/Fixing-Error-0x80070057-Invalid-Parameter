#!/Usr/bin/env bash


if [[ $EUID -ne 0 ]]; then
    echo -e "\033[31mThis script must be run as root or with sudo.\033[0m"
    exit 1
fi

script_ver="1.4"
cwd="$PWD/gawk-build-script"
install_dir="/usr/local"
web_repo="https://github.com/slyfox1186/script-repo"
gnu_ftp="https://ftp.gnu.org/gnu/gawk/"

print_color() {
    case $1 in
        green) echo -e "\033[0;32m$2\033[0m" ;;
        red) echo -e "\033[0;31m$2\033[0m" ;;
        *) echo "$2" ;;
    esac
}

print_banner() {
    print_color green "gawk build script - v$script_ver"
    echo "==============================================="
}

cleanup() {
    print_color green "Cleaning up..."
    rm -fr "$cwd"
}

handle_failure() {
    print_color red "\nAn error occurred. Exiting..."
    cleanup
    exit 1
}

install_missing_packages() {
    print_color green "Checking and installing missing packages..."
    if command -v apt > /dev/null; then
        pkgs=(autoconf autoconf-archive autogen automake binutils build-essential ccache cmake curl git libtool libtool-bin lzip m4 nasm ninja-build texinfo zlib1g-dev yasm)
        apt update
        for pkg in "${pkgs[@]}"; do
            if ! dpkg -l | grep -qw $pkg; then
                apt install -y $pkg
            fi
        done
    elif command -v yum > /dev/null; then
        yum install -y autoconf automake binutils gcc gcc-c++ make
    else
        print_color red "Unsupported package manager. Please install dependencies manually."
        exit 1
    fi
}

find_latest_release() {
    clear
    print_color green "Finding the latest gawk release..."
    latest_release=$(curl -sL $gnu_ftp | grep tar.lz | grep -v '.sig' | sed -n 's/.*href="\([^"]*\).*/\1/p' | sort -V | tail -n 1)
    if [[ -z $latest_release ]]; then
        print_color red "Failed to find the latest gawk release. Exiting..."
        exit 1
    fi
    archive_url="$gnu_ftp$latest_release"
    archive_name="$latest_release"
    archive_dir=$(echo $latest_release | sed 's/.tar.lz//')
}

download_and_extract() {
    print_color green "Downloading and extracting gawk..."
    mkdir -p "$cwd"
    cd "$cwd" || exit
    if [[ ! -f $archive_name ]]; then
        curl -Lso $archive_name $archive_url
    fi
    mkdir -p "$archive_dir/build"
    tar --lzip -xf $archive_name -C "$archive_dir/build" --strip-components 1 || handle_failure
}

build_and_install() {
    print_color green "Building and installing gawk..."
    cd "$archive_dir/build" || exit 1
    ./configure --prefix=/usr/local/gawk CFLAGS="-g -O3 -pipe -fno-plt -march=native" --build=x86_64-linux-gnu --host=x86_64-linux-gnu || handle_failure
    make "-j$(nproc)" || handle_failure
    make install || handle_failure
    print_color green "gawk installation completed successfully."
}

print_banner
install_missing_packages
find_latest_release
download_and_extract
build_and_install
cleanup