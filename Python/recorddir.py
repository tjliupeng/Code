import os
from sys import argv

def listdirandwrite(dirpath, file):
  f = open(file, 'w')
  for dirname in os.listdir(dirpath):
    f.write(dirname+'\n')
  f.close()
  
if __name__ == "__main__":
  if len(argv) < 3:
    print("Usage: python recorddir path recordfile")
    exit(0)
	
  script, dirpath, recordfile = argv
  listdirandwrite(dirpath, recordfile)