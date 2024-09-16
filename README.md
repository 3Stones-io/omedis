# Omedis

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# Developers

Please use the Pull Request workflow to submit your changes. For a guide on how to create Pull Requests, check out [GitHub's tutorial on creating a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request).

If that seems to be too complicated:
Use https://gitbutler.com to create a pull request.

## One PR per change

Please create one PR per change. If you have multiple changes, please create multiple PRs. This allows for early feedback and reduces the risk of having to rework large parts of a PR.

## Commit messages

Please use clear and descriptive commit messages.

## Secrets

The secret for tokens need to be changed for the `production` environment and can be found in `config/config.exs`

```
config :omedis, :token_signing_secret, "Lu8xpRC9"
```

This can also be set as an environment variable `TOKEN_SIGNING_SECRET` and override the value in the `config.exs` file.



## Ash Framework

We are using the [Ash Framework](https://ash-hq.org).
