# Load binaries from the TeX-Live installation.
TEX_BINDIR="${HOME}/.local/share/texlive/*/bin/*"
# The echo trick here is to force expansion of the * characters above.
TEX_BINDIR=$(echo ${TEX_BINDIR} | tr ' ' '\n' | sort -V -r | head -n 1)

if [[ ":${PATH}:" != *":${TEX_BINDIR}:"* ]]
then
  export PATH="${TEX_BINDIR}:${PATH}"
fi
