#!/bin/sh

test_description='prune $GIT_DIR/worktrees'

. ./test-lib.sh

test_expect_success 'prune --worktrees on normal repo' '
	git prune --worktrees &&
	test_must_fail git prune --worktrees abc
'

test_expect_success 'prune files inside $GIT_DIR/worktrees' '
	mkdir .git/worktrees &&
	: >.git/worktrees/abc &&
	git prune --worktrees --verbose >actual &&
	cat >expect <<EOF &&
Removing worktrees/abc: not a valid directory
EOF
	test_i18ncmp expect actual &&
	! test -f .git/worktrees/abc &&
	! test -d .git/worktrees
'

test_expect_success 'prune directories without gitdir' '
	mkdir -p .git/worktrees/def/abc &&
	: >.git/worktrees/def/def &&
	cat >expect <<EOF &&
Removing worktrees/def: gitdir file does not exist
EOF
	git prune --worktrees --verbose >actual &&
	test_i18ncmp expect actual &&
	! test -d .git/worktrees/def &&
	! test -d .git/worktrees
'

test_expect_success POSIXPERM 'prune directories with unreadable gitdir' '
	mkdir -p .git/worktrees/def/abc &&
	: >.git/worktrees/def/def &&
	: >.git/worktrees/def/gitdir &&
	chmod u-r .git/worktrees/def/gitdir &&
	git prune --worktrees --verbose >actual &&
	test_i18ngrep "Removing worktrees/def: unable to read gitdir file" actual &&
	! test -d .git/worktrees/def &&
	! test -d .git/worktrees
'

test_expect_success 'prune directories with invalid gitdir' '
	mkdir -p .git/worktrees/def/abc &&
	: >.git/worktrees/def/def &&
	: >.git/worktrees/def/gitdir &&
	git prune --worktrees --verbose >actual &&
	test_i18ngrep "Removing worktrees/def: invalid gitdir file" actual &&
	! test -d .git/worktrees/def &&
	! test -d .git/worktrees
'

test_expect_success 'prune directories with gitdir pointing to nowhere' '
	mkdir -p .git/worktrees/def/abc &&
	: >.git/worktrees/def/def &&
	echo "$(pwd)"/nowhere >.git/worktrees/def/gitdir &&
	git prune --worktrees --verbose >actual &&
	test_i18ngrep "Removing worktrees/def: gitdir file points to non-existent location" actual &&
	! test -d .git/worktrees/def &&
	! test -d .git/worktrees
'

test_expect_success 'not prune locked checkout' '
	test_when_finished rm -r .git/worktrees
	mkdir -p .git/worktrees/ghi &&
	: >.git/worktrees/ghi/locked &&
	git prune --worktrees &&
	test -d .git/worktrees/ghi
'

test_expect_success 'not prune recent checkouts' '
	test_when_finished rm -r .git/worktrees
	mkdir zz &&
	mkdir -p .git/worktrees/jlm &&
	echo "$(pwd)"/zz >.git/worktrees/jlm/gitdir &&
	git prune --worktrees --verbose --expire=2.days.ago &&
	test -d .git/worktrees/jlm
'

test_done