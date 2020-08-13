#!/bin/bash
#
### distcc.sh(1)           DistCC remote auto-job script        distcc.sh(1) ###
#
# NAME
#
#    distcc.sh - DistCC remote auto-job script
#
# SYNOPSIS
#
#    source distcc.sh; distcc_build make my_target
#
# DESCRIPTION
#
#    Helper script that allows remotely building through distcc(1).
#    Instead of just having distcc rely on its DISTCC_HOSTS environment
#    variable and the --jobs argument of the build tool given by the user,
#    this script automatically checks the available remotes and selects a
#    good enough job count.
#
#    This script depends on having ccache(1) installed and configured as your
#    C(++) building system. This generally means that the CC and CXX compilers
#    in your build process should come from /usr/lib/ccache.
#
#    A caveat built into this script is that the build machines should be
#    accessible as a local port. But this makes this script synergise well
#    with SSH tunnels.
#
# ENVIRONMENT VARIABLES
#
#    DCCSH_DEBUG           Define the environment variable if you want some
#                          debug messages printed.
#                          By default not set, and no debug is printed.
#
#    DISTCC_PORTS          A string in the format of "port/jobs port/jobs"
#                          that specifies which ports should be used as build
#                          machines and which machine can handle how many jobs.
#                          Default empty value means no remote builds.
#
#    DISTCC_NUM_FIRST_LOCAL
#                          The number of jobs to prefer handling locally,
#                          before giving work to the build machines.
#                          Recommended to set to a small enough number so that
#                          compilations of a few translation units do not load
#                          the network.
#                          Defaults to 0, in which case only remote build
#                          happens.
#
#    DISTCC_NUM_ONLY_LOCAL
#                          The number of jobs to run locally if *NO* remote
#                          machines are found available.
#                          Defaults to $(nproc), the number of cores available.
#
#    DISTCC_LOCAL_MEM      The amount of memory *in MiB* to require to be free
#                          per thread of compilation that is executed
#                          *locally*. The local compilations include at most
#                          DISTCC_NUM_FIRST_LOCAL jobs if remotes are found,
#                          or DISTCC_NUM_ONLY_LOCAL if no remotes work.
#
#
# HOW TO SET UP SSH TUNNEL
#
#    In your SSH configuration file (conventionally ~/.ssh/config) use the
#    following template for a build worker machine:
#
#        AddKeysToAgent yes
#
#        Host mybuild1
#            HostName mybuild1.awesomedistcc.example.com
#            Port 22
#            User user
#            LocalForward 3632 localhost:3632    # NOTE: Important line!
#
#    Before executing the build, create an SSH tunnel. The first command loads
#    the connection in the foreground and asks for your SSH key's password
#    (if any), allowing the second command to run in the background.
#    (Otherwise, the asking-for-key-unlock would wait indefinitely.)
#
#        ssh mybuild1 'exit'; ssh -CNq mybuild1 &!
#
# EXIT CODES
#
#    When not indicated otherwise, this script returns the exit code of the
#    build invocation.
#
#    The build invocation might have various exit codes, depending on whether
#    it goes through CMake, the build wrangler is GNU make or ninja, what
#    compiler is used.
#
#    In addition, this script generates the following error conditions:
#
#    -6                    Returned if not enough memory are present to run
#                          local compilations.
#
# AUTHOR
#
#    Whisperity (http://github.com/Whisperity)
################################################################################

# Prints arguments if debug mode is enabled.
function _dccsh_debug() {
    if [ -z "$DCCSH_DEBUG" ]; then
        return
    fi

    local PREVIOUS_DEBUG_WAS_NEWLINE=$_ECHO_N

    _ECHO_N=""
    if [ "$1" == "-n" ]; then
        _ECHO_N="-n"
        shift 1
    fi

    local FUNCNAME_PREFIX="${FUNCNAME[1]}:"
    if [ "$PREVIOUS_DEBUG_WAS_NEWLINE" == "-n" ]; then
        FUNCNAME_PREFIX=""
    fi
    echo $_ECHO_N "$FUNCNAME_PREFIX" "$@" >&2
}

function _dccsh_dump_config() {
    _dccsh_debug "DISTCC_PORTS:           $DISTCC_PORTS"
    _dccsh_debug "DISTCC_NUM_FIRST_LOCAL: $DISTCC_NUM_FIRST_LOCAL"
    _dccsh_debug "DISTCC_NUM_ONLY_LOCAL:  $DISTCC_NUM_ONLY_LOCAL"
    _dccsh_debug "DISTCC_LOCAL_MEM:       $DISTCC_LOCAL_MEM"
}

# Returns true if $1 is listening on the local machine.
function check_tcp4port_listen() {
    _dccsh_debug -n "Check port $1..."

    ss -lt4 | grep ":$1" &>/dev/null
    local R=$?

    _dccsh_debug -n "    is listening? "
    if [ $R -eq 0 ]; then
        _dccsh_debug "YES"
    else
        _dccsh_debug "NO"
    fi

    return $R
}

# Build by concatenating $2 port with $3 jobs after $1 DISTCC_HOSTS string.
function _dccsh_concat_port() {
    local PORT=$2
    local JOBS=$3

    if check_tcp4port_listen "$PORT"; then
        local HOST_ENTRY="127.0.0.1:$PORT/$JOBS,lzo"
        _dccsh_debug "Concatenate \"$HOST_ENTRY\" after \"$1\""
        echo $1" $HOST_ENTRY"
        return 0
    else
        echo $1
        return 1
    fi
}

# Parses the DISTCC_PORTS environmental variable.
function _dccsh_parse_distcc_ports() {
    DCCSH_HOSTS=""
    DCCSH_TOTAL_JOBS=0

    for port_and_jobs in $DISTCC_PORTS; do
        local PORT=$(echo $port_and_jobs | cut -d'/' -f 1)
        local JOBS=$(echo $port_and_jobs | cut -d'/' -f 2)
        _dccsh_debug "Adding: $PORT with $JOBS jobs..."

        DCCSH_HOSTS=$(_dccsh_concat_port "$DCCSH_HOSTS" $PORT $JOBS)
        if [ $? -eq 0 ]; then
            DCCSH_TOTAL_JOBS=$(($DCCSH_TOTAL_JOBS + $JOBS))
            _dccsh_debug "$PORT: responding, added, new total job count" \
                "is: $DCCSH_TOTAL_JOBS."
        else
            _dccsh_debug "$PORT: did not respond."
        fi
    done
}

# Adds building some TUs on the local machine to the DCCSH_ variables, based
# on environmental configuration.
function _dccsh_append_localhost() {
    if [ $DCCSH_TOTAL_JOBS -eq 0 ]; then
        _dccsh_debug "No working remote found."

        local LOCAL_JOB=$DISTCC_NUM_ONLY_LOCAL
        if [ -z $LOCAL_JOB ]; then
            _dccsh_debug "DISTCC_NUM_ONLY_LOCAL unset, defaulting to $(nproc)"
            LOCAL_JOB=$(nproc)
        fi

        _dccsh_debug "Setting execution with $LOCAL_JOB jobs locally!"
        DCCSH_HOSTS="localhost/$LOCAL_JOB"
        DCCSH_TOTAL_JOBS=$LOCAL_JOB
        DCCSH_LOCAL_JOBS=$LOCAL_JOB
    else
        _dccsh_debug "Working remotes found."

        local LOCAL_JOB=$DISTCC_NUM_FIRST_LOCAL
        if [ -z "$LOCAL_JOB" ]; then
            _dccsh_debug "DISTCC_NUM_FIRST_LOCAL unset, defaulting to 0"
            LOCAL_JOB=0
        fi

        if [ $LOCAL_JOB -gt 0 ]; then
            _dccsh_debug "Prioritising running $LOCAL_JOB jobs locally!"
            DCCSH_HOSTS="localhost/${LOCAL_JOB} $DCCSH_HOSTS"
            DCCSH_TOTAL_JOBS=$(($DCCSH_TOTAL_JOBS + $LOCAL_JOB))
        fi
        DCCSH_LOCAL_JOBS=$LOCAL_JOB
    fi
}

function _dccsh_check_memory() {
    if [ $DCCSH_LOCAL_JOBS -eq 0 ]; then
        _dccsh_debug "no local jobs, not checking memory use..."
        return 0  # OK.
    fi

    local MEM_PER_BUILD=$DISTCC_LOCAL_MEM
    if [ -z "$MEM_PER_BUILD" ]; then
        _dccsh_debug "DISTCC_LOCAL_MEM unset, defaulting to '1024'"
        MEM_PER_BUILD=1024
    fi

    _dccsh_debug "Checking if $DCCSH_LOCAL_JOBS * $MEM_PER_BUILD MiB " \
        "memory available"
    local NEEDED_MEM=$(($MEM_PER_BUILD * $DCCSH_LOCAL_JOBS))
    _dccsh_debug "Needed mem: $NEEDED_MEM MiB"
    local AVAILABLE_MEM=$(("$(free | grep 'Mem:' | awk '{ print $7 }')" / 1024))
    _dccsh_debug "Available memory right now: $AVAILABLE_MEM MiB"

    if [ $AVAILABLE_MEM -lt $NEEDED_MEM ]; then
        echo "Available memory: $AVAILABLE_MEM MiB" >&2
        echo "Needed memory: $NEEDED_MEM MiB" >&2
        return 1
    fi
}

# Appends additional jobs to the total allowed job count for preprocessing.
function _dccsh_append_preprocess_jobs() {
    _dccsh_debug "Allowing $(nproc) extra jobs for preprocessing..."
    DCCSH_TOTAL_JOBS=$(($DCCSH_TOTAL_JOBS + $(nproc)))
}

function _dccsh_cleanup_vars() {
    DCCSH_HOSTS=""
    DCCSH_TOTAL_JOBS=0
    DCCSH_LOCAL_JOBS=0
    _ECHO_N=""
}

# Actually executes the build with having DISTCC_HOSTS set and ccache set
# to run through distcc.
function _dccsh_run_distcc() {
    local DISTCC_HOSTS_STR=$1
    shift 1

    _dccsh_debug "Executing with hosts: \"$DISTCC_HOSTS_STR\""
    DISTCC_HOSTS="$DISTCC_HOSTS_STR" CCACHE_PREFIX="distcc" "$@"
}

# Prepares running the build remotely. This is the entry point of the script.
function distcc_build() {
    _dccsh_dump_config
    _dccsh_debug "command line is: \"$@\""

    _dccsh_parse_distcc_ports
    _dccsh_append_localhost

    _dccsh_check_memory
    if [ $? -ne 0 ]; then
        echo "[ERROR] Refusing to build: not enough memory for local jobs!" >&2
        return -6
    fi

    _dccsh_append_preprocess_jobs

    _dccsh_debug "Running $DCCSH_TOTAL_JOBS threads"
    _dccsh_run_distcc "$DCCSH_HOSTS" "$@" -j "$DCCSH_TOTAL_JOBS"
    local R=$?

    _dccsh_cleanup_vars

    return $R
}

