from bs4 import BeautifulSoup
from urllib import request
import requests
import argparse
import os

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
    except Exception as e:
        print(str(e))


def download_files_from_url(url, saved_path):
    print(f"Downloading files from {url}")
    if not os.path.exists(saved_path):
        os.makedirs(saved_path, exist_ok=True)
    opened_url = request.urlopen(url)
    content = opened_url.read()
    soup = BeautifulSoup(content, features="html.parser")

    for a in soup.findAll('a',href=True):
        if a.text.endswith('/'):
            download_files_from_url(url + a.text, saved_path + a.text)
        elif a.text.endswith('.pdf'):
            file_saved_path = saved_path + a.text.split('/')[-1]
            download_single_file(url + a.text, file_saved_path)


ap = argparse.ArgumentParser()
ap.add_argument("-u","--url", required=True, help='The base url for downloading file')#"http://www.andrew.cmu.edu/course/15-749/READINGS/"
ap.add_argument("-s", "--saved-path", type=str, default=os.getcwd(), help='the local path to store the files')
args = vars(ap.parse_args())
download_files_from_url(args['url'], args['saved_path'].replace('\\', '/') + '/')