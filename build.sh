#!/bin/sh

nimble build --threads:on --d:release -y
cd assembler
nimble build --d:release -y
cd ..
zip -r lychee-build-linux-x64.zip lychee lychee-cli assembler/lasm docs/ examples/ README.md lychee.png
