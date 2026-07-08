#!/usr/bin/env bash
lcov --ignore-errors inconsistent --capture --directory nimcache --output-file coverage.info
lcov --ignore-errors inconsistent --remove coverage.info '*/lib/*' --output-file coverage.info
genhtml --ignore-errors range --filter missing coverage.info --output-directory coverage_html