#!/usr/bin/env bash
# shellcheck disable=SC2066,SC2068,SC2086,SC2162

clear

sudo apt -y install trash-cli
clear

#
# SET THE PATH VARIABLE
#

if [ -d "${HOME}/.local/bin" ]; then
    export PATH="${PATH}:${HOME}/.local/bin"
fi

if [ -f 'list.txt' ]; then
    sudo rm 'list.txt'
fi

cat > 'list.txt' <<'EOF'
/path/to/video/video.mp4
/path/to/video/video.mkv
EOF

while read -u 9 video
do
    # STORES THE CURRENT VIDEO WIDTH, ASPECT RATIO, PROFILE, BIT RATE, AND TOTAL DURATION IN VARIABLES FOR USE LATER IN THE FFMPEG COMMAND LINE
    aratio="$(ffprobe -hide_banner -select_streams v:0 -show_entries stream=display_aspect_ratio -of default=nk=1:nw=1 -pretty "${video}" 2>/dev/null)"
    length="$(ffprobe -hide_banner -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${video}" 2>/dev/null)"
    maxrate="$(ffprobe -hide_banner -show_entries format=bit_rate -of default=nk=1:nw=1 -pretty "${video}" 2>/dev/null)"
    height="$(ffprobe -hide_banner -select_streams v:0 -show_entries stream=height -of csv=s=x:p=0 -pretty "${video}" 2>/dev/null)"
    width="$(ffprobe -hide_banner -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 -pretty "${video}" 2>/dev/null)"

    # MODIFY VARS TO GET FILE INPUT AND OUTPUT NAMES
    file_in="${video}"
    fext="${video#*.}"
    file_out="${video%.*} (x265).${fext}"

    # GETS THE INPUT VIDEOS MAX DATARATE AND APPLIES LOGIC TO DETERMINE bitrate, bufsize, AND MAXRATE VARIABLES
    trim="$(bc <<< "scale=2 ; ${maxrate::-11} * 1000")"
    btr="$(bc <<< "scale=2 ; ${trim} / 2")"
    bitrate="${btr::-3}"
    maxrate="$(( bitrate * 3 ))"
    bfs="$(bc <<< "scale=2 ; ${btr} * 2")"
    bufsize="${bfs::-3}"
    length="$(( ${length::-7} / 60 ))"

    #
    # PRINT THE VIDEO STATS IN THE TERMINAL
    #

    cat <<EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Working Dir:     ${PWD}

Input File:      ${file_in}
Output File:     ${file_out}

Aspect Ratio:    ${aratio}
Dimensions:      ${width}x${height}

Maxrate:         ${maxrate}k
Bufsize:         ${bufsize}k
Bitrate:         ${bitrate}k

Length:          ${length} mins

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
EOF

    #
    # EXECUTE FFMPEG
    #

    echo
    if ffmpeg \
            -y \
            -threads 0 \
            -hide_banner \
            -hwaccel_output_format cuda \
            -i "${file_in}" \
            -c:v hevc_nvenc \
            -preset:v medium \
            -profile:v main10 \
            -pix_fmt:v p010le \
            -rc:v vbr \
            -tune:v hq \
            -b:v "${bitrate}"k \
            -bufsize:v "${bufsize}"k \
            -maxrate:v "${maxrate}"k \
            -bf:v 4 \
            -b_ref_mode:v middle \
            -qmin:v 0 \
            -qmax:v 99 \
            -temporal-aq:v 1 \
            -rc-lookahead:v 20 \
            -i_qfactor:v 0.75 \
            -b_qfactor:v 1.1 \
            -c:a libfdk_aac \
            -qmin:a 1 \
            -qmax:a 5 \
            "${file_out}"; then
        google_speech 'Video conversion completed.' 2>/dev/null
        if [ -f "${file_out}" ]; then
            trash-put "${file_in}"
        fi
    else
        google_speech 'Video conversion failed.' 2>/dev/null
        echo
        exit 1
    fi
    clear
done 9< 'list.txt'