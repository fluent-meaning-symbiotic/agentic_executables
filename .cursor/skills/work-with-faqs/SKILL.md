---
name: work-with-faqs
description: Installs, updates, and uses FAQ documentation across codebases. Use when working with FAQs, discovering package documentation, updating FAQs after code changes, or when the user asks about FAQ installation, updates, or usage.
---

# Working with FAQs

**Goal:** Concise, AI-optimized FAQ system. Short & Smart. Spatial memory for instant recall.

## FAQ Types

| Type | Purpose | Format | Audience |
|------|---------|--------|----------|
| **DESIGN_FAQ.md** | WHY decisions made | Q&A (2-3 sentences) | Maintainers, AI agents |
| **DX_FAQ.md** (or USER_FAQ.md) | HOW to use system | Memory Palace (🏠 rooms + code) | Developers, users |

**Key Principle:** DESIGN_FAQ = architectural rationale. DX_FAQ = usage patterns. No duplication.

## FAQ Discovery Matrix

| Working On | Read These FAQs | Why |
|-----------|----------------|-----|
| Core library/framework | Root DESIGN_FAQ + DX_FAQ | Foundation architecture |
| Module/package | Core FAQs + Module FAQs | Core fundamentals + module-specific |
| Application/example | Core DX_FAQ + relevant module DX_FAQs | API usage patterns |
| New feature | Core DESIGN_FAQ → understand constraints | Architectural context |

**Quick Discovery:**
- Use `Glob` tool: `**/DESIGN_FAQ.md` or `**/DX_FAQ.md` (or `**/USER_FAQ.md`)
- FAQs typically live at: project root, package roots, module directories
- Hierarchy: Read core FAQs first, then module/package-specific

## Using FAQs - Decision Matrix

| Question Type | Read This | Search Pattern | Example |
|--------------|-----------|----------------|---------|
| **WHY** exists? | DESIGN_FAQ | `Grep "Why.*[topic]"` | "Why this architecture?" |
| **HOW** to use? | DX_FAQ | Navigate to 🏠 room | "How do I call this API?" |
| **TRADE-OFFS**? | DESIGN_FAQ | Look for ✅/❌ sections | "Option A vs Option B?" |
| **CODE PATTERN**? | DX_FAQ | Find matching room | "Code example for X?" |
| **MODULE-SPECIFIC**? | Module DX_FAQ | Module-specific rooms | "Use this module?" |
| **RATIONALE**? | DESIGN_FAQ | `Grep "Rationale"` | "Why this decision?" |

### FAQ Reading Strategies

**DESIGN_FAQ (Architectural Understanding):**
1. Use `Grep` for specific topics: `Grep "Why.*[topic]" --type md`
2. Focus on Q&A + trade-offs (✅/❌)
3. Read rationale sections for context

**DX_FAQ (Usage Patterns):**
1. Navigate Memory Palace "rooms" (🏠 🏭 🔍 etc.) - spatial organization
2. Use spatial memory: locate feature in specific "room"
3. Copy code patterns directly from rooms

## Updating FAQs

### Update Trigger Matrix

| Change Type | Update DESIGN_FAQ? | Update DX_FAQ? | Update Module FAQ? |
|-------------|-------------------|----------------|-------------------|
| New internal system | ✅ | ❌ | ❌ |
| New public API | ❌ | ✅ | ✅ (if module) |
| Architectural change | ✅ | ❌ | ✅ (if affects module) |
| Interface change | ❌ | ✅ | ✅ (if module provides it) |
| Performance optimization | ✅ | ❌ | ❌ |
| New pattern/feature | ❌ | ✅ | ❌ |
| Module extraction | ✅ (why extracted) | ✅ (how to use) | ✅ (new module FAQs) |

### Update Workflow (Compressed)

**1. Identify Change:**
- Use `Grep` to find related FAQ entries
- Determine FAQ type from matrix above

**2. Update DESIGN_FAQ Pattern:**
```markdown
**Q: Why [decision]?**
A: [2-3 sentence answer with key rationale]

**Trade-offs:**
- ✅ [Benefits]
- ❌ [Drawbacks]
```

**3. Update DX_FAQ Pattern:**
```markdown
## 🏠 [Appropriate Room]

**Q: How do I [action]?**
```[language]
// Minimal working example
system.newFeature();
```

**When to use:** [Use case]. **Avoid when:** [Anti-pattern].
```

**4. Update Module/Package FAQs (if applicable):**
- Check for project-specific FAQ update commands
- Update module FAQs when module API changes
- Maintain consistency with core FAQs (no duplication)

### Memory Palace Format for DX_FAQ

**Key Principle:** Spatial organization = AI agent memory retention

**Rooms (Locations) - Customize by Domain:**

_Example for API/Framework:_
- 🏠 Initialization Hub: Setup, configuration, initialization
- 🏭 Object Factory: Object/entity creation and lifecycle
- 🔍 Query/Search Station: Finding and filtering operations
- 🧱 Component Workshop: Component/module creation
- ⚙️ Processing Lab: Processing/transformation operations
- 🎯 Event Hub: Event handling and messaging
- 📦 Extension Store: Plugins/modules installation

_Example for CLI/Tool:_
- 🏠 Command Center: Main commands and initialization
- ⚙️ Configuration Workshop: Settings and configuration
- 🔍 Data Explorer: Querying and searching
- 📤 Output Station: Export and output operations

**Pattern:**
```markdown
## 🏠 [Room Name]

OPERATION: code snippet
OPERATION: code snippet

**Q: How to [action]?**
```[language]
// Pattern with spatial context
```
```

This format leverages spatial memory for instant recall. Adapt rooms to your domain.

## Module/Package FAQ System

### Module FAQ Hierarchy

**Typical Structure:**
```
project_root/
├── DESIGN_FAQ.md          # Core architecture decisions
├── DX_FAQ.md              # Core usage patterns
└── modules/               # Or: packages/, plugins/, components/
    ├── module_a/
    │   ├── DESIGN_FAQ.md  # Module-specific decisions
    │   └── DX_FAQ.md      # Module-specific usage
    └── module_b/
        ├── DESIGN_FAQ.md
        └── DX_FAQ.md
```

### Module FAQ Update Rules

**When to Create/Update Module FAQs:**
1. **New module:** Create both DESIGN_FAQ + DX_FAQ
2. **Module API change:** Update module DX_FAQ
3. **Module extraction:** Update module DESIGN_FAQ (rationale) + DX_FAQ (usage)
4. **Module-specific feature:** Update module DX_FAQ with usage examples

**Module FAQ Structure:**
- Reference core FAQs for fundamentals (no duplication)
- Focus on module-specific concerns only
- Use same formats: DESIGN_FAQ (Q&A), DX_FAQ (Memory Palace rooms)

**Cross-referencing:**
```markdown
<!-- In module DX_FAQ -->
For core patterns, see `[path-to-root]/DX_FAQ.md`.

<!-- In core DX_FAQ -->
For module-specific patterns:
- Module A: `modules/module_a/DX_FAQ.md`
- Module B: `modules/module_b/DX_FAQ.md`
```

Check for project-specific FAQ update commands in `.cursor/commands/`.

## Validation Checklist

Before committing FAQ updates:

- [ ] DESIGN_FAQ updated for architectural changes?
- [ ] DX_FAQ updated for API/usage changes?
- [ ] Module FAQs updated if module affected?
- [ ] Code examples tested and working?
- [ ] Terminology consistent across FAQs?
- [ ] No contradictions with existing docs?
- [ ] Memory Palace structure maintained in DX_FAQ?
- [ ] Answers concise (2-3 sentences for DESIGN_FAQ)?
- [ ] No duplication between core and module FAQs?

## Quick Reference

| Task | Action |
|------|--------|
| **Find FAQ** | Use `Glob "**/DESIGN_FAQ.md"` or `"**/DX_FAQ.md"` |
| **Understand WHY** | Read DESIGN_FAQ, look for Q&A + trade-offs |
| **Learn HOW** | Read DX_FAQ, navigate to room (🏠🏭🔍) |
| **Update after change** | Use trigger matrix → update appropriate FAQ |
| **Add module FAQ** | Create DESIGN_FAQ + DX_FAQ in module directory |
| **Verify consistency** | Use `Grep` to find related entries |

## Related Resources

Check for project-specific resources:
- FAQ usage rules: `.cursor/rules/faq_*.mdc` or `.cursor/rules/faq_usage.*`
- Update FAQ commands: `.cursor/commands/update-faq.*` or project docs
- Root FAQs: `DESIGN_FAQ.md`, `DX_FAQ.md` (or `USER_FAQ.md`)
- Module FAQs: `modules/*/DESIGN_FAQ.md`, `modules/*/DX_FAQ.md` (adapt path to project structure)
