#!/bin/bash

curl https://apps.mzstatic.com/content/android-apple-music-apk/applemusic.apk -O
unzip applemusic.apk "lib/*"

if [ "$(uname -m)" = 'aarch64' ]; then
  mv lib/arm64-v8a .
  rm -r applemusic.apk lib/*
  mv arm64-v8a lib/
elif [[ "$(uname -m)" = 'arm'* ]]; then
  mv lib/armeabi-v7a .
  rm -r applemusic.apk lib/*
  mv armeabi-v7a lib/
elif [ "$(uname -m)" = 'x86_64' ]; then
  mv lib/x86_64 .
  rm -r applemusic.apk lib/*
  mv x86_64 lib/
elif [ "$(uname -m)" = 'i686' ]; then
  mv lib/x86 .
  rm -r applemusic.apk lib/*
  mv x86 lib/
fi

/opt/anisette_server