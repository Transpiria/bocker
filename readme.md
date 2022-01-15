# Bocker

[![CircleCI](https://img.shields.io/circleci/build/github/Transpiria/bocker/master)](https://app.circleci.com/pipelines/github/Transpiria/bocker)
[![NPM](https://img.shields.io/npm/v/bocker)](https://www.npmjs.com/package/bocker)

Bocker is a simple mocker for bats.

## Installation

### Npm

Install bocker with [npm](https://www.npmjs.com).

```shell
npm install -D bocker
```

## Usage

In order to 

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

#### Does

What the mocked call will do when executed.

### Verify
