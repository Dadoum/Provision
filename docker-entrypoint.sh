#!/bin/bash

if [ -z "$(ls -A lib/ 2> /dev/null)" ]; then
  curl https://apps.mzstatic.com/content/android-apple-music-apk/applemusic.apk -O
  if [ "$(uname -m)" = 'aarch64' ]; then
    unzip applemusic.apk 'lib/arm64-v8a/libstoreservicescore.so' 'lib/arm64-v8a/libCoreADI.so'
  elif [[ "$(uname -m)" = 'arm'* ]]; then
    unzip applemusic.apk 'lib/armeabi-v7a/libstoreservicescore.so' 'lib/armeabi-v7a/libCoreADI.so'
  elif [ "$(uname -m)" = 'x86_64' ]; then
    unzip applemusic.apk 'lib/x86_64/libstoreservicescore.so' 'lib/x86_64/libCoreADI.so'
  elif [ "$(uname -m)" = 'i686' ]; then
    unzip applemusic.apk 'lib/x86/libstoreservicescore.so' 'lib/x86/libCoreADI.so'
  fi
  rm applemusic.apk
fi

/opt/anisette_server
