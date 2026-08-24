#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SKILLS_ROOT="$PROJECT_ROOT/skills"

TARGET="all"
SCOPE="user"
PROJECT_DIR=""
SKILL_FILTER=""
NAMESPACE="codearqtech"
GEMINI_COMMANDS="false"
FORCE="false"
DRY_RUN="false"
LIST_ONLY="false"

usage() {
  printf '%s\n' "Usage: ./scripts/install.sh [options]"
  printf '%s\n' "  --target NAME        claude|codex|opencode|amp|gemini|agents|all (default: all)"
  printf '%s\n' "                       agents = the shared .agents/skills alias, read by"
  printf '%s\n' "                       Codex, Gemini CLI, OpenCode and Amp"
  printf '%s\n' "                       all    = claude + codex + agents"
  printf '%s\n' "  --scope user|project Scope (default: user)"
  printf '%s\n' "  --project-dir PATH   Required for project scope"
  printf '%s\n' "  --skill NAME         Install one skill (default: all skills)"
  printf '%s\n' "  --namespace NAME     Prefix installed skills with NAME- (default: codearqtech)"
  printf '%s\n' "                       Use --namespace '' to install unprefixed names"
  printf '%s\n' "  --gemini-commands    Also write /NAMESPACE:<skill> slash commands for Gemini CLI"
  printf '%s\n' "  --list               List available skills and exit"
  printf '%s\n' "  --force              Back up and replace the existing version"
  printf '%s\n' "  --dry-run            Show destinations without writing"
  printf '%s\n' "  --help               Show this help"
}

available_skills() {
  for candidate in "$SKILLS_ROOT"/*; do
    [ -f "$candidate/SKILL.md" ] || continue
    basename "$candidate"
  done
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || { printf '%s\n' "Missing value for --target" >&2; exit 2; }
      TARGET="$2"
      shift 2
      ;;
    --scope)
      [ "$#" -ge 2 ] || { printf '%s\n' "Missing value for --scope" >&2; exit 2; }
      SCOPE="$2"
      shift 2
      ;;
    --project-dir)
      [ "$#" -ge 2 ] || { printf '%s\n' "Missing value for --project-dir" >&2; exit 2; }
      PROJECT_DIR="$2"
      shift 2
      ;;
    --skill)
      [ "$#" -ge 2 ] || { printf '%s\n' "Missing value for --skill" >&2; exit 2; }
      SKILL_FILTER="$2"
      shift 2
      ;;
    --namespace)
      [ "$#" -ge 2 ] || { printf '%s\n' "Missing value for --namespace" >&2; exit 2; }
      NAMESPACE="$2"
      shift 2
      ;;
    --gemini-commands)
      GEMINI_COMMANDS="true"
      shift
      ;;
    --list)
      LIST_ONLY="true"
      shift
      ;;
    --force)
      FORCE="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf '%s\n' "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[ -d "$SKILLS_ROOT" ] || {
  printf '%s\n' "Skills directory not found: $SKILLS_ROOT" >&2
  exit 1
}

ALL_SKILLS=$(available_skills)
[ -n "$ALL_SKILLS" ] || {
  printf '%s\n' "No skill with a SKILL.md found in: $SKILLS_ROOT" >&2
  exit 1
}

if [ "$LIST_ONLY" = "true" ]; then
  printf '%s\n' "$ALL_SKILLS"
  exit 0
fi

case "$TARGET" in
  claude|codex|opencode|amp|gemini|agents|all) ;;
  *) printf '%s\n' "Invalid target: $TARGET" >&2; exit 2 ;;
esac

case "$SCOPE" in
  user|project) ;;
  *) printf '%s\n' "Invalid scope: $SCOPE" >&2; exit 2 ;;
esac

case "$NAMESPACE" in
  ""|*[!a-zA-Z0-9-]*)
    [ -z "$NAMESPACE" ] || {
      printf '%s\n' "Invalid namespace: $NAMESPACE (use letters, digits and hyphens)" >&2
      exit 2
    }
    ;;
esac

SKILLS="$ALL_SKILLS"
if [ -n "$SKILL_FILTER" ]; then
  [ -f "$SKILLS_ROOT/$SKILL_FILTER/SKILL.md" ] || {
    printf '%s\n' "Unknown skill: $SKILL_FILTER" >&2
    printf '%s\n' "Available:" >&2
    printf '%s\n' "$ALL_SKILLS" >&2
    exit 2
  }
  SKILLS="$SKILL_FILTER"
fi

if [ "$SCOPE" = "project" ]; then
  [ -n "$PROJECT_DIR" ] || {
    printf '%s\n' "--project-dir is required for --scope project" >&2
    exit 2
  }
  [ -d "$PROJECT_DIR" ] || {
    printf '%s\n' "Project directory does not exist: $PROJECT_DIR" >&2
    exit 2
  }
  PROJECT_DIR=$(CDPATH= cd -- "$PROJECT_DIR" && pwd)
fi

if [ "$TARGET" = "all" ]; then
  PLATFORMS="claude codex agents"
else
  PLATFORMS="$TARGET"
fi

# Installed name for a skill, once the namespace prefix is applied.
installed_name() {
  if [ -n "$NAMESPACE" ]; then
    printf '%s\n' "$NAMESPACE-$1"
  else
    printf '%s\n' "$1"
  fi
}

destination_base() {
  platform="$1"
  if [ "$SCOPE" = "user" ]; then
    case "$platform" in
      claude) printf '%s\n' "$HOME/.claude/skills" ;;
      codex) printf '%s\n' "$HOME/.codex/skills" ;;
      opencode) printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills" ;;
      amp) printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/amp/skills" ;;
      gemini) printf '%s\n' "$HOME/.gemini/skills" ;;
      agents) printf '%s\n' "$HOME/.agents/skills" ;;
    esac
  else
    case "$platform" in
      claude) printf '%s\n' "$PROJECT_DIR/.claude/skills" ;;
      codex) printf '%s\n' "$PROJECT_DIR/.codex/skills" ;;
      opencode) printf '%s\n' "$PROJECT_DIR/.opencode/skills" ;;
      amp) printf '%s\n' "$PROJECT_DIR/.agents/skills" ;;
      gemini) printf '%s\n' "$PROJECT_DIR/.gemini/skills" ;;
      agents) printf '%s\n' "$PROJECT_DIR/.agents/skills" ;;
    esac
  fi
}

gemini_commands_base() {
  if [ "$SCOPE" = "user" ]; then
    base="$HOME/.gemini/commands"
  else
    base="$PROJECT_DIR/.gemini/commands"
  fi
  if [ -n "$NAMESPACE" ]; then
    printf '%s\n' "$base/$NAMESPACE"
  else
    printf '%s\n' "$base"
  fi
}

# Rewrite every reference to a bare skill name so that cross-references between
# skills, the openai.yaml default prompts and the SKILL.md name field all point
# at the namespaced install.
apply_namespace() {
  destination="$1"
  [ -n "$NAMESPACE" ] || return 0
  find "$destination" -type f \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' -o -name '*.toml' -o -name '*.json' -o -name '*.txt' \) -print | while IFS= read -r file; do
    tmp="$file.tmp-namespace"
    cp "$file" "$tmp"
    for known in $ALL_SKILLS; do
      sed "s|$known|$NAMESPACE-$known|g" "$tmp" > "$tmp.next"
      mv "$tmp.next" "$tmp"
    done
    mv "$tmp" "$file"
  done
}

preflight_for() {
  platform="$1"
  skill="$2"
  base=$(destination_base "$platform")
  destination="$base/$(installed_name "$skill")"
  if { [ -e "$destination" ] || [ -L "$destination" ]; } && [ "$FORCE" != "true" ]; then
    printf '%s\n' "[$platform] Already exists: $destination" >&2
    printf '%s\n' "No destinations were changed. Use --force to create a backup and update." >&2
    exit 1
  fi
}

back_up_existing() {
  destination="$1"
  timestamp=$(date '+%Y%m%d-%H%M%S')
  backup="$destination.backup-$timestamp"
  counter=0
  while [ -e "$backup" ] || [ -L "$backup" ]; do
    counter=$((counter + 1))
    backup="$destination.backup-$timestamp-$counter"
  done
  mv "$destination" "$backup"
  printf '%s\n' "Backup created: $backup"
}

install_for() {
  platform="$1"
  skill="$2"
  base=$(destination_base "$platform")
  source_dir="$SKILLS_ROOT/$skill"
  destination="$base/$(installed_name "$skill")"

  if [ "$DRY_RUN" = "true" ]; then
    printf '%s\n' "[$platform] $source_dir -> $destination"
    return
  fi

  mkdir -p "$base"
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    if [ "$FORCE" != "true" ]; then
      printf '%s\n' "[$platform] Already exists: $destination" >&2
      printf '%s\n' "Use --force to create a backup and update." >&2
      exit 1
    fi
    back_up_existing "$destination"
  fi

  cp -R "$source_dir" "$destination"
  apply_namespace "$destination"
  printf '%s\n' "[$platform] Installed: $destination"
}

skill_summary() {
  skill="$1"
  meta="$SKILLS_ROOT/$skill/agents/openai.yaml"
  summary=""
  if [ -f "$meta" ]; then
    summary=$(sed -n 's/^[[:space:]]*short_description:[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$meta" | head -1)
  fi
  [ -n "$summary" ] || summary="Run the $skill skill"
  printf '%s\n' "$summary"
}

install_gemini_command() {
  skill="$1"
  base=$(gemini_commands_base)
  name=$(installed_name "$skill")
  destination="$base/$skill.toml"
  summary=$(skill_summary "$skill")

  if [ "$DRY_RUN" = "true" ]; then
    printf '%s\n' "[gemini-command] -> $destination"
    return
  fi

  mkdir -p "$base"
  if { [ -e "$destination" ] || [ -L "$destination" ]; } && [ "$FORCE" != "true" ]; then
    printf '%s\n' "[gemini-command] Already exists: $destination" >&2
    printf '%s\n' "Use --force to create a backup and update." >&2
    exit 1
  fi
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    back_up_existing "$destination"
  fi

  {
    printf 'description = "%s"\n' "$summary"
    printf 'prompt = """\n'
    printf 'Activate the `%s` skill and apply it to the request below.\n' "$name"
    printf 'Follow the skill exactly, including its principles and its reference files.\n\n'
    printf '{{args}}\n'
    printf '"""\n'
  } > "$destination"
  printf '%s\n' "[gemini-command] Installed: $destination"
}

if [ "$DRY_RUN" != "true" ]; then
  for platform in $PLATFORMS; do
    for skill in $SKILLS; do
      preflight_for "$platform" "$skill"
    done
  done
fi

for platform in $PLATFORMS; do
  for skill in $SKILLS; do
    install_for "$platform" "$skill"
  done
done

if [ "$GEMINI_COMMANDS" = "true" ]; then
  for skill in $SKILLS; do
    install_gemini_command "$skill"
  done
fi
