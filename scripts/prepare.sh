#!/bin/sh
if [ -n "$CI" ]; then
  lefthook install --reset-hooks-path
else
  lefthook install
fi
