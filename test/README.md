# Tests
This directory contains very simple unit tests for most functions of the
program. I thought about using [shUnit2](https://code.google.com/p/shunit2/) but
because my time is limited I simply created a very simple framework for my tests
on my own. I might convert them at a later point and make use of the above
framework.

## Usage
Each function is tested with its own script, this allows one to execute single
tests. If you want to execute all tests simply use the `all.sh` script or issue
`make test` (`sudo make test` respectively) in the parent directory.

## Integration Test
The `integration_test.sh` is a special test that will install everything and
create a TLS server on localhost with nginx. Afterwards it will check if the
tickets are actually rotated.
