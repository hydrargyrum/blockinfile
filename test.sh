#!/bin/sh -eu
# shellcheck enable=

cd "$(dirname "$0")"

got=$(mktemp test.blockinfile.XXXXXX)
trap 'rm "$got"' EXIT


init () {
	cat > "$got"
	./blockinfile/blockinfile.py --path "$got" "$@"
}

check () {
	diff -u - "$got"
}


# no block
init <<- EOF
	foo bar
	baz
EOF
check <<- EOF
	foo bar
	baz
EOF

# new block
init --block "$(echo testing; echo a block)" <<- EOF
	foo bar
	baz
EOF
check <<- EOF
	foo bar
	baz
	# BEGIN ANSIBLE MANAGED BLOCK
	testing
	a block
	# END ANSIBLE MANAGED BLOCK
EOF

# change block
init --block "new block content" <<- EOF
	foo bar
	# BEGIN ANSIBLE MANAGED BLOCK
	testing
	a block
	# END ANSIBLE MANAGED BLOCK
	baz
EOF
check <<- EOF
	foo bar
	# BEGIN ANSIBLE MANAGED BLOCK
	new block content
	# END ANSIBLE MANAGED BLOCK
	baz
EOF

# delete block
init <<- EOF
	foo bar
	# BEGIN ANSIBLE MANAGED BLOCK
	testing
	a block
	# END ANSIBLE MANAGED BLOCK
	baz
EOF
check <<- EOF
	foo bar
	baz
EOF

# custom labels
init --marker "# marker: {mark}" --marker-begin "{{{" --marker-end "}}}" --block "new block content" <<- EOF
	foo bar
	# marker: {{{
	testing
	a block
	# marker: }}}
	baz
EOF
check <<- EOF
	foo bar
	# marker: {{{
	new block content
	# marker: }}}
	baz
EOF
