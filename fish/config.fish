function add_path_if_need
  set result (false)
  for v in $argv
    contains $v $PATH -- or (contains $v $fish_user_paths)
    if test $status -ne 0
      echo "Add $v to $fish_user_paths"
      set -U fish_user_paths $v fish_user_paths
      set result (true)
    end
  end

  return $result
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

setup_rust
setup_starship
