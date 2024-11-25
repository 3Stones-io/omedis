.PHONY: check-gettext

check-gettext:
	@mix gettext.extract --merge > /dev/null 2>&1
	@if ! git diff --quiet priv/gettext; then \
		echo '❌ Found uncommitted Gettext translation changes!' && \
		echo '\nModified files:' && \
		git diff --name-only priv/gettext | sed 's/^/  - /' && \
		echo '\nTo fix this:' && \
		echo '1. Run "mix gettext.extract --merge" locally' && \
		echo '2. Review and commit the changes' && \
		echo '3. Push the updates to your branch\n' && \
		exit 1; \
	fi
