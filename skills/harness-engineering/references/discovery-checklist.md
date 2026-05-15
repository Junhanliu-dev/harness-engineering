# Phase 1: Discovery Checklist

**Goal:** Understand what this project IS before prescribing anything.

## 1.1 Detect Language & Framework

```bash
# File extensions reveal primary language
tldr tree . --depth 1

# Package manifests reveal framework
# Look for: package.json, go.mod, Cargo.toml, pyproject.toml, pom.xml,
#           build.gradle, Gemfile, mix.exs, composer.json, etc.
```

Read the manifest file to identify:
- Primary language and version
- Framework (if any)
- Build tool
- Test framework
- Linter/formatter configuration

## 1.2 Detect Architecture

```bash
tldr tree . --depth 3
tldr arch .
tldr structure . --lang <detected>
```

Don't assume layers. **Discover** them:
- What directories exist at the top level?
- How is code organized? (by feature? by layer? by domain?)
- What are the dependency directions between modules?
- Are there clear boundaries (interfaces, contracts)?

## 1.3 Detect Coding Patterns

Read 5-8 representative source files spanning different parts of the codebase. For each, note:

- **Naming**: How are files, functions, types, variables named?
- **Error handling**: try/catch? Result types? Error codes? Panic?
- **Dependency management**: Constructor injection? Global imports? Service locator?
- **State management**: Where does state live? How is it passed?
- **Async patterns**: Callbacks? Promises? Channels? Coroutines?
- **Type usage**: Strict types? Any/interface{}? Generics?
- **Logging**: What library? What levels? What format?
- **Validation**: Where does input validation happen? What library?

## 1.4 Detect Testing Patterns

```bash
# Find test files
tldr search "test" . --ext <test_extension>
```

Read 2-3 test files to understand:
- Test framework and assertion style
- How fixtures/mocks are set up
- Integration vs unit test separation
- Test data patterns (factories? fixtures? inline?)

## 1.5 Detect CI/CD & Quality Checks

Look for: `.github/workflows/`, `Jenkinsfile`, `.gitlab-ci.yml`, `Makefile`, `justfile`, etc.

What checks already run? What's missing?

## 1.6 Detect Unwritten Rules

These are patterns that are **consistent across the codebase** but not documented anywhere:

- Do all API handlers follow the same structure?
- Is there a consistent way to add a new feature?
- Are there implicit naming conventions (e.g., `*_handler.go`, `use*.ts`)?
- Are certain patterns always paired? (e.g., every service has a matching interface)
- What patterns are NEVER violated across the codebase?

**Method:** Compare 3+ files of the same "type" and extract what's identical in structure.

## 1.7 Research Best Practices

After detecting the stack, research current best practices for that specific language/framework:

```bash
# Use context7 MCP for framework-specific docs
# Use web search for community conventions
```

Compare what the project does vs. what the ecosystem recommends. The harness should encode **the project's actual conventions** (even if they differ from ecosystem defaults), but flag divergences for the wiki.
