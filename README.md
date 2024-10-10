# Introduction

This project is a simple example of how to use Supabase with Typescript.
It contains a few examples of how to use the Supabase client to interact with a Supabase instance.

## Folder Structure

The project is structured as follows:

```txt
├── actions
│   ├── clients // contains the client-side actions using the Supabase client. FOR TEST ONLY
│   │   ├── login.ts
│   │   ├── signup.ts
│   │   └── update-profiles.ts
│   └── urls // contains the client-side actions using urls RESTful API. FOR TEST ONLY
│       ├── login.ts
│       └── signup.ts
├── supabase
│   ├── migrations // migration file
│   │   ├── ...
│   └── config.toml
├── package.json
├── pnpm-lock.yaml
├── README.md
└── tsconfig.json
```

## Install Command

To install the project, run the following command:

- Install pnpm

```bash
npm install -g pnpm
```

- Install the project

```bash
pnpm install
```

- To run any file of test

```bash
pnpm ts-node path/to/file.ts
```

## Supabase CLI

To use the Supabase CLI, run the following docs:

<https://supabase.com/docs/guides/local-development/overview>

### Environment Variables

To use supabase cli generate a .env file with variables:

```bash
supabase gen keys --experimental > .env
```

Variables uses in this sample project

- `SUPABASE_URL`: the URL of the Supabase instance
- `SUPABASE_ANON_KEY`: the anonymous key for the Supabase instance

### Supabase Sync Database structure for develop (from cloud to local)

_Login supabase first!_
_base on you want to use what schema, mostly public/api_

```bash
supabase gen types --lang=typescript --project-id <project_id> --schema public > supabase/databases/database.types.ts
```

## Reference

- Supabase docs: <https://supabase.com/docs>
- Supabase cli: <https://supabase.com/docs/reference/cli/>
- Generating TypeScript Types: <https://supabase.com/docs/guides/api/rest/generating-types>
