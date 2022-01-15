function my_function() {
    local image="$1"

    docker push "${image}"
}
