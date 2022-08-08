#!/usr/bin/env bash

function bock_setup() {
    if [ -z "${bock_run}" ]; then
        export bock_run=$(mktemp -d || mktemp -d -t tmp)
        export bock_logs="${bock_run}/logs"
    fi
}

function bock_teardown() {
    if [ -n "${bock_run}" ] && [ -d "${bock_run}" ]; then
        if [ -f "${bock_logs}" ]; then
            cat "${bock_logs}" >&2
        fi
        rm -r "${bock_run}"
    fi
    unset bock_run
}

function write_args() {
    local file="$1"
    shift

    touch "${file}"
    for arg in "$@"; do
        echo "${arg}" >> "${file}"
    done
}

function read_args() {
    local file="$1"

    local args=()
    local line
    while IFS= read -r line; do
        args+=("${line}")
    done < "${file}"

    echo "${args[@]}"
}

function dir_count() {
    local pattern="$1"

    local count=$(find ${pattern} -maxdepth 0 -type d 2>/dev/null | wc -l)
    echo "${count}"
}

function file_count() {
    local pattern="$1"

    local count=$(find ${pattern} -maxdepth 0 -type f 2>/dev/null | wc -l)
    echo "${count}"
}

function index_of() {
    local value="$1"
    local index="$2"
    shift
    shift
    local args=("$@")

    while [[ "${index}" -lt "${#args[@]}" ]] && [ "${args[${index}]}" != "${value}" ]; do
        index=$((${index} + 1))
    done

    if [[ "${index}" -ge "${#args[@]}" ]]; then
        echo "-1"
    else
        echo "${index}"
    fi
}

function bock_log() {
    local level="$1"
    local message="$2"

    echo "${level}: ${message}" >> "${bock_logs}"
}

function bock_log_debug() {
    local message="$1"

    bock_log "DEBUG" "${message}"
}

function bock_log_info() {
    local message="$1"

    bock_log "INFO" "${message}"
}

function bock_log_warn() {
    local message="$1"

    bock_log "WARN" "${message}"
}

function bock_log_error() {
    local message="$1"

    bock_log "ERROR" "${message}"
}

function arrange_proxy() {
    local com="$1"
    shift
    local args=("$@")
    bock_log_debug "Mocked call: ${com} ${args[@]}"

    local count
    local entry=0
    local total=$(dir_count "${bock_run}/${com}/*")
    local arg_index
    local success=0
    local exp
    local exps
    local exp_index
    local exp_success
    local does
    local has_count
    local has_exp_index
    local has_arg_index
    local has_end_index
    while [ "${success}" == "0" ] && [[ "${entry}" -lt "${total}" ]]; do
        exps=()
        while IFS= read -r line; do
            exps+=("${line}")
        done < "${bock_run}/${com}/${entry}/exps"
        bock_log_debug "Attempting to match expected: ${com} ${exps[@]}"
        arg_index=0
        exp_index=0
        exp_success=1
        while [ "${exp_success}" == "1" ] && [[ "${exp_index}" -lt "${#exps[@]}" ]]; do
            exp="${exps[${exp_index}]}"
            case "${exp}" in
                anyargs)
                    exp_index="${#exps[@]}"
                    ;;
                any)
                    arg_index=$((${arg_index} + 1))
                    ;;
                has*)
                    has_count="${exp#*-}"
                    if [ "${has_count}" == "has" ]; then
                        has_count="1"
                    fi

                    has_exp_index=$((${exp_index} + 1))
                    has_arg_index="$(index_of "${exps[${has_exp_index}]}" ${arg_index} ${args[@]})"
                    has_end_index=$((${has_arg_index} + ${has_count}))
                    if [[ "${has_arg_index}" -gt "-1" ]]; then
                        has_exp_index=$((${has_exp_index} + 1))
                        has_arg_index=$((${has_arg_index} + 1))
                        while [[ "${has_arg_index}" -lt "${has_end_index}" ]] && [ "${args[${has_arg_index}]}" == "${exps[${has_exp_index}]}" ]; do
                            has_exp_index=$((${has_exp_index} + 1))
                            has_arg_index=$((${has_arg_index} + 1))
                        done
                        if [ "${has_arg_index}" != "${has_end_index}" ]; then
                            bock_log_debug "Aurgument did not contain expected"
                            bock_log_debug "    expected: ${exps[${has_exp_index}]}"
                            bock_log_debug "      actual: ${args[${has_arg_index}]}"
                            exp_success=0
                        fi
                    else
                        bock_log_debug "Aurgument did not contain expected"
                        bock_log_debug "    expected: ${exps[${exp_index}]}"
                        exp_success=0
                    fi
                    exp_index=$((${exp_index} + ${has_count}))
                    ;;
                *)
                    if [ "${args[${arg_index}]}" != "${exp}" ]; then
                        bock_log_debug "Aurgument did not match expected"
                        bock_log_debug "    expected: ${exp}"
                        bock_log_debug "      actual: ${args[${arg_index}]}"
                        exp_success=0
                    fi
                    arg_index=$((${arg_index} + 1))
                    ;;
            esac

            exp_index=$((${exp_index} + 1))
        done

        if [ "${exp_success}" == "1" ]; then
            count=$(file_count "${bock_run}/${com}/${entry}/call_*")
            write_args "${bock_run}/${com}/${entry}/call_${count}" "${args[@]}"

            does=()
            while IFS= read -r line; do
                does+=("${line}")
            done < "${bock_run}/${com}/${entry}/does"
            success=1
        fi

        entry=$((${entry} + 1))
    done

    if [ "${success}" == "1" ]; then
        "${does[@]}"
    else
        #TODO: passthru proxy
        bock_log_warn "Mocked call had no matching arrangement: ${com} ${args[@]}"
    fi
}

function arrange() {
    local arg
    local com
    local args=()
    local does=(return 0)
    local opts=()

    while [[ $# -gt 0 ]] && [ -z "${com}" ]; do
        if [ "${1#-}" != "${1}" ]; then
            opts+=("${1}")
        else
            com="${1}"
        fi

        shift
    done

    while [[ $# -gt 0 ]]; do
        if [ "${1}" != "--" ]; then
            args+=("${1}")
        else
            shift
            does=("$@")
            break
        fi

        shift
    done

    bock_setup
    if [ ! -d "${bock_run}/${com}" ]; then
        mkdir -p "${bock_run}/${com}"
        eval "
function ${com[0]}() {
    arrange_proxy ${com[0]} \$@
}
"
    fi

    local entry=$(dir_count "${bock_run}/${com}/*")
    mkdir -p "${bock_run}/${com}/${entry}"
    write_args "${bock_run}/${com}/${entry}/exps" "${args[@]}"
    write_args "${bock_run}/${com}/${entry}/opts" "${opts[@]}"
    write_args "${bock_run}/${com}/${entry}/does" "${does[@]}"
}

function verify() {
    local com="$1"

    local result=0
    local count=0
    local exps
    local entry=0
    local total=$(dir_count "${bock_run}/${com}/*")
    while [[ "${entry}" -lt "${total}" ]]; do
        count=$(file_count "${bock_run}/${com}/${entry}/call_*")
        if [ "${count}" == "0" ]; then
            result=1
            exps=()
            while IFS= read -r line; do
                exps+=("${line}")
            done < "${bock_run}/${com}/${entry}/exps"
            echo "Expected calls: 1, actual: ${count}, call: ${com} ${exps[@]}"
        fi

        entry=$((${entry} + 1))
    done

    return ${result}
}
