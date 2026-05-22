#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACE_YAML="$ROOT_DIR/docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.yml"
TRACE_MD="$ROOT_DIR/docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.md"
STATE_MD="$ROOT_DIR/docs/08-desarrollo-con-ia/ESTADO_PASOS.md"

ruby - "$TRACE_YAML" "$TRACE_MD" "$STATE_MD" <<'RUBY'
require "yaml"
require "time"

trace_path, trace_md_path, state_path = ARGV
trace = YAML.load_file(trace_path)
relations = trace.fetch("relations")

def split_row(line)
  line.strip.sub(/^\|/, "").sub(/\|$/, "").split("|").map { |c| c.strip }
end

def table_row(cells)
  "| #{cells.join(" | ")} |"
end

state_lines = File.exist?(state_path) ? File.readlines(state_path, chomp: true) : []
state_by_step = {}
state_lines.each do |line|
  next unless line.start_with?("| PASO_")
  cells = split_row(line)
  state_by_step[cells[0]] = {
    "Estado" => cells[1] || "-",
    "Equipo" => cells[2] || "-",
    "Avance" => cells[3] || "-",
    "Responsable" => cells[4] || "-",
    "Ultimo commit/rama" => cells[5] || "-",
    "Bloqueos" => cells[6] || "-",
    "Proxima accion" => cells[7] || "-"
  }
end

relations_by_step = relations.group_by { |r| r["paso_id"] }

new_state_lines = []
inside_steps_table = false
state_lines.each do |line|
  if line.start_with?("| Paso | Estado | Equipo | Avance | Responsable | Ultimo commit/rama | Bloqueos | Proxima accion |") ||
     line.start_with?("| Paso | HU | Issue HU | Epica | Requerido para Done | Estado | Equipo | Avance | Responsable | Ultimo commit/rama | Bloqueos | Proxima accion |")
    inside_steps_table = true
    new_state_lines << table_row(["Paso", "HU", "Issue HU", "Epica", "Requerido para Done", "Estado", "Equipo", "Avance", "Responsable", "Ultimo commit/rama", "Bloqueos", "Proxima accion"])
    next
  end

  if inside_steps_table && line.start_with?("|---")
    new_state_lines << table_row(["---", "---", "---", "---", "---", "---", "---", "---:", "---", "---", "---", "---"])
    next
  end

  if inside_steps_table && line.start_with?("| PASO_")
    cells = split_row(line)
    if cells.length >= 12
      paso_id, _hu, _issue, _epic, _required, estado, equipo, avance, responsable, commit, bloqueos, accion = cells
    else
      paso_id, estado, equipo, avance, responsable, commit, bloqueos, accion = cells
    end
    step_relations = relations_by_step.fetch(paso_id, [])
    hu_values = step_relations.map { |r| r["hu_id"] || "sin HU directa" }.uniq.join("<br>")
    issue_values = step_relations.map { |r| r["hu_issue_number"] ? "##{r["hu_issue_number"]}" : "pendiente" }.uniq.join("<br>")
    epic_values = step_relations.map { |r| r["epic_id"] || "-" }.uniq.join("<br>")
    required_values = step_relations.any? { |r| r["required_for_hu_done"] } ? "Si" : "No"
    new_state_lines << table_row([paso_id, hu_values, issue_values, epic_values, required_values, estado, equipo, avance, responsable, commit, bloqueos, accion])
    next
  end

  if inside_steps_table && line.start_with?("## ")
    inside_steps_table = false
  end

  new_state_lines << line
end

File.write(state_path, new_state_lines.join("\n") + "\n")

state_by_step = {}
File.readlines(state_path, chomp: true).each do |line|
  next unless line.start_with?("| PASO_")
  cells = split_row(line)
  state_by_step[cells[0]] = cells[5] || "-"
end

def projected_project_status(hu_id, relations, state_by_step)
  required = relations.select { |r| r["hu_id"] == hu_id && r["required_for_hu_done"] }
  return "-" if hu_id.nil? || required.empty?
  statuses = required.map { |r| state_by_step.fetch(r["paso_id"], "TODO") }
  return "Done" if statuses.all? { |s| s == "DONE" }
  return "En progreso" if statuses.any? { |s| ["IN_PROGRESS", "REVIEW", "PAUSED"].include?(s) }
  return "Blocked" if statuses.any? { |s| s == "BLOCKED" }
  "Pendiente"
end

groups = relations.group_by { |r| [r["epic_id"] || "SIN_EPICA", r["epic_title"] || "Sin epica"] }
generated_at = Time.now.strftime("%Y-%m-%d %H:%M")

md = []
md << "# Trazabilidad PASOS - HU - Epicas - GitHub Project"
md << ""
md << "Este archivo es la vista humana de `TRAZABILIDAD_PASOS_HU.yml`. El YAML es la fuente de verdad para agentes y scripts."
md << ""
md << "Generado/actualizado: #{generated_at}"
md << ""
md << "## Regla de cierre"
md << ""
md << "Una HU o TT puede pasar a `Done` en GitHub Projects solo cuando todos sus pasos con `required_for_hu_done: true` estan `DONE` y verificados."
md << ""
md << "Los pasos smoke o gates pueden figurar como `sin HU directa`; validan integracion, pero no cierran una HU por si solos."
md << ""

groups.sort_by { |(epic_id, _), _rels| epic_id }.each do |(epic_id, epic_title), rels|
  md << "## #{epic_id} - #{epic_title}"
  md << ""
  md << "| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |"
  md << "|---|---|---:|---|---|---|---|---|"
  rels.sort_by { |r| [r["hu_id"] || "ZZZ", r["paso_id"]] }.each do |r|
    hu = r["hu_id"] ? "#{r["hu_id"]} - #{r["hu_title"]}" : r["hu_title"]
    issue = r["hu_issue_number"] ? "##{r["hu_issue_number"]}" : "pendiente"
    required = r["required_for_hu_done"] ? "Si" : "No"
    status = state_by_step.fetch(r["paso_id"], "-")
    project_status = projected_project_status(r["hu_id"], relations, state_by_step)
    md << table_row([r["epic_id"] || "-", hu, issue, r["paso_id"], required, status, project_status, r["contribution"] || "-"])
  end
  md << ""
end

File.write(trace_md_path, md.join("\n"))
RUBY

echo "Traceability docs generated:"
echo "  - docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.md"
echo "  - docs/08-desarrollo-con-ia/ESTADO_PASOS.md"
