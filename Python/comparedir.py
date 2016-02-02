# -*- coding: utf-8 -*-
from sys import argv
import glob
from os import path
import os

def compareDir(*args):
  firstdir, seconddir, fileextension = args
  path.normcase(firstdir)
  path.normcase(seconddir)
  firstallfile = glob.glob1( firstdir, fileextension )
  secondallfile = glob.glob1( seconddir, fileextension )
  firstDiffToSecond = [ f for f in firstallfile if f not in secondallfile ]
  print "firstDiffToSecond"
  print firstDiffToSecond
  secondDiffToFirst = [ f for f in secondallfile if f not in firstallfile ]
  print "secondDiffToFirst"
  print secondDiffToFirst
  
if __name__ == "__main__":
  if len(argv) < 4:
    print "Usage: python comparedir dir1 dir2 fileextension"
    exit(0)
	
  script, firstdir, seconddir, fileextension = argv
  compareDir(firstdir, seconddir, fileextension)
  
