#shellcheck disable=SC2162,SC1091,SC2317

#########################################
## SET SUDO TO RUN AS THE CURRENT USER ##
#########################################

# sudo() { eval $(which sudo) -H -u root "$@"; }

##################################################################################
## WHEN LAUNCHING CERTAIN PROGRAMS FROM TERMINAL, SUPPRESS ANY WARNING MESSAGES ##
##################################################################################

gte() { eval $(which gnome-text-editor) "$@" &>/dev/null; }
gtes() { eval $(which sudo) -H -u root /usr/bin/gnome-text-editor "$@" &>/dev/null; }

###################
## FIND COMMANDS ##
###################

ffind()
{
    clear

    local fname fpath ftype fmaxdepth

    read -p 'Enter the name to search for: ' fname
    echo
    read -p 'Enter a type of file (d|f|blank): ' ftype
    echo
    read -p 'Enter the starting path: ' fpath
    clear

    if [ -n "$fname" ] && [ -z "$ftype" ] && [ -z "$fpath" ]; then
        sudo find . -iname "$fname" | while read line; do echo "$line"; done
    elif [ -n "$fname" ] && [ -z "$ftype" ] && [ -n "$fpath" ]; then
        sudo find "$fpath" -iname "$fname" | while read line; do echo "$line"; done
    elif [ -n "$fname" ] && [ -n "$ftype" ] && [ -n "$fpath" ]; then
        sudo find "$fpath" -type "$ftype" -iname "$fname" | while read line; do echo "$line"; done
    elif [ -n "$fname" ] && [ -z "$ftype" ] && [ "$fpath" ]; then
        sudo find . -iname "$fname" | while read line; do echo "$line"; done
    elif [ -n "$fname" ] && [ -n "$ftype" ] && [ "$fpath" = '.' ]; then
        sudo find . -type "$ftype" -iname "$fname" | while read line; do echo "$line"; done
     fi
}

######################
## UNCOMPRESS FILES ##
######################

untar()
{
    clear

    local ext file

    for file in *.*
    do
        ext="${file##*.}" && mkdir -p "$PWD/${file%%.*}"

        case "$ext" in
            7z|zip)
                7z x -o"$PWD/${file%%.*}" "$PWD/$file"
                ;;
            bz2|gz|xz)
                jflag=''
                [[ "$ext" == 'bz2' ]] && jflag='j'
                tar -xf$jflag "$PWD/$file" -C "$PWD/${file%%.*}"
                ;;
            *)
                printf "%s\n\n%s\n\n" \
                    'No archives to extract were found.' \
                    'Make sure you run this function in the same directory as the archives'
                ;;
        esac
    done
}

##################
## CREATE FILES ##
##################

mf()
{
    clear

    local i

    if [ -z "$1" ]; then
        read -p 'Enter file name: ' i
        clear
        if [ ! -f "$i" ]; then touch "$i"; fi
        chmod 744 "$i"
    else
        if [ ! -f "$1" ]; then touch "$1"; fi
        chmod 744 "$1"
    fi

    clear; ls -1AhFv --color --group-directories-first
}

mdir()
{
    clear

    local dir

    if [[ -z "$1" ]]; then
        read -p 'Enter directory name: ' dir
        clear
        mkdir -p  "$PWD/$dir"
        cd "$PWD/$dir" || exit 1
    else
        mkdir -p "$1"
        cd "$PWD/$1" || exit 1
    fi

    clear; ls -1AhFv --color --group-directories-first
}

##################
## AWK COMMANDS ##
##################

# REMOVED ALL DUPLICATE LINES: OUTPUTS TO TERMINAL
rmd() { clear; awk '!seen[${0}]++' "$1"; }

# REMOVE CONSECUTIVE DUPLICATE LINES: OUTPUTS TO TERMINAL
rmdc() { clear; awk 'f!=${0}&&f=${0}' "$1"; }

# REMOVE ALL DUPLICATE LINES AND REMOVES TRAILING SPACES BEFORE COMPARING: REPLACES THE file
rmdf()
{
    clear
    perl -i -lne 's/\s*$//; print if ! $x{$_}++' "$1"
    ged "$1"
}

###################
## file COMMANDS ##
###################

# COPY file
cpf()
{
    clear

    if [ ! -d "$HOME/tmp" ]; then
        mkdir -p "$HOME/tmp"
    fi

    cp "$1" "$HOME/tmp/$1"

    chown -R "$USER":"$USER" "$HOME/tmp/$1"
    chmod -R 744 "$HOME/tmp/$1"

    clear; ls -1AhFv --color --group-directories-first
}

# MOVE file
mvf()
{
    clear

    if [ ! -d "$HOME/tmp" ]; then
        mkdir -p "$HOME/tmp"
    fi

    mv "$1" "$HOME/tmp/$1"

    chown -R "${USER}":"${USER}" "$HOME/tmp/$1"
    chmod -R 744 "$HOME/tmp/$1"

    clear; ls -1AhFv --color --group-directories-first
}

##################
## APT COMMANDS ##
##################

# DOWNLOAD AN APT PACKAGE + ALL ITS DEPENDENCIES IN ONE GO
apt_dl() { wget -c "$(apt-get install --reinstall --print-uris -qq $1 | cut -d"'" -f2)"; }

# CLEAN
clean()
{
    clear
    sudo apt-fast -y autoremove
    sudo apt-fast clean
    sudo apt-fast autoclean
    sudo apt-fast -y purge
}

# UPDATE
update()
{
    clear
    sudo apt-fast update
    sudo apt-fast -y full-upgrade
    sudo apt-fast -y install ubuntu-advantage-tools
    sudo apt-fast -y autoremove
    sudo apt-fast clean
    sudo apt-fast autoclean
    sudo apt-fast -y purge
}

# FIX BROKEN APT PACKAGES
fix()
{
    clear
    sudo apt-fast -f -y install
    apt --fix-broken install
    apt --fix-missing update
    dpkg --configure -a
    sudo apt-fast -y autoremove
    sudo apt-fast clean
    sudo apt-fast autoclean
    sudo apt-fast -y purge
    sudo apt-fast update
}

listd()
{
    clear
    local search_cache

    if [ -n "$1" ]; then
        sudo apt-fast list *$1*-dev | awk -F'/' '{print $1}'
    else
        read -p 'Enter the string to search: ' search_cache
        clear
        sudo apt-fast list *$1*-dev | awk -F'/' '{print $1}'
    fi
}


list()
{
    clear
    local search_cache

    if [ -n "$1" ]; then
        sudo apt-fast list *$1* | awk -F'/' '{print $1}'
    else
        read -p 'Enter the string to search: ' search_cache
        clear
        sudo apt-fast list *$1* | awk -F'/' '{print $1}'
    fi
}

# USE sudo apt-fast TO SEARCH FOR ALL APT PACKAGES BY PASSING A NAME TO THE FUNCTION
asearch()
{
    clear
    local search_cache

    if [ -n "$1" ]; then
        sudo apt-fast search "$1 ~i" -F "%p"
    else
        read -p 'Enter the string to search: ' search_cache
        clear
        sudo apt-fast search "$1 ~i" -F "%p"
    fi
}

# USE APT CACHE TO SEARCH FOR ALL APT PACKAGES BY PASSING A NAME TO THE FUNCTION
csearch()
{
    clear
    local search_cache

    if [ -n "$1" ]; then
        apt-cache search --names-only "$1.*" | awk '{print $1}'
    else
        read -p 'Enter the string to search: ' search_cache
        clear
        apt-cache search --names-only "$search_cache.*" | awk '{print $1}'
    fi
}

# FIX MISSING GPNU KEYS USED TO UPDATE PACKAGES
fix_key()
{
    clear

    local file url

    if [[ -z "$1" ]] && [[ -z "$2" ]]; then
        read -p 'Enter the file name to store in /etc/apt/trusted.gpg.d: ' file
        echo
        read -p 'Enter the gpg key url: ' url
        clear
    else
        file="$1"
        url="$2"
    fi

    curl -S# "$url" | gpg --dearmor | sudo tee "/etc/apt/trusted.gpg.d/$file"

    if curl -S# "$url" | gpg --dearmor | sudo tee "/etc/apt/trusted.gpg.d/$file"; then
        echo 'The key was successfully added!'
    else
        echo 'The key FAILED to add!'
    fi
}


##########################
# TAKE OWNERSHIP COMMAND #
##########################
toa()
{
    clear

    chown -R "$USER":"$USER" "$PWD"
    chmod -R 744 "$PWD"

    clear; ls -1AhFv --color --group-directories-first
}

#################
# DPKG COMMANDS #
#################

## SHOW ALL INSTALLED PACKAGES
showpkgs()
{
    dpkg --get-selections |
    grep -v deinstall > "$HOME"/tmp/packages.list
    ged "$HOME"/tmp/packages.list
}

# PIPE ALL DEVELOPMENT PACKAGES NAMES TO file
getdev()
{
    apt-cache search dev |
    grep "\-dev" |
    cut -d ' ' -f1 |
    sort > 'dev-packages.list'
    ged 'dev-packages.list'
}

################
## SSH-KEYGEN ##
################

# create a new private and public ssh key pair
new_key()
{
    clear

    local bits comment name pass type

    echo -e "Encryption type: [ rsa | dsa | ecdsa ]\\n"
    read -p 'Your choice: ' type
    clear

    echo '[i] Choose the key bit size'
    echo '[i] Values encased in() are recommended'

    if [[ "$type" == 'rsa' ]]; then
        echo -e "[i] rsa: [ 512 | 1024 | (2048) | 4096 ]\\n"
    elif [[ "$type" == 'dsa' ]]; then
        echo -e "[i] dsa: [ (1024) | 2048 ]\\n"
    elif [[ "$type" == 'ecdsa' ]]; then
        echo -e "[i] ecdsa: [ (256) | 384 | 521 ]\\n"
    fi

    read -p 'Your choice: ' bits
    clear

    echo '[i] Choose a password'
    echo -e "[i] For no password just press enter\\n"
    read -p 'Your choice: ' pass
    clear

    echo '[i] Choose a comment'
    echo -e "[i] For no comment just press enter\\n"
    read -p 'Your choice: ' comment
    clear

    echo -e "[i] Enter the ssh key name\\n"
    read -p 'Your choice: ' name
    clear

    echo -e "[i] Your choices\\n"
    echo -e "[i] Type: $type"
    echo -e "[i] bits: $bits"
    echo -e "[i] Password: $pass"
    echo -e "[i] comment: $comment"
    echo -e "[i] Key name: $name\\n"
    read -p 'Press enter to continue or ^c to exit'
    clear

    ssh-keygen -q -b "$bits" -t "$type" -N "$pass" -C "$comment" -f "$name"

    chmod 600 "$PWD/$name"
    chmod 644 "$PWD/$name".pub
    clear

    echo -e "file: $PWD/$name\\n"
    cat "$PWD/$name"

    echo -e "\\nfile: $PWD/$name.pub\\n"
    cat "$PWD/$name.pub"
    echo
}

# export the public ssh key stored inside a private ssh key
keytopub()
{
    clear; ls -1AhFv --color --group-directories-first

    local opub okey

    echo -e "Enter the full paths for each file\\n"
    read -p 'Private key: ' okey
    read -p 'Public key: ' opub
    clear
    if [ -f "$okey" ]; then
        chmod 600 "$okey"
    else
        echo -e "Warning: file missing = $okey\\n"
        read -p 'Press Enter to exit.'
        exit 1
    fi
    ssh-keygen -b '4096' -y -f "$okey" > "$opub"
    chmod 644 "$opub"
    cp "$opub" "$HOME"/.ssh/authorized_keys
    chmod 600 "$HOME"/.ssh/authorized_keys
    unset "$okey"
    unset "$opub"
}

# install colordiff package :)
cdiff() { clear; colordiff "$1" "$2"; }

# GZIP
gzip() { clear; gzip -d "$@"; }

# get system time
show_time() { clear; date +%r | cut -d " " -f1-2 | grep -E '^.*$'; }

# CHANGE DIRECTORY
cdsys() { pushd "$HOME"/system || exit 1; cl; }

##################
## SOURCE FILES ##
##################

sbrc()
{
    clear

    source "$HOME"/.bashrc && echo -e "The command was a success!\\n" || echo -e "The command failed!\\n"
    sleep 1

    clear; ls -1AhFv --color --group-directories-first
}

spro()
{
    clear

    source "$HOME"/.profile && echo -e "The command was a success!\\n" || echo -e "The command failed!\\n"
    sleep 1

    clear; ls -1AhFv --color --group-directories-first
}

####################
## ARIA2 COMMANDS ##
####################

# ARIA2 DAEMON IN BACKGROUND
aria2_on()
{
    clear

    if aria2c --conf-path="$HOME"/.aria2/aria2.conf; then
        echo -e "\\nCommand Executed Successfully\\n"
    else
        echo -e "\\nCommand Failed\\n"
    fi
}

# STOP ARIA2 DAEMON
aria2_off() { clear; killall aria2c; }

# RUN ARIA2 AND DOWNLOAD FILES TO CURRENT FOLDER
aria2()
{
    clear

    local file link

    if [[ -z "$1" ]] && [[ -z "$2" ]]; then
        read -p 'Enter the output file name: ' file
        echo
        read -p 'Enter the download url: ' link
        clear
    else
        file="$1"
        link="$2"
    fi

    aria2c --out="$file" "$link"
}

# PRINT lan/wan IP
myip()
{
    clear
    lan="$(hostname -I)"
    wan="$(dig +short myip.opendns.com @resolver1.opendns.com)"
    clear
    echo "Internal IP (lan) address: $lan"
    echo "External IP (wan) address: $wan"
}

# WGET COMMAND
mywget()
{
    clear; ls -1AhFv --color --group-directories-first

    local outfile url

    if [ -z "$1" ] || [ -z "$2" ]; then
        read -p 'Please enter the output file name: ' outfile
        echo
        read -p 'Please enter the url: ' url
        clear
        wget --out-file="$outfile" "$url"
    else
        wget --out-file="$1" "$2"
    fi
}

################
# RM COMMANDS ##
################

# RM DIRECTORY
rmd()
{
    clear

    local i

    if [ -z "$1" ] || [ -z "$2" ]; then
        read -p 'Please enter the directory name to remove: ' i
        clear
        sudo rm -r "$i"
        clear
    else
        sudo rm -r "$1"
        clear
    fi
}

# RM file
rmf()
{
    clear

    local i

    if [ -z "$1" ]; then
        read -p 'Please enter the file name to remove: ' i
        clear
        sudo rm "$i"
        clear
    else
        sudo rm "$1"
        clear
    fi
}

#################
## IMAGEMAGICK ##
#################

# OPTIMIZE WITHOUT OVERWRITING THE ORIGINAL IMAGES
imo()
{
    clear

    local i
    # find all jpg files and create temporary cache files from them
    for i in *.jpg; do
        echo -e "\\nCreating two temporary cache files: ${i%%.jpg}.mpc + ${i%%.jpg}.cache\\n"
        dimensions="$(identify -format '%wx%h' "$i")"
        convert "$i" -monitor -filter Triangle -define filter:support=2 -thumbnail "$dimensions" -strip \
        -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off \
        -auto-level -enhance -interlace none -colorspace sRGB "/tmp/${i%%.jpg}.mpc"
        clear
        for cfile in /tmp/*.mpc; do
        # find the temporary cache files created above and output optimized jpg files
            if [ -f "$cfile" ]; then
                echo -e "\\nOverwriting orignal file with optimized self: $cfile >> ${cfile%%.mpc}.jpg\\n"
                convert "$cfile" -monitor "${cfile%%.mpc}.jpg"
                # overwrite the original image with it's optimized version
                # by moving it from the tmp directory to the source directory
                if [ -f "${cfile%%.mpc}.jpg" ]; then
                    mv "${cfile%%.mpc}.jpg" "$PWD"
                    # delete both cache files before continuing
                    rm "$cfile"
                    rm "${cfile%%.mpc}.cache"
                    clear
                fi
            fi
        done
    done
}

# OPTIMIZE AND OVERWRITE THE ORIGINAL IMAGES
imow()
{
    clear
    local i dimensions random v v_noslash

    # Delete any useless zone idenfier files that spawn from copying a file from windows ntfs into a WSL directory
    find . -name "*:Zone.Identifier" -type f -delete 2>/dev/null

    # find all jpg files and create temporary cache files from them
    for i in *.jpg
    do
        # create a variable to hold a randomized directory name to protect against crossover if running
        # this function more than once at a time
        random="$(mktemp --directory)"
        echo '========================================================================================================='
        echo
        echo "Working Directory: $PWD"
        echo
        printf "Converting: %s\n             >> %s\n              >> %s\n               >> %s\n" "$i" "${i%%.jpg}.mpc" "${i%%.jpg}.cache" "${i%%.jpg}-IM.jpg"
        echo
        echo '========================================================================================================='
        echo
        dimensions="$(identify -format '%wx%h' "$i")"
        convert "$i" -monitor -filter 'Triangle' -define filter:support='2' -thumbnail "$dimensions" -strip \
            -unsharp '0.25x0.08+8.3+0.045' -dither None -posterize '136' -quality '82' -define jpeg:fancy-upsampling='off' \
            -define png:compression-filter='5' -define png:compression-level='9' -define png:compression-strategy='1' \
            -define png:exclude-chunk='all' -auto-level -enhance -interlace 'none' -colorspace 'sRGB' "$random/${i%%.jpg}.mpc"
        clear
        for cached in "$random"/*.mpc
        do
            if [ -f "$cached" ]; then
                convert "$cached" -monitor "${cached%%.mpc}.jpg"
                if [ -f "${cached%%.mpc}.jpg" ]; then
                    CWD="$(${cached//s:.*/::})"
                    mv "${cached%%.mpc}.jpg" "$PWD/${CWD%%.*}-IM.jpg"
                    rm -f "$PWD/${CWD%%.*}.jpg"
                    for v in $cached
                    do
                        v_noslash="${v%/}"
                        rm -fr "${v_noslash%/*}"
                        clear
                    done
                else
                    clear
                    echo 'Error: Unable to find the optimized image.'
                    echo
                    return 1
                fi
            fi
        done
    done

    # The text-to-speech below requries the following packages:
    # pip install gTTS; sudo apt -y install sox libsox-fmt-all
    if google_speech 'Image conversion completed.'; then
        return 0
    else
        google_speech 'Image conversion failed.'
        return 1
    fi
}

# DOWNSAMPLE IMAGE TO 50% OF THE ORIGINAL DIMENSIONS USING SHARPER SETTINGS
im50()
{
    clear
    local i

    for i in *.jpg
    do
        convert "$i" -monitor -colorspace sRGB -filter 'LanczosRadius' -distort Resize 50% -colorspace sRGB "$i"
    done
}

##################################################
## SHOW file name AND SIZE IN CURRENT DIRECTORY ##
##################################################

fs() { clear; du --max-depth=1 -abh | grep -Eo '^[0-9A-Za-z\_\-\.]*|[a-zA-Z0-9\_\-]+\.jpg$'; }

big_img() { clear; sudo find . -size +10M -type f -name '*.jpg' 2>/dev/null; }

###########################
## SHOW NVME TEMPERATURE ##
###########################

nvme_temp()
{
    clear

    local n0 n1 n2

    n0="$(sudo nvme smart-log /dev/nvme0n1)"
    n1="$(sudo nvme smart-log /dev/nvme1n1)"
    n2="$(sudo nvme smart-log /dev/nvme2n1)"

    printf "nvme0n1:\n\n%s\n\nnvme1n1:\n\n%s\n\nnvme2n1:\n\n%s\n\n" "$n0" "$n1" "$n2"
}

#############################
## REFRESH THUMBNAIL CACHE ##
#############################

rftn()
{
    clear
    sudo rm -fr "$HOME"/.cache/thumbnails/*
    ls -al "$HOME"/.cache/thumbnails
}

#######################
## NAUTILUS COMMANDS ##
#######################

nopen()
{
    nohup nautilus -w "$1" &>/dev/null &
}

#####################
## FFMPEG COMMANDS ##
#####################

cuda_purge()
{
    clear

    local answer

    echo 'Do you want to completely remove the cuda-sdk-toolkit?'
    echo
    echo 'WARNING: Do not reboot your PC without reinstalling the nvidia-driver first!'
    echo
    echo '[1] Yes'
    echo '[2] Exit'
    echo
    read -p 'Your choices are (1 or 2): ' answer
    clear

    if [[ "${answer}" -eq '1' ]]; then
        echo 'Purging the cuda-sdk-toolkit from your computer.'
        echo '================================================'
        echo
        sudo sudo apt-fast -y --purge remove "*cublas*" "cuda*" "nsight*"
        sudo sudo apt-fast -y autoremove
        sudo sudo apt-fast update
    elif [[ "${answer}" -eq '2' ]]; then
        return 0
    fi
}

##############################
## LIST LARGE FILES BY TYPE ##
##############################

large_files()
{
    clear

    local answer

    echo 'Input the file extension to search for without a dot: '
    echo
    read -p 'Enter your choice: ' answer
    clear
    find "$PWD" -type f -name "*.${answer}" -printf '%h\n' | sort -u -o 'large-files.txt'
    if [ -f 'large-files.txt' ]; then
        sudo ged 'large-files.txt'
    fi
}

###############
## MEDIAINFO ##
###############

mi()
{
    clear

    local i

    if [ -z "$1" ]; then
        ls -1AhFv --color --group-directories-first
        echo
        read -p 'Please enter the relative file path: ' i
        clear
        mediainfo "$i"
    else
        mediainfo "$1"
    fi
}

############
## FFMPEG ##
############

cdff() { clear; cd "$HOME/tmp/ffmpeg-build" || exit 1; cl; }
ffm() { clear; bash <(curl -sSL 'http://ffmpeg.optimizethis.net'); }
ffp() { clear; bash <(curl -sSL 'http://ffpb.optimizethis.net'); }

####################
## LIST PPA REPOS ##
####################

listppas()
{
    clear

    local _apt host user ppa entry

    for _apt in $(find /etc/apt/ -type f -name \*.list)
    do
        grep -Po "(?<=^deb\s).*?(?=#|$)" "$_apt" | while read entry
        do
            host="$(echo "$entry" | cut -d/ -f3)"
            user="$(echo "$entry" | cut -d/ -f4)"
            ppa="$(echo "$entry" | cut -d/ -f5)"
            #echo sudo apt-add-repository ppa:$user/$ppa
            if [ "ppa.launchpad.net" = "$host" ]; then
                echo sudo apt-add-repository ppa:"$user/$ppa"
            else
                echo sudo apt-add-repository \'deb "$entry"\'
            fi
        done
    done
}

#########################
## NVIDIA-SMI COMMANDS ##
#########################

monitor_gpu() { clear; nvidia-smi dmon; }

################################################################
## PRINT THE NAME OF THE DISTRIBUTION YOU ARE CURRENTLY USING ##
################################################################

os_name() { clear; eval lsb_release -a | grep -Eo '[A-Za-z]+ [0-9\.]+\s*[A-Z]*'; }

##############################################
## MONITOR CPU AND MOTHERBOARD TEMPERATURES ##
##############################################

hw_mon()
{
    clear

    local found

    # install lm-sensors if not already
    if ! which lm-sensors &>/dev/null; then
        sudo apt-fast -y install lm-sensors
    fi

    # add modprobe to system startup tasks if not already added    
    found="$(grep -o 'drivetemp' '/etc/modules')"
    if [ -z "$found" ]; then
        echo 'drivetemp' | sudo tee -a '/etc/modules'
    else
        sudo modprobe drivetemp
    fi

    sudo watch -n1 sensors
}

###################
## 7ZIP COMMANDS ##
###################

# create a max compressed settings tar.gz file
7z_gz()
{
    clear

    local spath dpath

    read -p 'Please enter the source folder path: ' spath
    echo
    read -p 'Please enter the destination archive path (w/o extension): ' dpath
    clear

    if [ ! -f "$dpath".tar.gz ]; then
        7z a -ttar -so -an "$spath" | 7z a -mx9 -mpass1 -si "$dpath".tar.gz
    else
        clear
        printf "%s\n\n%s\n\n" \
        'The output file already exists.' \
        'Please choose another output name or delete the file.'
    fi
}

# create a max compressed settings 7z file
7z_7z()
{
    clear

    local spath dpath

    read -p 'Please enter the source folder path: ' spath
    echo
    read -p 'Please enter the destination archive path (w/o extension): ' dpath
    clear

    if [ ! -f "$dpath".tar.gz ]; then
        7z a -t7z -m0=lzma2 -mx9 "$dpath".7z ./"$spath"/*
    else
        clear
        printf "%s\n\n%s\n\n" \
        'The output file already exists.' \
        'Please choose another output name or delete the file.'
    fi
}

#####################
## FFMPEG COMMANDS ##
#####################

ffr() { bash "$1" -b --latest --enable-gpl-and-non-free; }
ffrv() { bash -v "$1" -b --latest --enable-gpl-and-non-free; }

###################
## WRITE CACHING ##
###################

wcache()
{
    clear

    local drive_choice

    lsblk
    echo
    read -p 'Enter the drive id to turn off write cacheing (/dev/sdX w/o /dev/): ' drive_choice

    sudo hdparm -W 0 /dev/"$drive_choice"
}

##################
## TAR COMMANDS ##
##################

tar_gz()
{
    clear

    local spath dpath

    read -p 'Please enter the source folder path: ' spath
    echo
    read -p 'Please enter the destination archive path (w/o extension): ' dpath
    clear

    if [ ! -f "$dpath".tar.gz ]; then
        tar -cvJf "$spath" "$dpath".tar.gz
    else
        clear
        printf "%s\n\n%s\n\n" \
        'The output file already exists.' \
        'Please choose another output name or delete the file.'
    fi
}

tar_bz2()
{
    clear

    local spath dpath

    read -p 'Please enter the source folder path: ' spath
    echo
    read -p 'Please enter the destination archive path (w/o extension): ' dpath
    clear

    if [ ! -f "$dpath".tar.bz2 ]; then
        tar -cvjf "$spath" "$dpath".tar.bz2
    else
        clear
        printf "%s\n\n%s\n\n" \
        'The output file already exists.' \
        'Please choose another output name or delete the file.'
    fi
}

tar_xz()
{
    clear

    local spath dpath

    read -p 'Please enter the source folder path: ' spath
    echo
    read -p 'Please enter the destination archive path (w/o extension): ' dpath
    clear

    if [ ! -f "$dpath".tar.xz ]; then
        tar -cvf - "$spath" | xz -9 -c - > "$dpath".tar.xz
    else
        clear
        printf "%s\n\n%s\n\n" \
        'The output file already exists.' \
        'Please choose another output name or delete the file.'
    fi
}

# GET LIST OF PACKAGES BY IMPORTANCE
list_optional() { clear; dpkg-query -Wf '${Package;-40}${Priority}\n' | sort -b -k2,2 -k1,1; }
