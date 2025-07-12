# Build with:
# 'nim c --out:command_embedder command_embedder.nim'

import os, strutils, osproc

proc getUserInput(prompt: string): string =
  stdout.write(prompt)
  stdout.flushFile()
  return stdin.readLine().strip()

proc selectTargetOS(): string =
  echo "=== Command Embedder Tool - Nim Version ==="
  echo "Select target operating system:"
  echo "1. Windows"
  echo "2. Linux"

  while true:
    let choice = getUserInput("Enter choice (1 or 2): ")
    case choice:
    of "1":
      return "windows"
    of "2":
      return "linux"
    else:
      echo "Invalid choice. Please enter 1 or 2."

proc getCommand(): string =
  return getUserInput("Enter the command to embed: ")

proc getOutputFilename(): string =
  return getUserInput("Enter output filename (without extension): ")

proc generateNimCode(command: string, targetOS: string): string =
  # Properly escape quotes in the command
  let escapedCommand = command.replace("\"", "\\\"").replace("\\", "\\\\")

  let execCommand = if targetOS == "windows":
    "execProcess(\"cmd\", args = [\"/C\", \"" & escapedCommand & "\"], options = {poUsePath})"
  else:
    "execProcess(\"sh\", args = [\"-c\", \"" & escapedCommand & "\"], options = {poUsePath})"

  let part1 = """import osproc, os

proc main() =
  try:
    let output = """
  let part2 = """
    echo output
  except:
    echo "Error executing command: ", getCurrentExceptionMsg()

when isMainModule:
  main()
"""
  return part1 & execCommand & "\n" & part2

proc writeSourceFile(filename: string, content: string) =
  let sourceFile = "output" / (filename & ".nim")
  writeFile(sourceFile, content)
  echo "Generated source file: " & sourceFile

proc compileExecutable(filename: string, targetOS: string) =
  let sourceFile = "output" / (filename & ".nim")
  let outputFile = if targetOS == "windows":
    "output" / (filename & ".exe")
  else:
    "output" / filename

  # Determine cross-compilation flags
  let osFlag = if targetOS == "windows": "--os:windows" else: "--os:linux"
  let cpuFlag = "--cpu:amd64"

  # Compile command
  let compileCmd = "nim c " & osFlag & " " & cpuFlag & " --out:" & outputFile & " " & sourceFile

  echo "Compiling for " & targetOS & "..."
  echo "Command: " & compileCmd

  let (output, exitCode) = execCmdEx(compileCmd)

  if exitCode == 0:
    echo "Successfully compiled: " & outputFile
  else:
    echo "Compilation failed:"
    echo output

proc main() =
  # Create output directory
  if not dirExists("output"):
    createDir("output")

  # Step 1: Collect user input
  let targetOS = selectTargetOS()
  let command = getCommand()
  let filename = getOutputFilename()

  echo ""
  echo "=== Configuration ==="
  echo "Target OS: " & targetOS
  echo "Command: " & command
  echo "Output: " & filename
  echo ""

  # Step 2: Generate Nim code
  let nimSource = generateNimCode(command, targetOS)

  # Step 3: Write source file
  writeSourceFile(filename, nimSource)

  # Step 4: Compile executable
  compileExecutable(filename, targetOS)

  echo ""
  echo "=== Process Complete ==="
  echo "Files created in output/ directory:"
  echo "- " & filename & ".nim (source code)"
  if targetOS == "windows":
    echo "- " & filename & ".exe (executable)"
  else:
    echo "- " & filename & " (executable)"

when isMainModule:
  main()
