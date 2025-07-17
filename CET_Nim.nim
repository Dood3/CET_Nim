# Build with:
# nim c myscript.nim
# nim c -d:release myscript.nim
# nim c -d:release -d:danger --opt:size --passC:-flto --passL:-s myscript.nim
# (-d:danger disables overflow checks, etc.)
# nim c --out:command_embedder command_embedder.nim
# nim c --cpu:amd64 --os:windows -o:myprogram.exe myscript.nim
# nim c --cpu:amd64 --os:windows -d:release -o:myprog.exe myscript.nim

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
  let execCommand = if targetOS == "windows":
    "execProcess(\"cmd\", args = [\"/C\", \"\"" & command & "\"\"], options = {poUsePath})"
  else:
    "execProcess(\"sh\", args = [\"-c\", \"\"\"" & command & "\"\"\"], options = {poUsePath})"

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

proc checkCrossCompilationSupport(targetOS: string): bool =
  if targetOS == "windows":
    # Check if MinGW cross-compilation toolchain is available
    let (_, mingwExitCode) = execCmdEx("which x86_64-w64-mingw32-gcc")
    if mingwExitCode != 0:
      echo "ERROR: Windows cross-compilation requires MinGW-w64 toolchain."
      echo "Install using:"
      echo "  Ubuntu/Debian: sudo apt-get install mingw-w64"
      echo ""
      echo "After installation, you may also need to configure Nim to use MinGW:"
      echo "  nim c --os:windows --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --out:" & "output" / "filename.exe" & " source.nim"
      return false
  return true

proc compileExecutable(filename: string, targetOS: string) =
  let sourceFile = "output" / (filename & ".nim")
  let outputFile = if targetOS == "windows":
    "output" / (filename & ".exe")
  else:
    "output" / filename

  # Check cross-compilation support
  if not checkCrossCompilationSupport(targetOS):
    echo "Skipping compilation due to missing cross-compilation toolchain."
    echo "Source file generated: " & sourceFile
    echo "You can compile it manually on a Windows system or after installing the required toolchain."
    return

  # Determine cross-compilation flags
  let osFlag = if targetOS == "windows": "--os:windows" else: "--os:linux"
  let cpuFlag = "--cpu:amd64"

  # For Windows cross-compilation, use MinGW if available
  let compileCmd = if targetOS == "windows":
    "nim c " & osFlag & " " & cpuFlag & " --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --out:" & outputFile & " " & sourceFile
  else:
    "nim c " & osFlag & " " & cpuFlag & " --out:" & outputFile & " " & sourceFile

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