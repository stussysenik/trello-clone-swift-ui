#!/bin/bash
set -euo pipefail

echo "🔧 Trello Clone — Project Setup"

# Install xcodegen if not present
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Installing xcodegen via Homebrew…"
    brew install xcodegen
fi

# Generate Xcode project
echo "⚙️  Generating Xcode project…"
xcodegen generate

echo "✅ Project generated successfully!"
echo "🚀 Opening Xcode…"
open TrelloClone.xcodeproj
