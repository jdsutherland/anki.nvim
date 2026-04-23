#!/bin/bash

# Self-installing Git pre-commit hook
HOOK_DIR=$(git rev-parse --git-dir)/hooks
SCRIPT_PATH=$(realpath "$0")
HOOK_PATH="$HOOK_DIR/pre-commit"

if [ ! -L "$HOOK_PATH" ] || [ "$(readlink "$HOOK_PATH")" != "$SCRIPT_PATH" ]; then
  echo "Installing pre-commit hook..."
  # Create hooks directory if it doesn't exist
  mkdir -p "$HOOK_DIR"
  # Create symlink
  ln -sf "$SCRIPT_PATH" "$HOOK_PATH"
  echo "Hook installed."
fi

# Get staged .lua files
STAGED_LUA_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.lua$')
if [ -z "$STAGED_LUA_FILES" ]; then
  exit 0
fi
# Format staged .lua files
echo "$STAGED_LUA_FILES" | xargs /usr/bin/stylua
# Add back the formatted files
echo "$STAGED_LUA_FILES" | xargs git add
