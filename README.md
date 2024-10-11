# Introduction

This project is a simple example of how to use Supabase with Typescript.
It contains a few examples of how to use the Supabase client to interact with a Supabase instance.

## Folder Structure

The project is structured as follows:

```txt
├── supabase
│   ├── functions
│   │   ├── import_map.json # A top-level import map to use across functions.
│   │   ├── _shared
│   │   │   ├── supabaseAdmin.ts # Supabase client with SERVICE_ROLE key.
│   │   │   ├── supabaseClient.ts # Supabase client with ANON key.
│   │   │   └── cors.ts # Reusable CORS headers.
│   │   ├── function-one # Use hyphens to name functions.
│   │   │   └── index.ts
│   │   ├── function-two
│   │   │   └── index.ts
│   │   └── tests
│   │       ├── function-one-test.ts
│   │       └── function-two-test.ts
│   ├── migrations
│   └── config.toml
├── package.json
├── pnpm-lock.yaml
├── README.md
└── tsconfig.json
```

***Naming Functions (edge)***

We recommend using hyphens to name functions
because hyphens are the most URL-friendly of all the naming conventions.

## Install Command

Install Deno and Supabase:

```bash
brew install deno # or follow the instructions at https://docs.deno.com/runtime/
brew install supabase/tap/supabase # or follow the instructions at https://supabase.com/docs/guides/local-development/cli/getting-started
```

## Supabase CLI

To use the Supabase CLI, run the following docs:

<https://supabase.com/docs/guides/local-development/overview>

### Environment Variables

To use supabase cli generate a .env file with variables:

```bash
supabase gen keys --project-id <project_id> --experimental > .env
```

### Supabase Sync Database structure for develop (from cloud to local)

```bash
supabase gen types --lang=typescript --project-ref <project_id> --schema public > supabase/databases/database.types.ts
```

### Edge Function

Deno installed required

```bash
> Create a function
$ supabase functions new hello-world

> Deploy your function
$ supabase functions deploy hello-world --project-ref <project_id>

> Invoke your function
$ curl -L -X POST 'https://<project_id>.supabase.co/functions/v1/hello-world' -H 'Authorization: Bearer [YOUR ANON KEY]' --data '{"name":"Functions"}'
```

## Deno

lint:

```bash
deno lint
```

## Reference

- Supabase docs: <https://supabase.com/docs>
- Supabase cli: <https://supabase.com/docs/reference/cli/>
- Generating TypeScript Types: <https://supabase.com/docs/guides/api/rest/generating-types>
- Edge functions & folder structure: <https://supabase.com/docs/guides/functions/quickstart>
