#!/bin/sh
set -e

openssl aes-256-cbc -K $ENCRYPTED_F10B5E0E5262_KEY -iv $ENCRYPTED_F10B5E0E5262_IV -in ./scripts/secrets.tar.enc -out ./scripts/secrets.tar -d
tar xvf ./scripts/secrets.tar -C android/