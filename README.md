# Omedis

To start your Phoenix server:

- Use [`mise`](https://mise.jdx.dev) or [`asdf`](https://asdf-vm.com) to install the correct versions of Erlang, Elixir and Node.js (check [`.tool-versions`](.tool-versions) file)
- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# Seed data

If you want to seed the database with demo data, run `mix seed.demo`. You can safely run it as many times as you want without duplicating the data.
Those demo seeds include test accounts with the following email addresses:

- **user@demo.com**
- **user2@demo.com**
- **user3@demo.com**

You can log in on the UI with any of the above email addresses, with the password: **password**.

The demo seeds file can be found [here](priv/repo/demo_seeds.exs).

# Developers

Please use the Pull Request workflow to submit your changes. For a guide on how to create Pull Requests, check out [GitHub's tutorial on creating a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request).

If that seems to be too complicated:
Use https://gitbutler.com to create a pull request.

## Contributing

Make sure to execute `mix check_code` in order to run all the checks before committing the code.

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

## Adding New Words to the Gettext Setup

When developing new features or updating static content in the application, follow the steps below to ensure all user-facing text is translatable using Gettext.

### 1. Use `with_locale/2` in Static HTML

For any static text added to your templates or views, wrap it with the `with_locale/2` function to ensure it can be translated based on the user's language preference. The syntax is as follows:

```elixir
with_locale(@language, fn -> gettext("Your New Text Here") end)
```

Make sure that every piece of new static text is wrapped in this function to ensure proper localization.

### Extract New Translations

Once you've added new text to the code, extract the translations into the .po files for each language using the following Mix task:

```
mix gettext.extract --merge
```

This command will:

Scan your project for any new calls to gettext/1.
Update the .po files located under priv/gettext/<language> directories, adding new entries for the texts you've marked as translatable.

### Update Translations

After running the extract command, navigate to the .po files in priv/gettext for each language. The new entries will appear as empty translations like this:

```
# priv/gettext/<language>/LC_MESSAGES/default.po


msgid "Your New Text Here"
msgstr ""
```

For each new entry, provide the appropriate translation by updating the msgstr value.

Example for French:

```
msgid "Your New Text Here"
msgstr "Votre nouveau texte ici"
```

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

```

```

## Configuration

### Auto-disappearing flash messages

To enable auto-disappearing flash messages, set the `FLASH_AUTO_DISAPPEAR` environment variable to an integer representing the delay in seconds. E.g.

```
FLASH_AUTO_DISAPPEAR=3
```

will make flash messages disappear after 3 seconds.

To disable, set to 0.

The default is 4 seconds.
