function worktree-rm --description "Remove current git worktree and switch back to main"
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: not in a git repository"
        return 1
    end

    # Only allow from a linked worktree, not the main one
    set git_dir (git rev-parse --git-dir)
    if test "$git_dir" = ".git"
        echo "Error: refusing to remove the main worktree"
        return 1
    end

    set current (pwd)
    set main_worktree (git worktree list --porcelain | head -1 | string replace "worktree " "")

    cd $main_worktree
    git worktree remove $current
end
