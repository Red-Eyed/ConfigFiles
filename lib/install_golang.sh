#!/usr/bin/env bash

GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -n 1)
curl -fsSL https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go.tar.gz
rm -rf "$HOME/.local/go" && mkdir -p "$HOME/.local"
tar -C "$HOME/.local" -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

ln -s "$HOME/.local/go/bin/go" "$HOME/.local/bin/"
ln -s "$HOME/.local/go/bin/gofmt" "$HOME/.local/bin/"
