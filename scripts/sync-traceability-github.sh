#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACE_YAML="$ROOT_DIR/docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.yml"
GENERATOR="$ROOT_DIR/scripts/generate-traceability-docs.sh"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) echo "Argumento desconocido: $arg" >&2; exit 2 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI no esta disponible" >&2
  exit 2
fi

REPO="$(ruby -ryaml -e 'puts YAML.load_file(ARGV[0]).fetch("repo")' "$TRACE_YAML")"
ISSUES_JSON="$(gh issue list --repo "$REPO" --state all --limit 1000 --json number,title)"

if [ "$DRY_RUN" = true ]; then
  ruby - "$TRACE_YAML" "$ISSUES_JSON" <<'RUBY'
require "yaml"
require "json"

trace_path, issues_json = ARGV
trace = YAML.load_file(trace_path)
issues = JSON.parse(issues_json)

index = {}
issues.each do |issue|
  if issue["title"] =~ /\[(HU-\d{2}-\d{2}|TT-\d{2}-\d{2}|EPIC-\d{2})\]/
    index[$1] = issue["number"]
  end
end

trace.fetch("relations").each do |r|
  hu = r["hu_id"]
  epic = r["epic_id"]
  puts "#{hu}: issue ##{index[hu]}" if hu && index[hu] && r["hu_issue_number"] != index[hu]
  puts "#{epic}: issue ##{index[epic]}" if epic && index[epic] && r["epic_issue_number"] != index[epic]
end

if ENV["GH_PROJECT_NUMBER"] && !ENV["GH_PROJECT_NUMBER"].empty?
  puts "github_project.number: #{ENV["GH_PROJECT_NUMBER"]}"
end
RUBY
  exit 0
fi

ruby - "$TRACE_YAML" "$ISSUES_JSON" <<'RUBY'
require "yaml"
require "json"

trace_path, issues_json = ARGV
trace = YAML.load_file(trace_path)
issues = JSON.parse(issues_json)

index = {}
issues.each do |issue|
  if issue["title"] =~ /\[(HU-\d{2}-\d{2}|TT-\d{2}-\d{2}|EPIC-\d{2})\]/
    index[$1] = issue["number"]
  end
end

trace.fetch("relations").each do |r|
  hu = r["hu_id"]
  epic = r["epic_id"]
  if hu && index[hu]
    r["hu_issue_number"] = index[hu]
    r["github_sync"] = true
  end
  r["epic_issue_number"] = index[epic] if epic && index[epic]
end

if ENV["GH_PROJECT_NUMBER"] && !ENV["GH_PROJECT_NUMBER"].empty?
  trace.fetch("github_project")["number"] = ENV["GH_PROJECT_NUMBER"].to_i
end

File.write(trace_path, trace.to_yaml)
puts "Traceability issue numbers synchronized."
RUBY

"$GENERATOR"
