#!/bin/bash

progress () { echo "====== $@" ; }

# Executables
# -----------

repo_dir="$(cd "$(dirname "$0")"; pwd)"
rvmonitor_bin="$repo_dir/ext/rv-monitor/target/release/rv-monitor/bin"
javamop_bin="$repo_dir/ext/javamop/target/release/javamop/javamop/bin"
gen_src_dir="$repo_dir/target/generated-sources"

progress "generate aspectJ and rvm files"

(   ( mkdir -p "$gen_src_dir/aspectJ" && mkdir -p "$gen_src_dir/java" && \
      cd "$repo_dir/monitor" && \
      "$javamop_bin/javamop" -debug -d "$gen_src_dir/aspectJ" -merge *.mop && \
      "$rvmonitor_bin/rv-monitor" -merge -d "$gen_src_dir/java" *.rvm ) \
 || ( rm -f "$gen_src_dir/aspectJ" ; rm -f "$gen_src_dir/java/*.java" ))
