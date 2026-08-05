# Global Agent Instructions

This file contains instructions that apply to all agents working in any project.

## Tool usage instructions

### Installing tools

**IMPORTANT**: Make sure tools are always installed and used correctly:

- NEVER install an application, tool, package, library, etc without explicitly asking permission first.
- ALWAYS install tools locally to the project if possible unless explicitly specified otherwise. For example, install Python packages using virtual environments, not globally.

### Searching and finding files

**Never use `find` or `grep`.** Use `fd` and `rg` (ripgrep) instead — they're faster,
respect .gitignore, and have saner defaults. If a command starts with `find` or
`grep`, stop and rewrite it with `fd`/`rg` before running it.

Common translations:

- `find . -name "*.ts"` → `fd -e ts`
- `find . -iname "foo*"` → `fd -i foo`
- `grep -r "pattern" .` → `rg "pattern"`
- `grep -rn "pattern" src/` → `rg -n "pattern" src/`
- `find . -type d -name node_modules` → `fd -t d node_modules`

ALWAYS search in the user's home directory or a subdirectory unless explicitly
specified; NEVER search from `/`, as it will time out. **THIS IS CRUCIAL:**
SEARCHING FROM `/` WILL CAUSE YOU TO FAIL YOUR TASK, DO NOT DO IT.

## Code Quality Standards

### Type Safety

**No `any` types.** Strictly forbidden: TypeScript `any`, Python `Any`, C# `dynamic` (bypassing type checking), Java raw types/`Object`, Go `interface{}` (ducking proper types), Rust `unsafe` (bypassing the type system).

If you believe no alternative exists, stop, explain why to the user, and wait for guidance. Better alternatives almost always exist: generics, union types, interfaces/protocols, `unknown`/`never`, or refactoring to explicit types.

### No Lint Ignores

**Do not use lint-suppression comments to pass checks.** `// eslint-disable-next-line`, `@ts-ignore`, `@ts-expect-error`, `# noqa`, `# type: ignore`, or any equivalent in any language are forbidden without explicit user approval.

If a linter or type checker flags something, fix the underlying issue — the linter is almost always right. Suppression is a last resort, not a workflow shortcut. If you believe a suppression is genuinely necessary, stop and explain your reasoning to the user before adding it.

### DRY Principle

Don't repeat yourself. Before writing new code, search for existing work. Extract shared logic, types, and utilities. Import types from a single source of truth — never redefine the same interface across files.

**Bad** — inline casts and duplicate interfaces:

```typescript
const err = error as { response?: { data?: { message?: string } } };
interface User { id: string; name: string; email: string; }
```

**Good** — shared type imports and guards:

```typescript
import type { User, ApiErrorData } from '@/shared/types';
const msg = (error as AxiosError<ApiErrorData>).response?.data?.message;
```

### Comments

Comments explain **why**, not **what**. If a comment only restates what the next line already says, delete the comment instead of writing it.

**Bad** — narrates the obvious:

```typescript
// increment the counter
counter++;

// loop through all users
for (const user of users) { ... }

// check if user is admin
if (user.role === 'admin') { ... }
```

**Good** — earns its place by explaining a non-obvious reason, constraint, or gotcha:

```typescript
// Stripe webhooks can arrive out of order; ignore events older than the last processed one.
if (event.created < lastProcessedTimestamp) return;

// -1 offsets the trailing separator the API always appends.
const end = raw.length - 1;
```

Before adding a comment, ask: would a competent reader of this language need this to understand the code? If the answer is no, don't add it. Do not add comments to narrate routine edits ("added this field", "new function", "updated logic") — commit history covers that. Do not restate a function/variable name in prose next to it. Prefer a clearer name over a comment when possible.

This applies to genuinely new comments you write — do not delete or rewrite pre-existing comments in code you touch unless they are wrong or the code they describe is removed.

### TypeScript Standards

For TypeScript projects:

- **Strict mode enabled** (`strict: true` in tsconfig)
- **No implicit any** - all types must be explicit
- **Strict null checks** - handle null/undefined explicitly
- **Modern target** - Use recent ECMAScript targets (ES2022+)

### Code Formatting

Use consistent formatting across projects (Prettier recommended):

- **Semicolons**: yes
- **Quotes**: single quotes for strings
- **Trailing commas**: all
- **Print width**: 100 characters
- **Tab width**: 2 spaces

### Import Conventions

Use path aliases, not relative imports.

**Bad:** `import { AuthService } from '../../../auth/auth.service';`

**Good:** `import { AuthService } from '@/auth/auth.service';`

Configure path aliases in your project's tsconfig.json or equivalent.

## Development Workflow

### Before Every Commit

**Format:** `<type>: <description>` — types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`. Commit messages MUST be 80 characters at most - they should not contain a detailed list of changes.

**Run these checks and fix all issues before committing:**

1. **Lint** — fix all errors
2. **Test** — all pass
3. **Build** — clean compile

**LSP / generated-code errors:** Regenerate (`npm run generate`, `prisma generate`, etc.), restart LSP, then verify with a build. If errors persist after regeneration, they are real — fix them.
