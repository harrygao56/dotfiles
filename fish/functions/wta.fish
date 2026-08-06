function wta --description "Create a git worktree in a new pane and launch a coding agent in it"
    argparse 'a/agent=' 's/seed=' -- $argv
    or return 2

    if not set -q TMUX
        echo "Error: must be inside tmux"
        return 1
    end

    if test (count $argv) -lt 1
        echo "Usage: wta <branch-name> [-a|--agent codex|claude] [-s|--seed <file>]"
        return 1
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: not in a git repository"
        return 1
    end

    set agent codex
    if set -q _flag_agent
        set agent $_flag_agent
    end
    if test "$agent" != codex -a "$agent" != claude
        echo "Error: --agent must be 'codex' or 'claude' (got '$agent')"
        return 1
    end

    if set -q _flag_seed; and not test -r "$_flag_seed"
        echo "Error: seed file not readable: $_flag_seed"
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

    # Spawn the agent in a new pane in the same window, labelled with the branch.
    set new_pane (tmux split-window -c $worktree_path -P -F '#{pane_id}')
    tmux set-option -p -t $new_pane @wt_label "$branch"

    # Seed the agent via a file path, never a long argv element: endpoint
    # security kills node on argv over ~1KB, so we pass a short "read this file"
    # instruction instead of the prompt itself.
    if set -q _flag_seed
        set launch "$agent \"Read $_flag_seed and start implementing. Follow its instructions.\""
    else
        set launch $agent
    end
    tmux send-keys -t $new_pane -- $launch Enter

    # Rebalance into the even grid (same as prefix + =).
    set window_id (tmux display-message -p '#{window_id}')
    $HOME/dotfiles/tmux/pane-tools.sh rebalance $window_id
end
