# AGENTS.md

## Commands

- **Build**: `pnpm build` — TypeScript + Vite, outputs to `dist/`
- **Dev**: `pnpm dev` — Vite dev server on :5173
- **Type-check**: `pnpm typecheck` — `tsc --noEmit`

### Test

- **All**: `pnpm test` — Vitest (must pass before commits)
- **Single file**: `npx vitest run path/to/test.ts`
- **Single test**: `npx vitest run -t "test name"`
- **Coverage**: `pnpm test -- --coverage`

### Lint

- **Check**: `pnpm lint` — ESLint + Prettier
- **Auto-fix**: `pnpm lint -- --fix && pnpm format`
- **Format**: `pnpm format` — `prettier --write .`

## Stack

- **Runtime**: Node.js 22 (`.nvmrc`)
- **Language**: TypeScript 5.7, strict mode
- **Framework**: Next.js 15.1 (App Router)
- **DB**: PostgreSQL 16 via Prisma 6
- **Styling**: Tailwind CSS 4
- **Package manager**: pnpm 9

## Structure

```
src/
  app/          — Next.js App Router (pages, layouts, API routes)
  components/   — Shared React components
  lib/          — Business logic, DB client, utilities
  server/       — Server-only code (auth, db queries, tRPC routers)
  types/        — Shared TypeScript types/interfaces
prisma/
  schema.prisma — Database schema (source of truth)
tests/
  unit/         — Vitest unit tests
  e2e/          — Playwright E2E tests
```

## Boundaries

- 🚫 **Never edit**: `.env`, `.env.*`, `dist/`, `.next/`, `node_modules/`
- 🚫 **Never commit**: Secrets, keys, `.env` files
- 🚫 **Never touch**: `prisma/migrations/` (managed by Prisma CLI)
- ⚠️ **Ask before**: Adding npm dependencies, changing `prisma/schema.prisma`, modifying CI/CD
- ✅ **Go ahead**: Create branches, edit `src/` and `tests/`, run any command

## Code Style

- Strict TypeScript. No `any` — use `unknown` and narrow.
- Prefer `interface` over `type` for object shapes.
- Async/await, never raw Promises.
- Named exports preferred over default exports.

### Example

```typescript
// ✅ Good
interface User { id: string; name: string; }

async function getUser(id: string): Promise<User> {
  const user = await db.user.findUnique({ where: { id } });
  if (!user) throw new Error(`User ${id} not found`);
  return user;
}

// ❌ Bad
type User = any;
function getUser(id) {
  return db.user.findUnique({ where: { id } }).then(r => r);
}
```

### Naming

- Functions: camelCase | Types: PascalCase | Constants: UPPER_SNAKE_CASE
- Files: kebab-case, React components in PascalCase files
- Test files: `*.test.ts` or `*.spec.ts`

## Testing

- **Framework**: Vitest with @testing-library/react
- **Location**: Co-located with source (`Button.test.tsx` next to `Button.tsx`)
- **E2E**: Playwright in `tests/e2e/` — `npx playwright test`
- New features require tests. Bug fixes require regression tests.

## Git

- **Branches**: `feat/`, `fix/`, `chore/` prefixes
- **Commits**: Conventional commits (`feat:`, `fix:`, `chore:`)
- **CI**: lint → typecheck → test → build (all must pass)

## Subprojects

- `packages/api/` — FastAPI backend → see `packages/api/AGENTS.md`
- `packages/web/` — Next.js frontend → see `packages/web/AGENTS.md`
