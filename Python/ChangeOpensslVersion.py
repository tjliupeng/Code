import os
from sys import argv

filearr = ["configure.ac", "rte-package-AIX.xml", "rte-package-HPUX-IA64.xml", "rte-package-HPUX-IA64-hpux11.31.xml", "rte-package-Linux-x86.xml", "rte-package-Solaris.xml", \
           "rte-package.xml", "build/SCENTER/Scenter.vcproj", "build/SCSERVIC/Scservic.vcproj"]

def ChangeOpensslVersion(smdir, oldversion, newversion):
  for file_name in filearr:
    changedfile = os.path.normpath( smdir + "/" + file_name)
    if os.path.exists(changedfile) == False:
      print (changedfile + " does not exist!")
      continue
    print("Modifying " + changedfile)
    with open(changedfile) as f:
      s = f.read()

    with open(changedfile, "w") as f:
      s = s.replace(oldversion, newversion)
      f.write(s)

if __name__=="__main__":
  if len(argv) < 4:
    print("Usage: python ChangeOpensslVersion directory oldversion newversion")
    exit(1)

  script, smdir, oldversion, newversion = argv
  print(repr(os.path.normpath(smdir)))
  if os.path.isdir(os.path.normpath(smdir)) == False:
    print(smdir + " is not a directory.");
    exit(1)
	
  if os.path.basename(os.path.normpath(smdir)) != "rte":
    print("The base directory should be rte!")
    exit(1)

  ChangeOpensslVersion(os.path.normpath(smdir), oldversion, newversion)