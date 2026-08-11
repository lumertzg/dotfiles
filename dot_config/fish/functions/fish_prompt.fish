function fish_prompt
    set -l last_status $status

    echo -n -s (set_color cyan) (path basename (prompt_pwd)) (set_color normal)

    set -l git_info (string split -m 1 ' ' -- (fish_git_prompt '%s'))

    if set -q git_info[1]
        echo -n -s ' on ' (set_color magenta) $git_info[1] (set_color normal)

        if set -q git_info[2]
            echo -n -s ' ' (set_color red) '[' $git_info[2] ']' (set_color normal)
        end
    end

    echo

    if test $last_status -ne 0
        echo -n -s (set_color red) "[$last_status]" (set_color normal) ' '
    end

    echo -n -s (set_color --bold green) '> ' (set_color normal)
end
