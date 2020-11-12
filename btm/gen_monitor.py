#!/usr/bin/env python

import glob
import os.path
import shutil
import sys
import tools

def readFile(name):
    with open(name, "rt") as f:
        return ''.join(f)

def writeFile(name, contents):
    with open(name, "wt") as f:
        f.write(contents)

def runPc(pcompiler_dir, arguments):
    tools.runNoError(["dotnet", os.path.join(pcompiler_dir, "Bld", "Drops", "Release", "Binaries", "Pc.dll")] + arguments)

def translate(pcompiler_dir, gen_monitor_dir):
    tools.progress("Run the PCompiler...")
    runPc(pcompiler_dir, ["twoPhaseCommit.p", "-g:RVM", "-o:%s" % gen_monitor_dir])

def fillAspect(aspectj_dir, gen_monitor_dir):
    tools.progress("Fill in AspectJ template")
    aspect_file_name = "twoPhaseCommitMonitorAspect.aj"
    aspect_file_path = os.path.join(gen_monitor_dir, aspect_file_name)
    aspectContent = readFile(aspect_file_path)
    aspectContent = aspectContent.replace("// add your own imports.", readFile("import.txt"))
    aspectContent = aspectContent.replace("// Implement your code here.", readFile("ajcode.txt"))
    writeFile(aspect_file_path, aspectContent)
    writeFile(os.path.join(aspectj_dir, aspect_file_name), aspectContent)

def runMonitor(rvmonitor_bin, gen_monitor_dir, java_dir):
    tools.progress("Run RVMonitor")
    monitor_binary = os.path.join(rvmonitor_bin, "rv-monitor")
    rvm_file = os.path.join(gen_monitor_dir, "twoPhaseCommit.rvm")
    tools.runNoError([monitor_binary, "-merge", "-d", java_dir, rvm_file])

def copyRuntime(runtime_dir, java_dir):
    tools.progress("Copy Runtime")
    for f in glob.glob(os.path.join(runtime_dir, "*.java")):
        shutil.copy(f, java_dir)

def build(pcompiler_dir, gen_monitor_dir, rvmonitor_bin, runtime_dir, aspectj_dir, java_dir):
    translate(pcompiler_dir, gen_monitor_dir)
    fillAspect(aspectj_dir, gen_monitor_dir)
    runMonitor(rvmonitor_bin, gen_monitor_dir, java_dir)
    copyRuntime(runtime_dir, java_dir)

def removeAll(pattern):
    for f in glob.glob(pattern):
        os.remove(f)

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    pcompiler_dir = os.path.join(script_dir, "ext", "P")
    runtime_dir = os.path.join(pcompiler_dir, "Src", "PRuntimes", "RvmRuntime")
    rvmonitor_bin = os.path.join(script_dir, "ext", "rv-monitor", "target", "release", "rv-monitor", "bin")
    gen_src_dir = os.path.join(script_dir, "target", "generated-sources")
    monitor_dir = os.path.join(script_dir, "monitor")

    aspectj_dir = os.path.join(gen_src_dir, "aspectJ")
    if not os.path.exists(aspectj_dir):
        os.makedirs(aspectj_dir)

    java_dir = os.path.join(gen_src_dir, "java")
    if not os.path.exists(java_dir):
        os.makedirs(java_dir)

    gen_monitor_dir = os.path.join(monitor_dir, "generated")
    if not os.path.exists(gen_monitor_dir):
        os.makedirs(gen_monitor_dir)

    try:
        tools.runInDirectory(
            monitor_dir,
            lambda: build(pcompiler_dir, gen_monitor_dir, rvmonitor_bin, runtime_dir, aspectj_dir, java_dir))
    except BaseException as e:
        removeAll(os.path.join(aspectj_dir, "*.aj"))
        removeAll(os.path.join(java_dir, "*.java"))
        raise e

if __name__ == "__main__":
    main()
