#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-d]
Build current Counter-Strike 1.6 modpack.
Available options:
-h, --help             Print this help and exit
-v, --verbose          Print script debug information
-d, --clean            Clean build environment
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # Default exit status 1.
  msg "$msg"
  exit "$code"
}

parse_params() {
  clean=false
  
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    -d | --clean) clean=true ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}

parse_params "$@"

MODPACK_NAME=cs_women_pack_various.zip
CSTRIKE_ADDON_DIRECTORY=cstrike_addon
CACHE_DIRECTORY=cache
MOD_LIST_FILE=mods.txt
CHECKSUMS_FILE=checksums.txt
PLAYER_MODELS_PATH=$CSTRIKE_ADDON_DIRECTORY/models/player
SOUND_PATH=$CSTRIKE_ADDON_DIRECTORY/sound
DOWNLOAD_TRIES=64
DOWNLOAD_DELAY=16
RETRY_ON_ERROR=502
INITIAL_DIRECTORIES="$SOUND_PATH/player $SOUND_PATH/radio/bot $PLAYER_MODELS_PATH/guerilla/ $PLAYER_MODELS_PATH/arctic/"
TRASH_DIRECTORIES="$CSTRIKE_ADDON_DIRECTORY/models/player/gign/Readme.txt $CSTRIKE_ADDON_DIRECTORY/models/player/gsg9/credits.txt $CSTRIKE_ADDON_DIRECTORY/models/player/leet/buffclass22s3tr.tga $CSTRIKE_ADDON_DIRECTORY/models/player/gsg9/DOA_Amy_Gal_Outfit_cs1.6/ $CSTRIKE_ADDON_DIRECTORY/models/player/terror/Angelina/ $CSTRIKE_ADDON_DIRECTORY/models/player/sas/Fey"
MODS=(2b sf2_snow_white sf2_sakura cso_fey smile_mary doa_amy cso_loadout cso_female_voices cso_angelina cso2_female_bot_voices csnz_yuri csnz_mei)
MODELS=(vip vip_t urban urban_t sas leet gsg9 guns_v female_sounds_player female_sounds_radio terror female_sounds_bots guerilla arctic)

declare -A source=(
  [2b]=$CACHE_DIRECTORY/yorha_2b.rar
  [sf2_snow_white]=$CACHE_DIRECTORY/special_force_2_snow_white.rar
  [sf2_sakura]=$CACHE_DIRECTORY/special_force_2_sakura.rar
  [cso_fey]=$CACHE_DIRECTORY/cso_fey.zip
  [smile_mary]=$CACHE_DIRECTORY/smile_mary.rar
  [doa_amy]=$CACHE_DIRECTORY/doa_amy_gal_outfit_cs16.zip
  [cso_loadout]=$CACHE_DIRECTORY/cso-full-loadout-redux.rar
  [cso_female_voices]=$CACHE_DIRECTORY/cso_female_voice.rar
  [cso_angelina]=$CACHE_DIRECTORY/cso_angelina_be3a9.zip
  [cso2_female_bot_voices]=$CACHE_DIRECTORY/cso2_female_bot_voice.rar
  [csnz_yuri]=$CACHE_DIRECTORY/buffclass23s1tr.zip
  [csnz_mei]=$CACHE_DIRECTORY/buffclass23s1ct.zip
  [vip]=$CSTRIKE_ADDON_DIRECTORY/models/player/vip/leet.mdl
  [vip_t]=$CSTRIKE_ADDON_DIRECTORY/models/player/vip/leetT.mdl
  [urban]=$CSTRIKE_ADDON_DIRECTORY/models/player/urban/gsg9.mdl
  [urban_t]=$CSTRIKE_ADDON_DIRECTORY/models/player/urban/gsg9T.mdl
  [sas]=$CSTRIKE_ADDON_DIRECTORY/models/player/sas/Fey/model/buffclass23s5tr.mdl
  [leet]=$CSTRIKE_ADDON_DIRECTORY/models/player/leet/buffclass22s3tr.mdl
  [gsg9]=$CSTRIKE_ADDON_DIRECTORY/models/player/gsg9/DOA_Amy_Gal_Outfit_cs1.6/DOA_Amy_Gal_Outfit_cs1.6.mdl
  [guns_v]=$CACHE_DIRECTORY/cso-full-loadout-redux/V-Models-Female/*
  [female_sounds_player]=$CACHE_DIRECTORY/cso_female_voice/sound/player/*
  [female_sounds_radio]=$CACHE_DIRECTORY/cso_female_voice/sound/radio/*
  [terror]=$CSTRIKE_ADDON_DIRECTORY/models/player/terror/Angelina/models/buffclass24s2tr.mdl
  [female_sounds_bots]=$CACHE_DIRECTORY/cso2_female_bot_voice/sound/radio/bot/*
  [guerilla]=$CACHE_DIRECTORY/buffclass23s1tr/models/buffclass23s1tr.mdl
  [arctic]=$CACHE_DIRECTORY/buffclass23s1ct/models/buffclass23s1ct.mdl
)

declare -A destination=(
  [2b]=$PLAYER_MODELS_PATH/vip/
  [sf2_snow_white]=$PLAYER_MODELS_PATH/urban/
  [sf2_sakura]=$PLAYER_MODELS_PATH/gign/
  [cso_fey]=$PLAYER_MODELS_PATH/sas/
  [smile_mary]=$PLAYER_MODELS_PATH/leet/
  [doa_amy]=$PLAYER_MODELS_PATH/gsg9/
  [cso_loadout]=$CACHE_DIRECTORY/cso-full-loadout-redux/
  [cso_female_voices]=$CACHE_DIRECTORY/cso_female_voice/
  [cso_angelina]=$PLAYER_MODELS_PATH/terror/
  [cso2_female_bot_voices]=$CACHE_DIRECTORY/cso2_female_bot_voice/
  [csnz_yuri]=$CACHE_DIRECTORY/buffclass23s1tr/
  [csnz_mei]=$CACHE_DIRECTORY/buffclass23s1ct/
  [vip]=$CSTRIKE_ADDON_DIRECTORY/models/player/vip/vip.mdl
  [vip_t]=$CSTRIKE_ADDON_DIRECTORY/models/player/vip/vipT.mdl
  [urban]=$CSTRIKE_ADDON_DIRECTORY/models/player/urban/urban.mdl
  [urban_t]=$CSTRIKE_ADDON_DIRECTORY/models/player/urban/urbanT.mdl
  [sas]=$CSTRIKE_ADDON_DIRECTORY/models/player/sas/sas.mdl
  [leet]=$CSTRIKE_ADDON_DIRECTORY/models/player/leet/leet.mdl
  [gsg9]=$CSTRIKE_ADDON_DIRECTORY/models/player/gsg9/gsg9.mdl
  [guns_v]=$CSTRIKE_ADDON_DIRECTORY/models/
  [female_sounds_player]=$CSTRIKE_ADDON_DIRECTORY/sound/player/
  [female_sounds_radio]=$CSTRIKE_ADDON_DIRECTORY/sound/radio/
  [terror]=$CSTRIKE_ADDON_DIRECTORY/models/player/terror/terror.mdl
  [female_sounds_bots]=$CSTRIKE_ADDON_DIRECTORY/sound/radio/bot/
  [guerilla]=$CSTRIKE_ADDON_DIRECTORY/models/player/guerilla/guerilla.mdl
  [arctic]=$CSTRIKE_ADDON_DIRECTORY/models/player/arctic/arctic.mdl
)

if [ "$clean" = true ]; then
  # Clean build.
  rm -rf $CSTRIKE_ADDON_DIRECTORY/ $CACHE_DIRECTORY/ $MODPACK_NAME
fi

# Directories.
for directory in $INITIAL_DIRECTORIES; do
  if [ ! -d "$directory" ]; then
    echo "Creating directory: $directory"
    mkdir -p $directory
  else
    echo "Directory already exists: $directory"
  fi
done

# Download.
wget --content-disposition --wait $DOWNLOAD_DELAY -t $DOWNLOAD_TRIES --retry-on-http-error=$RETRY_ON_ERROR -i $MOD_LIST_FILE -P $CACHE_DIRECTORY

# Check.
md5sum -c $CHECKSUMS_FILE

# Extract.
for mod in "${MODS[@]}"; do
  if [ "$mod" = "doa_amy" ] || [ "$mod" = "cso_angelina" ] || [ "$mod" = "csnz_yuri" ] || [ "$mod" = "csnz_mei" ] || [ "$mod" = "cso_fey" ]; then
    unzip ${source[$mod]} -d ${destination[$mod]}
  else
    unrar x ${source[$mod]} ${destination[$mod]}
  fi
done

# Move.
for model in "${MODELS[@]}"; do
  mv ${source[$model]} ${destination[$model]}
done

# Delete.
for directory in $TRASH_DIRECTORIES; do
  if [ -e "$directory" ]; then
    echo "Deleting directory: $directory"
    rm -rf $directory
  else
    echo "Directory already deleted: $directory"
  fi
done

# List.
cp README.md $CSTRIKE_ADDON_DIRECTORY/

# Package.
zip -9 -r $MODPACK_NAME $CSTRIKE_ADDON_DIRECTORY/

