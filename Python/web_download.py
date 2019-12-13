from bs4 import BeautifulSoup
from urllib import request
import requests
import argparse
import os
import traceback


##Downloaded class:
##https://www.cs.cmu.edu/~15853-f19/
##http://www.andrew.cmu.edu/course/15-749/READINGS/
##http://web.stanford.edu/class/cs205l/lectures.html
##https://nlp.cs.princeton.edu/cos484/

def str2bool(v):
    if isinstance(v, bool):
       return v
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')


def download_single_file(url, saved_path):
    try:
        if not os.path.exists(saved_path):
            print(f"Save file to {saved_path}")
            '''
            #stream mode
            r = requests.get(url, stream = True)
            with open(saved_path, "wb") as f:
                for chunk in r.iter_content(chunk_size=1024 * 1024):
                    if chunk:
                        f.write(chunk)
            '''
            r = requests.get(url)
            with open(saved_path, "wb") as f:
                f.write(r.content)
    except:
        print(traceback.print_stack())


def download_files_from_url(url, filebaseurl, isdownloaddirectory, saved_path, checked_property='href'):
    print(f"Downloading files from {url}")
    if not os.path.exists(saved_path):
        os.makedirs(saved_path, exist_ok=True)
    opened_url = request.urlopen(url)
    content = opened_url.read()
    soup = BeautifulSoup(content, features="html.parser")

    for a in soup.findAll('a',href=True):
        if checked_property == 'href':
            atext = a['href']
        else:
            atext = a.text

        if atext.endswith('/') and isdownloaddirectory:
            download_files_from_url(url + atext, saved_path + atext)
        elif atext.endswith('.pdf') or atext.endswith('.zip'):
            file_saved_path = saved_path + atext.split('/')[-1]
            if not os.path.exists(file_saved_path):
                if atext.startswith("http://") or atext.startswith("https://"):
                    download_single_file(atext, file_saved_path)
                else:
                    download_single_file(filebaseurl + atext, file_saved_path)


ap = argparse.ArgumentParser()
ap.add_argument("-u","--url", required=True, help='The url for downloading file')
ap.add_argument("-b", "--baseurl", required=True, help='The base url for the downloaded file')
ap.add_argument("-d", "--downloaddir", type=str2bool, nargs='?',
                        const=True, default=False, help='Indicate whether downloads directories on the web page')
ap.add_argument("-s", "--saved-path", type=str, default=os.getcwd(), help='the local path to store the files')
args = vars(ap.parse_args())
download_files_from_url(args['url'],args['baseurl'], args["downloaddir"], args['saved_path'].replace('\\', '/') + '/')


