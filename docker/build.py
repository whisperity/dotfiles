#!/usr/bin/env python3
import json
import os
import shlex
import urllib.request


def get_github_repo_commit(org_or_user, repository):
    repository_data = urllib.request.urlopen(  # nosec: urllib
        "http://api.github.com/repos/{0}/{1}".format(
            org_or_user, repository
        )
    ).read().decode("utf-8")
    repository_data = json.loads(repository_data)

    print("Default branch of {0}/{1} ".format(org_or_user, repository), end='')
    default_branch = repository_data['default_branch']
    print("is {0}, at...".format(default_branch), end='')

    branch_data = urllib.request.urlopen(  # nosec: urllib
        "http://api.github.com/repos/{0}/{1}/branches/{2}".format(
            org_or_user, repository, default_branch
        )
    ).read().decode("utf-8")
    branch_data = json.loads(branch_data)

    sha = branch_data['commit']['sha']
    print(sha)
    return sha


def read_bool(prompt, default=None):
    while True:
        print(prompt, end='')
        if default is None:
            print(" [y/n]", end='')
        else:
            if default:
                print(" [Y/n]", end='')
            else:
                print(" [y/N]", end='')

        print(": ", end='')
        data = input()

        if not data:
            if default is not None:
                return default
        else:
            if str(data).lower() == "y":
                return True
            if str(data).lower() == "n":
                return False


def read_value(prompt, requested_type=str, default=None):
    while True:
        if requested_type is bool:
            return read_bool(prompt, default)

        print(prompt, end='')
        if default is not None:
            print(" [{}]".format(str(default)), end='')
        print(": ", end='')

        data = input()

        if not data:
            if default is not None:
                return default
        else:
            return requested_type(data)


neovim_sha = get_github_repo_commit("neovim", "neovim")
dotfiles_manager_sha = get_github_repo_commit("whisperity",
                                              "Dotfiles-Framework")
dotfiles_sha = get_github_repo_commit("whisperity", "Dotfiles")

image = read_value("Docker image name", str, "whisperity/dotfiles")
install_cpp = read_value("Install C++ development tools", bool, False)
install_tex = read_value("Install LaTeX development tools", bool, False)
local_user = read_value("Username", str, "username")
git_user = read_value("Git user.name", str, local_user)
git_email = read_value("Git user.email", str,
                       "{}@localhost".format(local_user))

command = ["docker", "build", ".", "-t", image,
           "--build-arg=INSTALL_CPP=YES" if install_cpp else "",
           "--build-arg=INSTALL_TEX=YES" if install_tex else "",
           "--build-arg=LOCAL_USER={}".format(local_user),
           "--build-arg=GIT_USERNAME={}".format(git_user),
           "--build-arg=GIT_EMAIL={}".format(git_email),
           "--build-arg=__CACHEBREAKER__NEOVIM={}".format(neovim_sha),
           "--build-arg=__CACHEBREAKER__DOTFILES_FRAMEWORK={}".format(
               dotfiles_manager_sha),
           "--build-arg=__CACHEBREAKER__DOTFILES={}".format(dotfiles_sha)
           ]
command = list(map(shlex.quote, filter(lambda x: x, command)))

with open("build.sh", "w") as handle:
    print("#!/bin/bash", file=handle)
    print(" ".join(command), file=handle)
    print("rm build.sh", file=handle)

os.chmod("build.sh", 0o755)

print("Execute build.sh")
