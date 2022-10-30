#!/bin/bash

if [ ! -d "lib/" ]; then
  curl https://apps.mzstatic.com/content/android-apple-music-apk/applemusic.apk -O
  if [ "$(uname -m)" = 'aarch64' ]; then
    unzip applemusic.apk "lib/arm64-v8a/*"
  elif [[ "$(uname -m)" = 'arm'* ]]; then
    unzip applemusic.apk "lib/armeabi-v7a/*"
  elif [ "$(uname -m)" = 'x86_64' ]; then
    unzip applemusic.apk "lib/x86_64/*"
  elif [ "$(uname -m)" = 'i686' ]; then
    unzip applemusic.apk "lib/x86/*"
  fi
  rm applemusic.apk
fi

chmod +x anisette_server
/opt/anisette_server