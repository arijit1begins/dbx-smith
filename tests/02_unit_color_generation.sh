#!/usr/bin/env bash
# tests/02_unit_color_generation.sh - Fast unit test for color generation logic

set -euo pipefail

echo "Running Color Generation Unit Test..."

# Replicate the logic from dbx-smith-spin
_get_color() {
    local img="$1"
    local hash
    hash=$(echo "$img" | cksum | awk '{print $1}')
    local r=$(( (hash % 61) + 30 ))
    local g=$(( ((hash / 100) % 61) + 30 ))
    local b=$(( ((hash / 10000) % 61) + 30 ))
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

c1=$(_get_color "docker.io/library/alpine")
c2=$(_get_color "fedora:latest")
c3=$(_get_color "ubuntu:22.04")

echo "alpine: $c1"
echo "fedora: $c2"
echo "ubuntu: $c3"

if [[ ! "$c1" =~ ^#[0-9a-f]{6}$ ]]; then
    echo "❌ Error: Invalid color format generated."
    exit 1
fi

echo "✅ Color Generation Test Passed!"
