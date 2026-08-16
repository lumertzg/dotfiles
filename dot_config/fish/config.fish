set fish_greeting ""
set -g __fish_git_prompt_showdirtystate yes
set -g __fish_git_prompt_showuntrackedfiles yes
set -g __fish_git_prompt_showstashstate yes
set -g __fish_git_prompt_showupstream informative
set -g __fish_git_prompt_char_dirtystate '!'
set -g __fish_git_prompt_char_stagedstate '+'
set -g __fish_git_prompt_char_untrackedfiles '?'
set -g __fish_git_prompt_char_invalidstate '='
set -g __fish_git_prompt_char_stashstate '$'
set -g __fish_git_prompt_char_upstream_ahead '⇡'
set -g __fish_git_prompt_char_upstream_behind '⇣'
set -g __fish_git_prompt_char_upstream_diverged '⇕'

fish_add_path $HOME/.cargo/bin $HOME/go/bin $HOME/.odin $HOME/.local/bin $HOME/scripts

set -gx EDITOR nvim
set -gx SCOUT_BACKEND tmux
set -gx KUBE_EDITOR nvim
set -gx MANPAGER "nvim +Man!"

if status is-interactive
    bind \cY accept-autosuggestion
    bind \cE edit_command_buffer

    alias vim "nvim"
    alias k "kubectl"
    alias lg "lazygit"

    if type -q bat
        alias cat "bat"
    end
end

if type -q mise
    if status is-interactive
        mise activate fish | source
    else
        mise activate fish --shims | source
    end
end
