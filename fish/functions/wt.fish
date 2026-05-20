function wt --description "Create a git worktree and start claude in it"
    if not set -q TMUX
        echo "Error: must be inside tmux"
        return 1
    end

    if test (count $argv) -lt 1
        echo "Usage: wt <branch-name>"
        return 1
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: not in a git repository"
        return 1
    end

    set branch $argv[1]
    set main_worktree (git worktree list --porcelain | head -1 | string replace "worktree " "")
    set repo_name (basename $main_worktree)
    set worktree_path (dirname $main_worktree)/$repo_name-$branch

    if git show-ref --verify --quiet refs/heads/$branch
        git worktree add $worktree_path $branch
    else
        git worktree add -b $branch $worktree_path main
    end
    or return 1

    cd $worktree_path
    tmux set-option -p -t $TMUX_PANE @wt_label "claude:$branch"
    claude
end
