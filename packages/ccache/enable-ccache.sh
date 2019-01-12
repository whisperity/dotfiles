if [[ ":$PATH:" != *":/usr/lib/ccache:"* ]]
then
  export PATH="/usr/lib/ccache:${PATH}"
fi
