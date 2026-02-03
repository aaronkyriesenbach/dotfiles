# Global Agent Instructions

This file contains instructions that apply to all agents working in any project.

## Required Skills

### Subagent Driven Development

**MANDATORY**: When implementing features, you MUST use the `subagent-driven-development` skill. This is not optional.

Before implementing any feature:
1. Invoke the `subagent-driven-development` skill
2. Follow its process exactly
3. Break down work appropriately into subagent tasks

## Code Quality Standards

### Type Safety

**CRITICAL**: The use of `any` types is STRICTLY FORBIDDEN in all languages, including but not limited to:
- TypeScript/JavaScript: `any`
- Python: `Any`
- C#: `dynamic` (when used to bypass type checking)
- Java: raw types, excessive use of `Object`
- Go: `interface{}` (when used to avoid proper typing)
- Rust: excessive use of unsafe code to bypass type system

**If you believe there is truly no alternative to using an `any` type:**
1. STOP immediately
2. Do NOT proceed with implementation
3. Ask the user for guidance and clarification
4. Explain why you believe no alternative exists
5. Wait for explicit permission and direction

Remember: There is almost always a better alternative than `any`:
- Use proper generics/type parameters
- Define specific union types
- Create proper interfaces/protocols
- Use unknown/never types where appropriate
- Refactor to make types explicit

Type safety is non-negotiable. Proper typing prevents bugs, improves maintainability, and makes code self-documenting.

### DRY Principle (Don't Repeat Yourself)

**IMPORTANT**: Always apply the DRY principle during development:

1. **Reuse existing code** - Before writing new code, search for existing implementations that can be reused or extended
2. **Extract shared logic** - If the same logic appears in multiple places, extract it into a shared utility, hook, or service
3. **Use shared types** - Types used across multiple modules should be defined in a shared location
4. **Avoid type duplication** - Never define the same interface/type in multiple files; import from a single source of truth

**Bad Examples:**
```typescript
// BAD - Duplicating error type in multiple files
const err = error as { response?: { data?: { message?: string } } };

// BAD - Defining same interface in multiple locations
interface User { id: string; name: string; email: string; }
```

**Good Examples:**
```typescript
// GOOD - Use proper type guards with shared types
import { isAxiosError } from 'axios';
import type { ApiErrorData } from '@/shared/types';

if (isAxiosError<ApiErrorData>(error)) {
  const msg = error.response?.data?.message;
}

// GOOD - Import shared types
import type { User } from '@/shared/types';
```

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

**IMPORTANT**: Always use path aliases instead of relative imports.

**Bad - relative imports:**
```typescript
import { AuthService } from '../../../auth/auth.service';
import { useAuthStore } from '../../stores/auth.store';
```

**Good - path aliases:**
```typescript
import { AuthService } from '@/auth/auth.service';
import { useAuthStore } from '@/stores/auth.store';
```

Configure path aliases in your project's tsconfig.json or equivalent configuration.

## Development Workflow

### Commit Guidelines

**Commit Message Format:**
```
<type>: <description>

Types: feat, fix, refactor, test, docs, chore
```

**Examples:**
- `feat: add user authentication module`
- `fix: correct password validation logic`
- `refactor: extract shared validation utils`
- `test: add unit tests for user service`
- `docs: update API documentation`
- `chore: update dependencies`

### Before Committing (MANDATORY)

**Always run these checks before every commit:**
1. **Run linting** - Fix ALL linting errors before committing
2. **Run tests** - Ensure all tests pass
3. **Run build** - Verify the project compiles without errors

**Do not commit if linting fails.** Fix all lint errors first.

### LSP and Code Generation Errors

When you see LSP (Language Server Protocol) errors about missing generated types or modules:

1. **First**, regenerate the generated code (e.g., `npm run generate`, `prisma generate`, etc.)
2. **Then**, restart the LSP server to pick up the new types
3. **Verify** the errors are resolved by running the build command - do not assume errors are transient

**Important**: If LSP errors persist after regenerating code and restarting LSP, they are real errors that need to be fixed, not false positives.
