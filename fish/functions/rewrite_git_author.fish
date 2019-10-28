function rewrite_git_author -d "rewrite_git_author 'old_name' 'old_email' 'new_name' 'new_email'"
  if test (count $argv) -eq 4
    set old_name $argv[1]
    set old_email $argv[2]
    set new_name $argv[3]
    set new_email $argv[4]
    echo "rewrite $old_name <$old_email> -> $new_name <$new_email>"
    git filter-branch -f --env-filter "GIT_AUTHOR_NAME=$new_name; GIT_AUTHOR_EMAIL=$new_email; GIT_COMMITTER_NAME=$old_name; GIT_COMMITTER_EMAIL=$old_email;" HEAD;
  else
    echo "rewrite_git_author 'old_name' 'old_email' 'new_name' 'new_email'"
    return (true)
  end
end

