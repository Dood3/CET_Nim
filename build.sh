#!/bin/bash
# Build script for Command Embedder Tool

echo "Building Command Embedder Tool..."
nim c --out:command_embedder command_embedder.nim

if [ $? -eq 0 ]; then
    echo "Build successful! Run with: ./command_embedder"
else
    echo "Build failed!"
fi
