#!/bin/sh
# kombify StackKits APT repository setup
# Usage: curl -sSL apt.kombify.io/setup.sh | sudo sh
set -eu

echo "Adding kombify StackKits APT repository..."

# Download and install GPG key
curl -fsSL https://apt.kombify.io/kombify.gpg.key | \
  gpg --dearmor -o /usr/share/keyrings/kombify-stackkits-archive-keyring.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/kombify-stackkits-archive-keyring.gpg] https://apt.kombify.io/ stable main" | \
  tee /etc/apt/sources.list.d/kombify-stackkits.list > /dev/null

# Update package list
apt-get update -o Dir::Etc::sourcelist="sources.list.d/kombify-stackkits.list" \
  -o Dir::Etc::sourceparts="-" \
  -o APT::Get::List-Cleanup="0"

echo ""
echo "Done! Install stackkit with:"
echo "  sudo apt install kombify-stackkits"
