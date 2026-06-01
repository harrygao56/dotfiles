function wtr --description "Remove current worktree, delete its branch, and kill the current pane"
    if not set -q TMUX
        echo "Error: must be inside tmux"
        return 1
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: not in a git repository"
        return 1
    end

    # Don't allow removing the main worktree
    set git_dir (git rev-parse --git-dir)
    if test "$git_dir" = ".git"
        echo "Error: refusing to remove the main worktree"
        return 1
    end

    set current (pwd)
    set branch (git symbolic-ref --short HEAD 2>/dev/null)
    set main_worktree (git worktree list --porcelain | head -1 | string replace "worktree " "")

    # Remove the worktree. Bail if it fails (e.g. dirty tree) so we don't kill
    # the pane and leave an invisible orphaned worktree behind.
    if not git -C $main_worktree worktree remove $current
        echo "Worktree not removed. To force: git -C $main_worktree worktree remove --force $current"
        return 1
    end

    # `worktree remove` leaves the branch behind; delete it. Safe -d won't drop
    # unmerged work — fall back to printing the manual -D command.
    if test -n "$branch"
        if not git -C $main_worktree branch -d $branch
            echo "Note: branch '$branch' kept (unmerged). To delete: git -C $main_worktree branch -D $branch"
        end
    end

    # Sweep any stale admin entries from prior out-of-band removals.
    git -C $main_worktree worktree prune

    # Kill the current pane
    tmux kill-pane
end
