#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACE_YAML="$ROOT_DIR/docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.yml"
STATE_MD="$ROOT_DIR/docs/08-desarrollo-con-ia/ESTADO_PASOS.md"
HISTORY_MD="$ROOT_DIR/docs/08-desarrollo-con-ia/HISTORIAL_PASOS.md"
GENERATOR="$ROOT_DIR/scripts/generate-traceability-docs.sh"

if [ $# -lt 1 ]; then
  echo "Uso: $0 PASO_Sxx_xx [--dry-run] [--no-github]" >&2
  exit 2
fi

PASO_ID="$1"
DRY_RUN=false
NO_GITHUB=false
shift || true

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-github) NO_GITHUB=true ;;
    *) echo "Argumento desconocido: $arg" >&2; exit 2 ;;
  esac
done

eval "$(
  ruby - "$TRACE_YAML" "$PASO_ID" <<'RUBY'
require "yaml"
require "shellwords"

trace_path, paso_id = ARGV
trace = YAML.load_file(trace_path)
rels = trace.fetch("relations").select { |r| r["paso_id"] == paso_id }
abort "ERROR: #{paso_id} no tiene relaciones en TRAZABILIDAD_PASOS_HU.yml" if rels.empty?

project = trace.fetch("github_project")
repo = trace.fetch("repo")
owner = project.fetch("owner")
number = ENV["GH_PROJECT_NUMBER"] || project["number"]
number = "" if number.nil?
status_field = project.fetch("status_field")
in_progress = project.fetch("in_progress_status")
blocked = project.fetch("blocked_status")
done = project.fetch("done_status")

issue_numbers = rels
  .select { |r| r["github_sync"] == true && r["hu_issue_number"] }
  .map { |r| r["hu_issue_number"].to_s }
  .uniq

hu_labels = rels.map { |r| r["hu_id"] || "sin HU directa" }.uniq.join(", ")

puts "REPO=#{Shellwords.escape(repo)}"
puts "PROJECT_OWNER=#{Shellwords.escape(owner)}"
puts "PROJECT_NUMBER=#{Shellwords.escape(number.to_s)}"
puts "STATUS_FIELD=#{Shellwords.escape(status_field)}"
puts "STATUS_IN_PROGRESS=#{Shellwords.escape(in_progress)}"
puts "STATUS_BLOCKED=#{Shellwords.escape(blocked)}"
puts "STATUS_DONE=#{Shellwords.escape(done)}"
puts "RELATED_ISSUES=#{Shellwords.escape(issue_numbers.join(" "))}"
puts "RELATED_HUS=#{Shellwords.escape(hu_labels)}"
RUBY
)"

set_project_status() {
  local issue_number="$1"
  local status_name="$2"

  if [ "$NO_GITHUB" = true ]; then
    echo "GitHub skip (--no-github): issue #$issue_number -> $status_name"
    return 0
  fi

  if [ -z "${PROJECT_NUMBER:-}" ] || [ "$PROJECT_NUMBER" = "null" ]; then
    echo "GitHub skip: falta GH_PROJECT_NUMBER o github_project.number en TRAZABILIDAD_PASOS_HU.yml"
    return 0
  fi

  if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub skip: gh CLI no esta disponible"
    return 0
  fi

  local project_id field_id option_id item_id
  project_id="$(gh project view "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --jq '.id' 2>/dev/null || true)"
  field_id="$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --jq ".fields[] | select(.name == \"$STATUS_FIELD\") | .id" 2>/dev/null || true)"
  option_id="$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --jq ".fields[] | select(.name == \"$STATUS_FIELD\") | .options[]? | select(.name == \"$status_name\") | .id" 2>/dev/null || true)"
  item_id="$(gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --limit 1000 --format json --jq ".items[] | select(.content.number == $issue_number) | .id" 2>/dev/null || true)"

  if [ -z "$project_id" ] || [ -z "$field_id" ] || [ -z "$option_id" ] || [ -z "$item_id" ]; then
    echo "GitHub skip: no pude resolver Project/item/campo para issue #$issue_number -> $status_name"
    return 0
  fi

  gh project item-edit \
    --project-id "$project_id" \
    --id "$item_id" \
    --field-id "$field_id" \
    --single-select-option-id "$option_id" >/dev/null
  echo "GitHub Project: issue #$issue_number -> $status_name"
}

comment_issue() {
  local issue_number="$1"
  local body="$2"

  if [ "$NO_GITHUB" = true ] || ! command -v gh >/dev/null 2>&1; then
    return 0
  fi

  gh issue comment "$issue_number" --repo "$REPO" --body "$body" >/dev/null 2>&1 || true
}

echo "Paso: $PASO_ID"
echo "HU/TT relacionadas: $RELATED_HUS"

if [ "$DRY_RUN" = true ]; then
  echo
  echo "Dry-run: no se actualiza ESTADO_PASOS.md, HISTORIAL_PASOS.md ni GitHub Project."
  bash "$ROOT_DIR/scripts/verify_paso.sh" "$PASO_ID" --dry-run
  exit 0
fi

for issue in $RELATED_ISSUES; do
  set_project_status "$issue" "$STATUS_IN_PROGRESS"
done

set +e
(cd "$ROOT_DIR" && bash "$ROOT_DIR/scripts/verify_paso.sh" "$PASO_ID")
VERIFY_EXIT=$?
set -e

if [ "$VERIFY_EXIT" -eq 0 ]; then
  NEW_STEP_STATUS="DONE"
  RESULT="PASS"
  PROJECT_TARGET_STATUS="$STATUS_DONE"
else
  NEW_STEP_STATUS="BLOCKED"
  RESULT="FAIL"
  PROJECT_TARGET_STATUS="$STATUS_BLOCKED"
fi

READY_ISSUES="$(
  ruby - "$TRACE_YAML" "$STATE_MD" "$HISTORY_MD" "$PASO_ID" "$NEW_STEP_STATUS" "$RESULT" "$PROJECT_TARGET_STATUS" <<'RUBY'
require "yaml"
require "time"

trace_path, state_path, history_path, paso_id, new_status, result, project_target_status = ARGV
trace = YAML.load_file(trace_path)
relations = trace.fetch("relations")
rels = relations.select { |r| r["paso_id"] == paso_id }

def split_row(line)
  line.strip.sub(/^\|/, "").sub(/\|$/, "").split("|").map { |c| c.strip }
end

def table_row(cells)
  "| #{cells.join(" | ")} |"
end

previous_status = "-"
lines = File.readlines(state_path, chomp: true)
updated = lines.map do |line|
  if line.start_with?("| #{paso_id} |")
    cells = split_row(line)
    if cells.length >= 12
      previous_status = cells[5]
      cells[5] = new_status
    else
      previous_status = cells[1]
      cells[1] = new_status
    end
    table_row(cells)
  else
    line
  end
end
File.write(state_path, updated.join("\n") + "\n")

hu_ids = rels.map { |r| r["hu_id"] || "sin HU directa" }.uniq
issue_numbers = rels.map { |r| r["hu_issue_number"] ? "##{r["hu_issue_number"]}" : "pendiente" }.uniq
timestamp = Time.now.strftime("%Y-%m-%d %H:%M")
entry = []
entry << ""
entry << "### #{timestamp} - #{paso_id} - #{new_status}"
entry << ""
entry << "- Responsable: Agente"
entry << "- HU afectadas: #{hu_ids.join(", ")}"
entry << "- Issue HU: #{issue_numbers.join(", ")}"
entry << "- Estado anterior: #{previous_status}"
entry << "- Estado nuevo: #{new_status}"
entry << "- Project status anterior: En progreso"
entry << "- Project status nuevo: #{project_target_status}"
entry << "- Rama/commit: pendiente de registrar"
entry << "- Archivos tocados:"
entry << "  - pendiente de completar por el agente"
entry << "- Avance real:"
entry << "  - Cierre operativo ejecutado por scripts/agent-complete-paso.sh"
entry << "- Checks ejecutados:"
entry << "  - ./scripts/verify_paso.sh #{paso_id} -> #{result}"
entry << "- Evidencia de verificacion:"
entry << "  - Resultado automatizado: #{result}"
entry << "- Bloqueos:"
entry << "  - #{result == "PASS" ? "ninguno" : "ver salida de verify_paso.sh"}"
entry << "- Proxima accion:"
entry << "  - #{result == "PASS" ? "revisar dependencias desbloqueadas y continuar con el siguiente paso" : "corregir checks fallidos antes de reintentar cierre"}"

File.open(history_path, "a") { |file| file.puts(entry.join("\n")) }

state_by_step = {}
File.readlines(state_path, chomp: true).each do |line|
  next unless line.start_with?("| PASO_")
  cells = split_row(line)
  state_by_step[cells[0]] = cells.length >= 12 ? cells[5] : cells[1]
end

ready_issues = []
relations.group_by { |r| r["hu_id"] }.each do |hu_id, hu_rels|
  next if hu_id.nil?
  next unless hu_rels.any? { |r| r["paso_id"] == paso_id }
  required = hu_rels.select { |r| r["required_for_hu_done"] }
  next unless required.any?
  next unless required.all? { |r| state_by_step[r["paso_id"]] == "DONE" }
  synced = hu_rels.find { |r| r["github_sync"] == true && r["hu_issue_number"] }
  ready_issues << synced["hu_issue_number"] if synced
end

puts ready_issues.uniq.join(" ")
RUBY
)"

"$GENERATOR" >/dev/null

if [ "$VERIFY_EXIT" -eq 0 ]; then
  for issue in $READY_ISSUES; do
    set_project_status "$issue" "$STATUS_DONE"
    comment_issue "$issue" "Paso $PASO_ID verificado correctamente. Todas las relaciones requeridas para esta HU estan DONE; se actualiza Project Status a $STATUS_DONE."
  done
  echo "Paso $PASO_ID cerrado localmente como DONE."
else
  for issue in $RELATED_ISSUES; do
    set_project_status "$issue" "$STATUS_BLOCKED"
    comment_issue "$issue" "Paso $PASO_ID fallo en verificacion automatizada. Revisar la salida de verify_paso.sh antes de mover esta HU a Done."
  done
  echo "Paso $PASO_ID quedo BLOCKED porque verify_paso.sh fallo." >&2
  exit "$VERIFY_EXIT"
fi
