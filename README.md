# Omedis

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Move to the assets folder with `cd assets` and run `npm install` to install the frontend dependencies.
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
config :omedis, :token_signing_secret, System.get_env("TOKEN_SIGNING_SECRET") || "Lu8xpRC9"
```

This can also be set as an environment variable `TOKEN_SIGNING_SECRET` and override the value in the `config.exs` file.

## Ash Framework

We are using the [Ash Framework](https://ash-hq.org).

## System Admins

Most times system admin work is done with the web GUI. But sometimes it is handy to do this work in the CLI. Here are some examples.

### Add a User

To add a user , you can use the following code in the IEx console.
To create a user you need to provide the following information:
email, hashed_password, first_name, last_name , gender and birthdate.

```
alias Omedis.Accounts.User

User.create(%{email: "wintermeyer@gmail.com" , hashed_password: Bcrypt.hash_pwd_salt("password"),first_name: "Stefan", last_name: "Wintermeyer", gender: "Male", birthdate: "1980-01-01"})
```

### Update a User

To update the user with the email address `example@example.com` you

```
alias Omedis.Accounts.User

{:ok , user} = User.by_email("example@example.com")
User.update(user, %{first_name: "Stefan" })
```

### Delete a User

To delete the user with the email address `example@example.com` you ...

```
alias Omedis.Accounts.User

{:ok , user} = User.by_email("example@example.com")
User.destroy(user)
```
