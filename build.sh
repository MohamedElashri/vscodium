#!/bin/bash

set -ex

if [[ "$SHOULD_BUILD" == "yes" ]]; then
  npm config set scripts-prepend-node-path true

  echo "MS_COMMIT: ${MS_COMMIT}"

  . prepare_vscode.sh

  cd vscode || exit

  yarn monaco-compile-check
  yarn valid-layers-check

  yarn gulp compile-build
  yarn gulp compile-extension-media
  yarn gulp compile-extensions-build
  yarn gulp minify-vscode

  if [[ "$OS_NAME" == "osx" ]]; then
    npm set npm_config_arch=arm64
    yarn gulp "vscode-darwin-${VSCODE_ARCH}-min-ci"
  elif [[ "$OS_NAME" == "windows" ]]; then
    . ../build/windows/rtf/make.sh
    
    yarn gulp "vscode-win32-${VSCODE_ARCH}-min-ci"
    yarn gulp "vscode-win32-${VSCODE_ARCH}-code-helper"
    yarn gulp "vscode-win32-${VSCODE_ARCH}-inno-updater"
    yarn gulp "vscode-win32-${VSCODE_ARCH}-archive"
    yarn gulp "vscode-win32-${VSCODE_ARCH}-system-setup"
    yarn gulp "vscode-win32-${VSCODE_ARCH}-user-setup"
    
    if [[ "${VSCODE_ARCH}" == "ia32" || "${VSCODE_ARCH}" == "x64" ]]; then
      . ../build/windows/msi/build.sh
      . ../build/windows/msi/build-updates-disabled.sh
    fi
  else # linux
    yarn gulp "vscode-linux-${VSCODE_ARCH}-min-ci"
    if [[ "$SKIP_LINUX_PACKAGES" != "True" ]]; then
      yarn gulp "vscode-linux-${VSCODE_ARCH}-build-deb"
      yarn gulp "vscode-linux-${VSCODE_ARCH}-build-rpm"
      
      . ../build/linux/appimage/build.sh
    fi
  fi

  cd ..
fi
