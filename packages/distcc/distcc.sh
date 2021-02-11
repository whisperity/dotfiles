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
#    This script requires calling a build tool that can accept a '-j'
#    parameter. The above example in :SYNOPSIS can, for example, expand to:
#
#        DISTCC_HOSTS="foo/8" make my_target -j8
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
#    DISTCC_NUM_LOCAL_SCALING
#                          If defined and too much memory would be needed by
#                          the local jobs (as calculated by
#                          DISTCC_NUM_{FIRST|ONLY}_LOCAL * DISTCC_LOCAL_MEM),
#                          instead of bailing out immediately, scale down the
#                          number of local jobs to a manageable amount.
#                          Defaults to empty value which means prefer bailing.
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
function _dccsh_debug {
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

function _dccsh_dump_config {
    _dccsh_debug "DISTCC_PORTS:             $DISTCC_PORTS"
    _dccsh_debug "DISTCC_NUM_FIRST_LOCAL:   $DISTCC_NUM_FIRST_LOCAL"
    _dccsh_debug "DISTCC_NUM_ONLY_LOCAL:    $DISTCC_NUM_ONLY_LOCAL"
    _dccsh_debug "DISTCC_NUM_LOCAL_SCALING: $DISTCC_NUM_LOCAL_SCALING"
    _dccsh_debug "DISTCC_LOCAL_MEM:         $DISTCC_LOCAL_MEM"
}

# Returns true if $1 is listening on the local machine.
function check_tcpport_listen {
    _dccsh_debug -n "Check port $1..."

    ss -lnt | \
        tail -n +2 | \
        awk '{ print $4; }' | \
        awk -F":" '{ print $NF; }' | \
        grep "$1" \
        &>/dev/null
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
function _dccsh_concat_port {
    local PORT=$2
    local JOBS=$3

    if check_tcpport_listen "$PORT"; then
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
function _dccsh_parse_distcc_ports {
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
                "is: $DCCSH_TOTAL_JOBS"
        else
            _dccsh_debug "$PORT: did not respond."
        fi
    done
}

# Calculates how many local *compiling* workers are allowed, based on user
# configuration.
# Parameters: $1 - DISTCC_NUM_ONLY_LOCAL, $2 - DISTCC_NUM_FIRST_LOCAL.
function _dccsh_calculate_local_workers {
    if [ $DCCSH_TOTAL_JOBS -eq 0 ]; then
        _dccsh_debug "No working remote found."

        local LOCAL_JOB=$1
        if [ -z $LOCAL_JOB -o $LOCAL_JOB -eq -1 ]; then
            _dccsh_debug "DISTCC_NUM_ONLY_LOCAL unset, defaulting to '$(nproc)'"
            LOCAL_JOB=$(nproc)
        fi
    else
        _dccsh_debug "Working remotes found."

        local LOCAL_JOB=$2
        if [ -z "$LOCAL_JOB" -o $LOCAL_JOB -eq -1 ]; then
            _dccsh_debug "DISTCC_NUM_FIRST_LOCAL unset, defaulting to '0'"
            LOCAL_JOB=0
        fi
    fi

    _dccsh_debug "Setting execution with $LOCAL_JOB jobs locally!"
    DCCSH_LOCAL_JOBS=$LOCAL_JOB
}

# Adds building some TUs on the local machine to the DCCSH_ variables, based
# on environmental configuration.
function _dccsh_append_localhost {
    if [ $DCCSH_LOCAL_JOBS -gt 0 ]; then
        _dccsh_debug "Prioritising running $DCCSH_LOCAL_JOBS jobs locally!"
        DCCSH_HOSTS="localhost/${DCCSH_LOCAL_JOBS} $DCCSH_HOSTS"
        DCCSH_TOTAL_JOBS=$(($DCCSH_TOTAL_JOBS + $DCCSH_LOCAL_JOBS))
    else
        _dccsh_debug "Local job count was $DCCSH_LOCAL_JOBS, not appending" \
            "'localhost'"
    fi
}

# Checks whether there is enough memory available for all the local jobs.
function _dccsh_check_memory {
    if [ $DCCSH_LOCAL_JOBS -eq 0 ]; then
        _dccsh_debug "no local jobs, not checking memory use..."
        return 0  # OK.
    fi

    DCCSH_MEM_PER_BUILD=$DISTCC_LOCAL_MEM
    if [ -z "$DCCSH_MEM_PER_BUILD" ]; then
        _dccsh_debug "DISTCC_LOCAL_MEM unset, defaulting to '1024'"
        DCCSH_MEM_PER_BUILD=1024
    fi

    _dccsh_debug "Checking if $DCCSH_LOCAL_JOBS * $DCCSH_MEM_PER_BUILD MiB" \
        "memory available"
    local NEEDED_MEM=$(($DCCSH_MEM_PER_BUILD * $DCCSH_LOCAL_JOBS))
    _dccsh_debug "Needed mem: $NEEDED_MEM MiB"
    local AVAILABLE_MEM=$(("$(free | grep 'Mem:' | awk '{ print $7 }')" / 1024))
    _dccsh_debug "Available memory right now: $AVAILABLE_MEM MiB"

    if [ $AVAILABLE_MEM -lt $NEEDED_MEM ]; then
        echo "Available memory: $AVAILABLE_MEM MiB" >&2
        echo "Needed memory: $NEEDED_MEM MiB" >&2
        return 1
    fi
}

# Scales down how much local workers could be done based on the environment and
# available resources.
function _dccsh_scale_local_workers {
    if [ -z "$DISTCC_NUM_LOCAL_SCALING" ]; then
        _dccsh_debug "Refusing to scale: user did not specify" \
            "'DISTCC_NUM_LOCAL_SCALING'"
        echo 0
        return
    fi

    local AVAILABLE_MEM=$(("$(free | grep 'Mem:' | awk '{ print $7 }')" / 1024))
    local NEW_WORKER_COUNT=$(($AVAILABLE_MEM / $DCCSH_MEM_PER_BUILD))
    _dccsh_debug "Scaling local worker count to $NEW_WORKER_COUNT to fit memory"

    echo $NEW_WORKER_COUNT
}

# Appends additional jobs to the total allowed job count for preprocessing.
function _dccsh_append_preprocess_jobs {
    _dccsh_debug "Allowing $(nproc) extra jobs for preprocessing..."
    DCCSH_TOTAL_JOBS=$(($DCCSH_TOTAL_JOBS + $(nproc)))
}

function _dccsh_cleanup_vars {
    DCCSH_HOSTS=""
    DCCSH_TOTAL_JOBS=0
    DCCSH_LOCAL_JOBS=0
    DCCSH_MEM_PER_BUILD=0
    _ECHO_N=""
}

# Actually executes the build with having DISTCC_HOSTS set and ccache set
# to run through distcc.
function _dccsh_run_distcc {
    local DISTCC_HOSTS_STR=$1
    shift 1

    _dccsh_debug "Executing with hosts: \"$DISTCC_HOSTS_STR\""
    _dccsh_debug "Executed command line: $@"
    DISTCC_HOSTS="$DISTCC_HOSTS_STR" CCACHE_PREFIX="distcc" $*
}

# Prepares running the build remotely. This is the entry point of the script.
function distcc_build {
    _dccsh_dump_config
    _dccsh_debug "command line is: $*"

    _dccsh_parse_distcc_ports

    _dccsh_calculate_local_workers \
            ${DISTCC_NUM_ONLY_LOCAL:-"-1"} ${DISTCC_NUM_FIRST_LOCAL:-"-1"}
    _dccsh_check_memory
    if [ $? -ne 0 ]; then
        local NEW_WORKER_COUNT=$(_dccsh_scale_local_workers)
        if [ $NEW_WORKER_COUNT -eq 0 ]; then
            echo "[ERROR] Refusing to build: not enough memory for local jobs!" >&2
            return -6
        fi

        # Recalculate the number of local workers in the DCCSH_ variables
        # after scaling was performed.
        _dccsh_calculate_local_workers $NEW_WORKER_COUNT $NEW_WORKER_COUNT
    fi

    _dccsh_append_localhost
    _dccsh_append_preprocess_jobs

    _dccsh_debug "Running $DCCSH_TOTAL_JOBS threads"
    _dccsh_run_distcc "$DCCSH_HOSTS" $* -j "$DCCSH_TOTAL_JOBS"
    local R=$?

    _dccsh_cleanup_vars

    return $R
}
