# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Koipond is an experimental Ruby gem that detects the most recently changed `.rb` file in a project, discovers its "kin" (related files), and uses Claude CLI to reimagine the related code. It's a pedagogical exploration of Ruby's intrinsic features, written in the spirit of \_why the lucky stiff.

**This is not a production tool.** It's a toy for exploring Ruby's elegance and Claude's code rewriting capabilities.

## Architecture

### Core Concepts

- **Stone**: A Ruby file in the project. Implements `Comparable` (sorts by modification time) and lives in a `Pond`.
- **Pond**: A project directory. Includes `Enumerable` (define `each`, get 60 methods free). Uses `method_missing` to let you access files like `pond.user_model`.
- **Wave**: Carries context to Claude. Contains style-specific prompts as lambdas in a frozen hash.
- **Reflection**: What comes back from Claude. Contains proposed rewrites that can be previewed or applied.
- **Shape** (Prism version): A file's structural fingerprint—classes, methods, attrs, constants, includes.
- **ShapeDiff**: Compares two Shapes to produce semantic changelogs with magnitude scoring.

### File Structure

```
source/files-2/           # Original regex-based Koi (historical)
  koi.rb                  # The complete gem (~780 lines, both library and CLI)
  koi.gemspec
  garden.rb               # Example project (Seed → Flower → Basket)
  README.md

source/files-3/           # Prism-powered evolution
  prism_pond.rb           # Shape extraction, diffing, AST-aware kin discovery
  prism_features.rb       # Demonstration of Prism vs old AST
  PRISM.md

source/files-4/           # Interactive simulation
  sim.rb                  # Animated session replay
  SESSION.txt             # 670-line rendered playthrough
```

### Ruby Features Showcased

The code intentionally demonstrates these Ruby patterns:

| Feature          | Where                                     | Why                                             |
| ---------------- | ----------------------------------------- | ----------------------------------------------- |
| Refinements      | `StringSwims`                             | Scoped monkey-patching ("polite metamorphosis") |
| Struct           | `Stone`, `Reflection`                     | Zero-boilerplate value objects                  |
| Data.define      | `Requirement`, `Method`, `Params` (Prism) | Immutable value objects (Ruby 3.2+)             |
| Comparable       | `Stone#<=>`                               | Define one method, get six operators            |
| Enumerable       | `Pond#each`                               | Define one method, get ~60 methods              |
| method_missing   | `Pond`                                    | Files become methods: `pond.user_model.kin`     |
| Lazy Enumerator  | `Stone#deep_kin`                          | Breadth-first graph traversal on demand         |
| TracePoint       | `Koipond.narrate!`                        | Live method-call observation                    |
| Pattern matching | CLI ARGV parsing                          | Ruby 3 `case/in` destructuring                  |
| Lambdas in Hash  | `Wave::STYLES`                            | Strategy pattern in 3 lines                     |
| `__FILE__ == $0` | Bottom of koipond.rb                      | Same file is library and CLI                    |

## Requirements

- Ruby >= 3.3 (for native Prism)
- `claude` CLI installed and in PATH

## Commands

### Run the CLI

```bash
koi                               # Gentle ripple from most recent file
koi --radical                     # Radical reimagining
koi --poignant                    # In _why's spirit
koi --trace                       # Watch internal narration
koi ~/path --radical              # Specify project path
```

### Run the demos

```bash
ruby examples/prism_features.rb   # Prism vs old AST comparison
ruby examples/sim.rb              # Interactive session replay
```

### Build the gem

```bash
gem build koipond.gemspec
gem install koipond
```

## Style Guidelines

This codebase intentionally uses Ruby idioms that may look unusual but are educational:

- **Endless method syntax**: `def to_s = "🪨 #{path.basename}"` (Ruby 3.0+)
- **Safe navigation + Symbol#to_proc chains**: `stone&.kin&.map(&:to_s)&.join(', ')`
- **Pattern matching on ARGV**: `case ARGV in [*, '--radical', *] then :radical`
- **Heavy use of `.then`/`.tap`** for pipeline style

When modifying, preserve this pedagogical style—the "why" comments are as important as the code.

## Key Design Decisions

1. **Single-file gem**: `koipond.rb` is both library and executable. \_why would approve.
2. **No external dependencies**: Only stdlib (pathname, open3, json, set) plus Prism (native in Ruby 3.3+).
3. **Immutable past**: `.freeze` on "before" states is philosophical, not just technical.

## Working with Claude Integration

The gem calls Claude CLI via `Open3.capture3('claude', '-p', prompt, '--output-format', 'text')`. Responses are parsed for `=== FILEPATH ===` delimited sections.

Three prompt styles exist as lambdas in `Wave::STYLES`:

- `:gentle` — Preserve method signatures, refine gently
- `:radical` — Reimagine architecture if it serves clarity
- `:poignant` — Channel \_why's curiosity and precision
