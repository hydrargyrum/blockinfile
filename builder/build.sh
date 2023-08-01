#!/bin/sh -eu
# SPDX-License-Identifier: GPL-3.0-only

cd "$(dirname "$0")"
FILE=blockinfile.py

echo "= Building environment ============================="

mkdir -p env
python3 -m venv env
. ./env/bin/activate

python3 -m pip install -r requirements.txt

echo "= Patching file ===================================="

cp env/lib/python3*/site-packages/ansible/modules/"$FILE" .

# __future__ imports are useless for us, and they cry if not imported early so
# delete them
sed -i '/^from ansible/d ; /^from __future__ import/d' "$FILE"

# it seems sed's "r" command forcefully prepends the pattern space
# so it's hard to find a place where to inject our code…
# inject the shebang here too
sed -i '1 {
	s@.*@#!/usr/bin/env python3@
	r insert.txt
}' "$FILE"
chmod +x "$FILE"

# get ansible version
python3 -c "import ansible.release as R; print(f'__version__ = {R.__version__!r}')" > __init__.py

echo "= Move to package =================================="

mv __init__.py "$FILE" ../blockinfile/

echo "= Done! ============================================"
