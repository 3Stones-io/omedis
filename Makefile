
.PHONY: check-gettext
check-gettext:
	@output=$$(mix gettext.extract --merge 2>&1) && \
	if ! git diff --quiet priv/gettext; then \
		echo '❌ Found uncommitted Gettext translation changes!\n\nModified files:' && \
		git diff --name-only priv/gettext | sed 's/^/  - /' && \
		echo '\nTo fix this:\n1. Run "mix gettext.extract --merge" locally\n2. Review and commit the changes\n3. Push the updates to your branch\n' && \
		exit 1; \
	fi