function set_git_author -d "set user.name and user.email"
  if test (count $argv) -eq 2
    git config --local user.name $argv[1]
    git config --local user.email $argv[2]
  else
    echo "set_git_author user.name user.email"
  end
end

