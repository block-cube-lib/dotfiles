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
  fish_add_path $HOME/.cargo/bin
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
