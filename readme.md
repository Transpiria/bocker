# Bocker

[![CircleCI](https://img.shields.io/circleci/build/github/Transpiria/bocker/main)](https://app.circleci.com/pipelines/github/Transpiria/bocker)
[![NPM](https://img.shields.io/npm/v/bocker)](https://www.npmjs.com/package/bocker)

Bocker is a simple mocker for bats.

## Installation

### Npm

Install bocker with [npm](https://www.npmjs.com).

```shell
npm install -D bocker
```

## Usage

See [examples](examples) for examples.

### Setup

Load bocker in the test file.

```shell
load bocker
```

### Cleanup

Clean up the temporary files used during the test run by adding bock_teardown to the test teardown method.

```shell
function teardown() {
    bock_teardown
}
```

### Arrange

Sets up a mock of a call.

```shell
arrange [options] call [arguments] -- [does]
```

#### Options

Options applied to the mock.

|Option|Description|
|---|---|

#### Arguments

A list of arguments and/or conditions use to match the call

##### anyargs

Matches any remaining arguments.

##### any

Matches any argument.

##### has

Matches a sequence of arguments in the call.

```shell
# usage
has[-sequence count] sequence

# examples
has foo
has-1 foo
has-2 foo bar
```

#### Does

What the mocked call will do when executed.

### Verify

Verifies a mock was run or not.

```shell
verify [options] call [arguments]
```
