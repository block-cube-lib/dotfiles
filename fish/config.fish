function add_path_if_need
  set result (false)
  for v in $argv
    contains $v $PATH -- or (contains $v $fish_user_paths)
    if test $status -ne 0
      echo "Add $v to $fish_user_paths"
      set -U fish_user_paths $v $fish_user_paths
      set result (true)
    end
  end

  return $result
end

function setup_fisher
  type -q fisher
  if test $status -ne 0
    echo "install fisher"
    curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish
  end
end

function setup_z
  type -q z
  if test $status -ne 0
    echo "install z"
    fisher add jethrokuan/z
  end
end

function setup_rust
  type -q cargo
  if test $status -ne 0
    echo "install rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  end
  add_path_if_need $HOME/.cargo/bin
end

function setup_starship
  type -q starship
  if test $status -ne 0
    echo "install starship"
    cargo install starship
  end

  eval (starship init fish)
end

setup_fisher
setup_z

setup_rust
setup_starship

# setup pyenv
type -q pyenv
if test $status -eq 0
  source (pyenv init - | psub)
end

# setup rbenv
type -q rbenv
if test $status -eq 0
  source (rbenv init - | psub)
end
