#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACE_YAML="$ROOT_DIR/docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.yml"
STATE_MD="$ROOT_DIR/docs/08-desarrollo-con-ia/ESTADO_PASOS.md"
BACKLOG_CSV="$ROOT_DIR/docs/02-planificacion/01_backlog/epicas_y_user_stories.csv"
PASOS_DIR="$ROOT_DIR/docs/08-desarrollo-con-ia/pasos"

ruby - "$TRACE_YAML" "$STATE_MD" "$BACKLOG_CSV" "$PASOS_DIR" "$ROOT_DIR" <<'RUBY'
require "yaml"
require "csv"
require "set"

trace_path, state_path, backlog_path, pasos_dir, root_dir = ARGV
errors = []
warnings = []

trace = YAML.load_file(trace_path)
relations = trace.fetch("relations")

paso_files = Dir[File.join(pasos_dir, "PASO_*.md")]
  .reject { |path| File.basename(path) == "PASO_TEMPLATE.md" }
pasos_on_disk = paso_files.map { |path| File.basename(path, ".md") }.sort
pasos_in_yaml = relations.map { |r| r["paso_id"] }.uniq.sort

missing_in_yaml = pasos_on_disk - pasos_in_yaml
missing_on_disk = pasos_in_yaml - pasos_on_disk
errors << "PASOS sin relacion en YAML: #{missing_in_yaml.join(", ")}" unless missing_in_yaml.empty?
errors << "PASOS en YAML sin archivo local: #{missing_on_disk.join(", ")}" unless missing_on_disk.empty?

relations.each do |r|
  paso_file = File.join(root_dir, r.fetch("paso_file"))
  errors << "#{r["paso_id"]}: paso_file no existe: #{r["paso_file"]}" unless File.exist?(paso_file)
end

csv_rows = CSV.read(backlog_path, headers: true)
known_story_ids = csv_rows.map { |row| row["Story ID"] }.compact.to_set
known_epic_ids = csv_rows.map { |row| row["Epic ID"] }.compact.to_set

relations.each do |r|
  hu_id = r["hu_id"]
  epic_id = r["epic_id"]
  errors << "#{r["paso_id"]}: hu_id inexistente en CSV: #{hu_id}" if hu_id && !known_story_ids.include?(hu_id)
  errors << "#{r["paso_id"]}: epic_id inexistente en CSV: #{epic_id}" if epic_id && !known_epic_ids.include?(epic_id)
  if r["github_sync"] == true && r["hu_issue_number"].nil?
    errors << "#{r["paso_id"]}/#{hu_id}: github_sync=true requiere hu_issue_number"
  end
end

def split_row(line)
  line.strip.sub(/^\|/, "").sub(/\|$/, "").split("|").map { |c| c.strip }
end

state_by_step = {}
trace_cols_by_step = {}
File.readlines(state_path, chomp: true).each do |line|
  next unless line.start_with?("| PASO_")
  cells = split_row(line)
  if cells.length >= 12
    paso_id, hu, issue, epic, required, status = cells[0], cells[1], cells[2], cells[3], cells[4], cells[5]
    trace_cols_by_step[paso_id] = { hu: hu, issue: issue, epic: epic, required: required }
    state_by_step[paso_id] = status
  else
    paso_id, status = cells[0], cells[1]
    state_by_step[paso_id] = status
    warnings << "#{paso_id}: ESTADO_PASOS.md todavia no tiene columnas de trazabilidad"
  end
end

pasos_in_yaml.each do |paso_id|
  errors << "#{paso_id}: no aparece en ESTADO_PASOS.md" unless state_by_step.key?(paso_id)
end

relations.group_by { |r| r["paso_id"] }.each do |paso_id, rels|
  next unless trace_cols_by_step[paso_id]
  expected_hus = rels.map { |r| r["hu_id"] || "sin HU directa" }.uniq.sort
  expected_epics = rels.map { |r| r["epic_id"] || "-" }.uniq.sort
  actual_hus = trace_cols_by_step[paso_id][:hu].split("<br>").sort
  actual_epics = trace_cols_by_step[paso_id][:epic].split("<br>").sort
  errors << "#{paso_id}: HU en ESTADO_PASOS.md no coincide con YAML" unless actual_hus == expected_hus
  errors << "#{paso_id}: Epica en ESTADO_PASOS.md no coincide con YAML" unless actual_epics == expected_epics
end

done_status = trace.dig("github_project", "done_status") || "Done"
relations.group_by { |r| r["hu_id"] }.each do |hu_id, rels|
  next if hu_id.nil?
  required = rels.select { |r| r["required_for_hu_done"] }
  next if required.empty?
  required_statuses = required.map { |r| state_by_step.fetch(r["paso_id"], "TODO") }
  hu_local_done = rels.any? { |r| r["hu_project_status"] == done_status }
  if hu_local_done && !required_statuses.all? { |status| status == "DONE" }
    errors << "#{hu_id}: figura #{done_status} pero tiene pasos requeridos sin DONE"
  end
end

if warnings.any?
  puts "Warnings:"
  warnings.uniq.each { |warning| puts "  - #{warning}" }
  puts
end

if errors.any?
  warn "Traceability validation failed:"
  errors.uniq.each { |error| warn "  - #{error}" }
  exit 1
end

puts "Traceability validation passed."
RUBY
