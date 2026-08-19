#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SKILL_NAME="diagnose-system-performance"
SOURCE_DIR="$PROJECT_ROOT/skills/$SKILL_NAME"

TARGET="all"
SCOPE="user"
PROJECT_DIR=""
FORCE="false"
DRY_RUN="false"

usage() {
  printf '%s\n' "Usage: ./scripts/install.sh [options]"
  printf '%s\n' "  --target claude|codex|opencode|all   Target (default: all)"
  printf '%s\n' "  --scope user|project                 Scope (default: user)"
  printf '%s\n' "  --project-dir PATH                   Required for project scope"
  printf '%s\n' "  --force                              Back up and replace the existing version"
  printf '%s\n' "  --dry-run                            Show destinations without writing"
  printf '%s\n' "  --help                               Show this help"
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

case "$TARGET" in
  claude|codex|opencode|all) ;;
  *) printf '%s\n' "Invalid target: $TARGET" >&2; exit 2 ;;
esac

case "$SCOPE" in
  user|project) ;;
  *) printf '%s\n' "Invalid scope: $SCOPE" >&2; exit 2 ;;
esac

[ -f "$SOURCE_DIR/SKILL.md" ] || {
  printf '%s\n' "Skill source not found: $SOURCE_DIR" >&2
  exit 1
}

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

destination_base() {
  platform="$1"
  if [ "$SCOPE" = "user" ]; then
    case "$platform" in
      claude) printf '%s\n' "$HOME/.claude/skills" ;;
      codex) printf '%s\n' "$HOME/.agents/skills" ;;
      opencode) printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills" ;;
    esac
  else
    case "$platform" in
      claude) printf '%s\n' "$PROJECT_DIR/.claude/skills" ;;
      codex) printf '%s\n' "$PROJECT_DIR/.agents/skills" ;;
      opencode) printf '%s\n' "$PROJECT_DIR/.opencode/skills" ;;
    esac
  fi
}

preflight_for() {
  platform="$1"
  base=$(destination_base "$platform")
  destination="$base/$SKILL_NAME"
  if { [ -e "$destination" ] || [ -L "$destination" ]; } && [ "$FORCE" != "true" ]; then
    printf '%s\n' "[$platform] Already exists: $destination" >&2
    printf '%s\n' "No destinations were changed. Use --force to create a backup and update." >&2
    exit 1
  fi
}

install_for() {
  platform="$1"
  base=$(destination_base "$platform")
  destination="$base/$SKILL_NAME"

  if [ "$DRY_RUN" = "true" ]; then
    printf '%s\n' "[$platform] $SOURCE_DIR -> $destination"
    return
  fi

  mkdir -p "$base"
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    if [ "$FORCE" != "true" ]; then
      printf '%s\n' "[$platform] Already exists: $destination" >&2
      printf '%s\n' "Use --force to create a backup and update." >&2
      exit 1
    fi
    timestamp=$(date '+%Y%m%d-%H%M%S')
    backup="$destination.backup-$timestamp"
    counter=0
    while [ -e "$backup" ] || [ -L "$backup" ]; do
      counter=$((counter + 1))
      backup="$destination.backup-$timestamp-$counter"
    done
    mv "$destination" "$backup"
    printf '%s\n' "[$platform] Backup created: $backup"
  fi

  cp -R "$SOURCE_DIR" "$destination"
  printf '%s\n' "[$platform] Installed: $destination"
}

if [ "$DRY_RUN" != "true" ]; then
  if [ "$TARGET" = "all" ]; then
    preflight_for claude
    preflight_for codex
    preflight_for opencode
  else
    preflight_for "$TARGET"
  fi
fi

if [ "$TARGET" = "all" ]; then
  install_for claude
  install_for codex
  install_for opencode
else
  install_for "$TARGET"
fi
