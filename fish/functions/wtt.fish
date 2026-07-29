function wtt --description "Re-tag all tmux panes with their current git branch"
    if not set -q TMUX
        echo "Error: must be inside tmux"
        return 1
    end

    set tagged 0
    set skipped 0

    for line in (tmux list-panes -a -F '#{pane_id}'\t'#{pane_current_path}')
        set parts (string split \t -- $line)
        set pane_id $parts[1]
        set path $parts[2]

        if not git -C $path rev-parse --git-dir >/dev/null 2>&1
            set skipped (math $skipped + 1)
            continue
        end

        set branch (git -C $path symbolic-ref --short HEAD 2>/dev/null)
        if test -z "$branch"
            set skipped (math $skipped + 1)
            continue
        end

        tmux set-option -p -t $pane_id @wt_label "$branch"
        set tagged (math $tagged + 1)
    end

    echo "Tagged $tagged panes, skipped $skipped"
end
