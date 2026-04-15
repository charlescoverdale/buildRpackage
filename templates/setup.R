# tests/testthat/setup.R
#
# Redirect any package cache to a temp directory for all tests so that
# nothing is written to the user's home filespace during R CMD check.
# Required by CRAN policy.

options({{PACKAGE_NAME}}.cache_dir = tempfile("{{PACKAGE_NAME}}_test_cache_"))
