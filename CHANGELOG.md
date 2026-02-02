# Changelog

All notable changes to Koipond will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-02-01

Initial release.

### Added

- Stone: Ruby file abstraction with Comparable (sorts by mtime)
- Pond: Project directory with Enumerable, method_missing for file access
- Wave: Carries context to Claude with style-specific lambdas
- Reflection: Proposed rewrites with preview and apply
- StringSwims refinements for String and Pathname
- Three prompt styles: gentle, radical, poignant
- CLI with `--radical`, `--poignant`, `--trace` flags
- Kin discovery via require parsing and name references
- Prism integration for structural understanding (Ruby 3.3+ native)
- Shape extraction: classes, modules, methods, attributes, includes, constants
- ShapeDiff for semantic change detection with magnitude scoring
- AST-aware kin discovery via DeepKin module
- ShapeCache for mtime-aware lazy caching
- Interactive REPL mode via `koi swim`

[Unreleased]: https://github.com/koipond/koipond/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/koipond/koipond/releases/tag/v0.1.0
