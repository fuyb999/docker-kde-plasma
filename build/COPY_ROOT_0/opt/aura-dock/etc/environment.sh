# BUILDTIME INSTRUCTIONS

if [ "$(id -u)" = "${USER_ID}" ] && [ ! -f "${HOME}/.gitconfig" ]; then
  git config --global --add safe.directory "*"
fi

# RUNTIME INSTRUCTIONS
