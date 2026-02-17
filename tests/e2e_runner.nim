## E2E runner: run E2E test binary. If BHANDA_E2E_URL and SERVER_PID are set (by
## e2e_serve launcher), skip starting the server and kill SERVER_PID when done.
## Otherwise start nimhttpd and run the test (legacy path).
## Run after building docs/ and e2e_bhanda; nimble testE2e does that.

import std/[net, os, osproc, strutils]

const
  docsDir = "docs"
  nimhttpdExe = "nimhttpd"
  e2eBinary = "build/e2e_bhanda"

proc findFreePort(): Port =
  let sock = newSocket()
  try:
    sock.bindAddr(Port(0), "127.0.0.1")
    let (_, port) = sock.getLocalAddr()
    return port
  finally:
    sock.close()

proc waitForServer(port: Port; maxAttempts: int = 10): bool =
  for i in 0 ..< maxAttempts:
    let sock = newSocket()
    try:
      sock.connect("127.0.0.1", port, 1000)
      return true
    except OSError:
      discard
    finally:
      try: sock.close() except: discard
    os.sleep(200)
  return false

proc main(): int =
  let url = getEnv("BHANDA_E2E_URL")
  let serverPidStr = getEnv("SERVER_PID")

  if url.len > 0 and serverPidStr.len > 0:
    echo "E2E: server already running at ", url, " (PID ", serverPidStr, ")"
    let testProc = startProcess(
      e2eBinary,
      options = {poUsePath, poParentStreams}
    )
    result = testProc.waitForExit()
    try:
      let pid = serverPidStr.parseInt
      if pid > 0:
        let killProc = startProcess("kill", args = [$pid], options = {poUsePath})
        discard killProc.waitForExit()
    except ValueError:
      discard
    return

  let port = findFreePort()
  echo "E2E: serving ", docsDir, " on http://127.0.0.1:", port.uint16, "/"

  let serverProc = startProcess(
    nimhttpdExe,
    args = ["-p:" & $port.uint16, "-a:127.0.0.1", docsDir],
    options = {poUsePath}
  )
  defer: serverProc.terminate()

  if not waitForServer(port):
    echo "E2E: server did not respond on port ", port.uint16
    return 1

  putEnv("BHANDA_E2E_URL", "http://127.0.0.1:" & $port.uint16 & "/")
  let testProc = startProcess(
    e2eBinary,
    options = {poUsePath, poParentStreams}
  )
  result = testProc.waitForExit()

when isMainModule:
  quit(main())
