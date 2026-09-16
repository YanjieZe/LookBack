#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build.noindex
xcrun swiftc Sources/DwellTrigger.swift Sources/HeadTurnTrigger.swift Tests/main.swift -o .build.noindex/TriggerTests
.build.noindex/TriggerTests
