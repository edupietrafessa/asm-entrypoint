#!/usr/bin/env bash

set -euo pipefail

output_dir="${1:-solana-llvm}"

output_dir=$(pwd)/solana-llvm
llvm_dir=$output_dir/llvm

if [[ -L $llvm_dir || -d $llvm_dir ]]; then
  echo "✅ Solana platform tools already present in directory"
  exit 0
fi

cleanup() {
  rm -rf $output_dir
}
trap cleanup ERR

config_path="$HOME/.config/solana/install/config.yml"

if [[ ! -f "$config_path" ]]; then
  echo "❌ Solana config not found. Please install the Solana CLI:"
  echo "https://docs.anza.xyz/cli/install"
  exit 1
fi

active_release_dir=$(grep '^active_release_dir:' $config_path | sed 's/^active_release_dir:[[:space:]]*//')
local_llvm_dir=$active_release_dir/bin/platform-tools-sdk/sbf/dependencies/platform-tools/llvm

mkdir -p $llvm_dir

if [[ -d $local_llvm_dir ]]; then
  ln -s $local_llvm_dir $llvm_dir
  echo "✅ Solana platform tools already installed. Symlink created."
  exit 0
fi

cd $output_dir

solana_tools_version="${SOLANA_TOOLS_VERSION:-v1.43}"
release_url="https://github.com/anza-xyz/platform-tools/releases/download/$solana_tools_version"

arch=$(uname -m)
if [[ "$arch" == "arm64" ]]; then
  arch="aarch64"
fi
case $(uname -s | cut -c1-7) in
"Linux")
  os="linux"
  ;;
"Darwin")
  os="osx"
  ;;
"Windows" | "MINGW64")
  os="windows"
  ;;
*)
  echo "install-solana-llvm.sh: Unknown OS $(uname -s)" >&2
  exit 1
  ;;
esac

solana_llvm_tar=platform-tools-$os-$arch.tar.bz2
url="$release_url/$solana_llvm_tar"

echo "⚠️ Solana platform-tools not found. Downloading from source $url"
curl --proto '=https' --tlsv1.2 -SfOL "$url"

echo "Unpacking $solana_llvm_tar"
tar -xjf $solana_llvm_tar
rm $solana_llvm_tar

echo "✅ solana-llvm tools available at $output_dir"
