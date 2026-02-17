## E2E server launcher: starts e2e_server with a ready pipe, blocks until the server
## has signalled (or failed). Does not return to shell until ready or failure.
## On success: prints "PORT PID" to stdout and exits 0. On failure: exits non-zero.
## Unix only (pipe/dup2).

import std/[net, os, osproc]

when defined(posix):
  import std/posix
else:
  echo "e2e_serve requires Posix (pipe signalling)"
  quit(1)

const
  readyFdNum = 10
  docsDir = "docs"
  serverExe = "build/e2e_server"

proc findFreePort(): Port =
  let sock = newSocket()
  try:
    sock.bindAddr(Port(0), "127.0.0.1")
    let (_, port) = sock.getLocalAddr()
    return port
  finally:
    sock.close()

proc main(): int =
  when defined(posix):
    let port = findFreePort()
    var fds: array[0..1, cint]
    if posix.pipe(fds) != 0:
      echo "e2e_serve: pipe failed"
      return 1
    let readFd = fds[0]
    let writeFd = fds[1]

    if posix.dup2(writeFd, readyFdNum.cint) < 0:
      echo "e2e_serve: dup2 failed"
      discard posix.close(readFd)
      discard posix.close(writeFd)
      return 1
    discard posix.close(writeFd)

    putEnv("NIMHTTPD_READY_FD", $readyFdNum)
    let serverProc = startProcess(
      serverExe,
      args = ["-p:" & $port.uint16, docsDir],
      options = {poUsePath}
    )
    discard posix.close(readyFdNum.cint)

    var buf: array[1, char]
    let n = posix.read(readFd, buf[0].addr, 1)
    discard posix.close(readFd)

    if n > 0:
      echo port.uint16, " ", serverProc.processID()
      return 0

    let code = serverProc.waitForExit()
    if code != 0:
      return code
    return 1
  else:
    return 1

when isMainModule:
  quit(main())
