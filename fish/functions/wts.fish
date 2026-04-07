function wts --description "Switch current pane to a git worktree via fzf"
    if not set -q TMUX
        echo "Error: must be inside tmux"
        return 1
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: not in a git repository"
        return 1
    end

    set selected (git worktree list | fzf --height=40% --reverse | awk '{print $1}')

    if test -n "$selected"
        cd $selected
    end
end
