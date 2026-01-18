function glo
    if test (count $argv) -eq 0
        git log --oneline
    else
        git log --oneline -n $argv[1]
    end
end
