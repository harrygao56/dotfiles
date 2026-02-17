function worktree --description "Create a git worktree from main"
    if test (count $argv) -lt 1
        echo "Usage: worktree <branch-name>"
        return 1
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: not in a git repository"
        return 1
    end

    # Only allow from the main worktree, not a linked one
    set git_dir (git rev-parse --git-dir)
    if test "$git_dir" != ".git"
        echo "Error: must run from the main worktree, not a linked worktree"
        return 1
    end

    set branch $argv[1]
    set repo_root (git rev-parse --show-toplevel)
    set repo_name (basename $repo_root)
    set worktree_path (dirname $repo_root)/$repo_name-$branch

    git worktree add -b $branch $worktree_path main
    and cd $worktree_path
end
