function sp
    set dir (scout --backend path)

    if test -n "$dir"
        cd "$dir"
    end
end
