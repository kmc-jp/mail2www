# mail2www

mail2www exposes a mail archive through a Sinatra JSON API and a React UI. In
production, nginx serves the compiled React assets directly and delegates only
`/api` requests to Sinatra through Phusion Passenger.

## Development

Copy `config/mail2www.example.yml` to `config/mail2www.yml`, adjust the mail
folders and SMTP settings, then install dependencies:

```sh
cp config/mail2www.example.yml config/mail2www.yml
bundle install
npm install
```

Run the API and Vite development server in separate terminals:

```sh
bundle exec rackup -p 9292
npm run dev
```

Vite proxies `/api` to port 9292. The UI uses React Compiler, TanStack Router,
TanStack Query, and `zod/mini` response validation.

## Production

Build immutable frontend assets during deployment:

```sh
npm ci
npm run build
bundle install --deployment --without development test
```

Use [`deploy/nginx.conf.example`](deploy/nginx.conf.example) as the starting
point for the site configuration. Replace the paths, Ruby executable, hostname,
and authentication integration for the target host. The repository root is the
Passenger application root (`config.ru`), while nginx's document root is
`dist/`. Both nginx and Passenger use that directory as their document root, but
only the `/api` location enables Passenger. Restart Passenger after changing Ruby
code or configuration, and reload nginx after changing its site configuration.

Run both suites before deployment:

```sh
bundle exec rspec
npm run lint
npm run build
```
