#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
task_tmp=$(mktemp -d "${TMPDIR:-/tmp}/vaquita-migration.XXXXXX")
trap 'rm -rf "$task_tmp"' EXIT
arch=$(uname -m)
xcrun swiftc -target "$arch-apple-macos14.0" -parse-as-library scripts/MigrationLegacy.swift -o "$task_tmp/legacy"
xcrun swiftc -target "$arch-apple-macos14.0" -parse-as-library scripts/MigrationEventsLegacy.swift -o "$task_tmp/events"
xcrun swiftc -target "$arch-apple-macos14.0" -parse-as-library Vaquita/Moneda.swift Vaquita/Dinero.swift Vaquita/Evento.swift Vaquita/Participante.swift Vaquita/Persistencia.swift scripts/MigrationCheck.swift -o "$task_tmp/check"
xcrun swiftc -target "$arch-apple-macos14.0" -parse-as-library scripts/MigrationCentsLegacy.swift -o "$task_tmp/cents"
"$task_tmp/legacy" "$task_tmp/legacy.store"
"$task_tmp/check" "$task_tmp/legacy.store"
"$task_tmp/check" "$task_tmp/legacy.store"
"$task_tmp/events" "$task_tmp/events.store"
"$task_tmp/check" "$task_tmp/events.store" events
"$task_tmp/check" "$task_tmp/events.store" events
"$task_tmp/cents" "$task_tmp/cents.store"
"$task_tmp/check" "$task_tmp/cents.store" cents
"$task_tmp/check" "$task_tmp/cents.store" cents
