# BUILDTIME INSTRUCTIONS

if [ "$(id -u)" = "${USER_ID}" ] && [ ! -f "${HOME}/.gitconfig" ]; then
  git config --global --add safe.directory "*"

  if [ -z "$(git config --global user.name)" ]; then
    git config --global user.name "${USER_NAME}"
  fi

  if [ -z "$(git config --global user.email)" ]; then
    git config --global user.email "${USER_NAME}@gmail.com"
  fi
fi

# RUNTIME INSTRUCTIONS
