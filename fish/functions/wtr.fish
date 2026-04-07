function wtr --description "Remove current worktree and kill the current pane"
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
    set main_worktree (git worktree list --porcelain | head -1 | string replace "worktree " "")

    # Remove the worktree
    git -C $main_worktree worktree remove $current

    # Kill the current pane
    tmux kill-pane
end
