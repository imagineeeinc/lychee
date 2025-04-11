let doc = """
Usage:
  lasm <file>

Options:
  -h --help     Show this screen.
  --version     Show version.
"""

import docopt
import lychee_asmpkg/main

when isMainModule:
  let args = docopt(doc, version = "0.1.0", help=true)
  if args["<file>"]:
    let code = readFile($args["<file>"])