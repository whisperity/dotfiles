# Load binaries from the TeX-Live installation.
TEX_BINDIR="${HOME}/opt/texlive/texlive/bin/*"

if [[ ":${PATH}:" != *":${TEX_BINDIR}:"* ]]
then
  # The echo trick here is to force expansion of the * characters above.
  export PATH="$(echo ${TEX_BINDIR}):${PATH}"
fi
