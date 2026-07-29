function sp
    set dir (scout --no-tmux)

    if test -n "$dir"
        cd "$dir"
    end
end
