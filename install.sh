#!/bin/bash

# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Copy battinfo script to ~/.local/bin
cp ./battinfo ~/.local/bin/battinfo

# Make it executable
chmod +x ~/.local/bin/battinfo

echo "battinfo installed successfully!"
