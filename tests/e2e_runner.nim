## E2E runner: find a free port, start HTTP server (nimhttpd), run E2E test binary.
## Keeps port and server logic in Nim; no platform-specific shell.
## Run after building docs/ and the e2e_bhanda binary; nimble testE2e does that.

import std/[net, os, osproc]

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
