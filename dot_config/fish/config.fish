set fish_greeting ""

set -U fish_user_paths $HOME/.cargo/bin/ $fish_user_paths
set -U fish_user_paths $HOME/go/bin $fish_user_paths
set -U fish_user_paths $HOME/.odin/ $fish_user_paths
set -U fish_user_paths $HOME/.local/bin $fish_user_paths
set -U fish_user_paths $HOME/scripts $fish_user_paths

set -gx EDITOR nvim
set -gx SCOUT_BACKEND kitty
set -gx KUBE_EDITOR nvim
set -gx MANPAGER "nvim +Man!"

bind \cY accept-autosuggestion
bind \cE edit_command_buffer

alias vim "nvim"
alias k "kubectl"
alias lg "lazygit"

if type -q bat
    alias cat "bat"
end

if type -q starship
    starship init fish | source
end

if type -q mise 
    if status is-interactive
        mise activate fish | source
    else
        mise activate fish --shims | source
    end
end
