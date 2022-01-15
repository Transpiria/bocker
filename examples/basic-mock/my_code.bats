load bocker

function setup() {
    source my_code.sh
}

function tear_down() {
    bock_teardown
}

@test "Should successfully push an image" {
    # arrange
    local image="my_image"
    arrange docker push "${image}" -- exit 0

    # act
    run my_function "${image}"

    # assert
    [ "${status}" -eq 0 ]
    verify command
}
