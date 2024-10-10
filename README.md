# Introduction

This project is a simple example of how to use Supabase with Typescript.
It contains a few examples of how to use the Supabase client to interact with a Supabase instance.

## Folder Structure

The project is structured as follows:

```txt
├── actions
│   ├── clients // contains the client-side actions using the Supabase client
│   │   ├── login.ts
│   │   ├── signup.ts
│   │   └── update-profiles.ts
│   └── urls // contains the client-side actions using urls RESTful API
│       ├── login.ts
│       └── signup.ts
├── supabase
│   └── config.toml
├── package.json
├── pnpm-lock.yaml
├── README.md
└── tsconfig.json
```

## Environment Variables

- `SUPABASE_URL`: the URL of the Supabase instance
- `SUPABASE_ANON_KEY`: the anonymous key for the Supabase instance

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

## Reference

- Supabase docs: <https://supabase.com/docs>
- Supabase cli: <https://supabase.com/docs/reference/cli/>
