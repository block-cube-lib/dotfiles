function git_author -d "display git user.name and user.email"
  echo "name : " (git config --local user.name)
  echo "email: " (git config --local user.email)
end
