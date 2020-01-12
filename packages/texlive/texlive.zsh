setopt nullglob

# Load binaries from the TeX-Live installation.
texbins=(${HOME}/opt/texlive/*/bin/*)
texbin=${texbins[-1]}

if [[ ! -z $texbin && ${path[(ie)$texbin]} -gt ${#path} ]]
then
    path=($texbin $path)
fi

unsetopt nullglob
