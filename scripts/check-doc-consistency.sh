#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

errors=0

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  errors=1
}

numbered_files=()
while IFS= read -r file; do
  numbered_files+=("$file")
done < <(
  find 00-front-matter 01-foundations 02-runtime-and-session-start 03-context-and-control 04-interfaces-and-operator-surfaces 05-execution-continuity-and-integrations 06-boundaries-deployment-and-safety 07-evaluation-and-synthesis \
    -type f -name '*.md' ! -name '00-part-guide.md' | sort
)

for file in "${numbered_files[@]}"; do
  base="$(basename "$file")"
  prefix="${base%%-*}"
  if [[ "$prefix" =~ ^[0-9]{2}$ ]]; then
    heading="$(sed -n '1p' "$file")"
    if [[ ! "$heading" =~ ^#\ ${prefix}\. ]]; then
      fail "Heading number mismatch in $file (expected '# ${prefix}.', got '$heading')"
    fi
  fi
done

reader_files=()
while IFS= read -r file; do
  reader_files+=("$file")
done < <(
  {
    printf '%s\n' README.md
    find 00-front-matter 01-foundations 02-runtime-and-session-start 03-context-and-control 04-interfaces-and-operator-surfaces 05-execution-continuity-and-integrations 06-boundaries-deployment-and-safety 07-evaluation-and-synthesis 08-reference \
      -type f -name '*.md' | sort
  } | uniq
)

node - "${reader_files[@]}" <<'NODE'
const fs = require('fs');
const path = require('path');

const root = process.cwd();
const files = process.argv.slice(2);
let hadError = false;

function error(message) {
  console.error(`ERROR: ${message}`);
  hadError = true;
}

for (const relFile of files) {
  const absFile = path.join(root, relFile);
  const text = fs.readFileSync(absFile, 'utf8');
  const mdLinkRegex = /\[[^\]]*\]\(([^)]+)\)/g;
  let match;
  while ((match = mdLinkRegex.exec(text)) !== null) {
    const rawTarget = match[1].trim();
    if (!rawTarget || rawTarget.startsWith('http://') || rawTarget.startsWith('https://') || rawTarget.startsWith('#') || rawTarget.startsWith('mailto:') || rawTarget.startsWith('app://')) {
      continue;
    }
    const target = rawTarget.split('#')[0];
    const resolved = path.resolve(path.dirname(absFile), target);
    if (!fs.existsSync(resolved)) {
      error(`Broken relative link in ${relFile}: ${rawTarget}`);
    }
  }
}

const refsPath = path.join(root, '00-front-matter', '03-references.md');
if (fs.existsSync(refsPath)) {
  const refs = fs.readFileSync(refsPath, 'utf8');
  const urlRegex = /\[[^\]]+\]\((https?:\/\/[^)]+)\)/g;
  let match;
  while ((match = urlRegex.exec(refs)) !== null) {
    try {
      new URL(match[1]);
    } catch {
      error(`Invalid external URL in 00-front-matter/03-references.md: ${match[1]}`);
    }
  }
}

if (hadError) process.exit(1);
NODE
if [[ "$?" -ne 0 ]]; then
  errors=1
fi

legacy_patterns=(
  '00-how-to-read-this-book\.md'
  'appendix/'
  '`[0-9]{2}`(?:,\s*`[0-9]{2}`)*(?:,\s*appendix)?'
  '\|[^|\n]*\|\s*appendix\s*\|'
  '\[(15-code-reading-guide|17-end-to-end-scenarios)\.md\]'
  '\[(03-runtime-modes-and-entrypoints|04-session-startup-trust-and-initialization|07-command-system|08-tool-system-and-permissions|09-state-ui-and-terminal-interaction|10-services-and-integrations|11-agent-skill-plugin-mcp-and-coordination|12-task-model-and-background-execution|13-persistence-config-and-migrations|14-remote-bridge-server-and-upstreamproxy|16-risks-debt-and-observations)\.md\]'
  '\[\.\./(execution|interfaces|safety|evaluation)/'
  '\[(evaluation|context|interfaces|execution|safety|foundations)/[0-9]{2}[^]]*\.md\]'
)

for pattern in "${legacy_patterns[@]}"; do
  if rg -n "$pattern" README.md 00-front-matter 01-foundations 02-runtime-and-session-start 03-context-and-control 04-interfaces-and-operator-surfaces 05-execution-continuity-and-integrations 06-boundaries-deployment-and-safety 07-evaluation-and-synthesis 08-reference >/dev/null; then
    fail "Legacy pattern still present for regex: $pattern"
  fi
done

if [[ "$errors" -ne 0 ]]; then
  exit 1
fi

printf 'Doc consistency checks passed.\n'
