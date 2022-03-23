# -*- coding: utf-8 -*-
#! /bin/env python3

import ast
import os
import zipfile
from datetime import datetime
import sys

help = """Odoo Module Packaging
What is it?
A simple python script that compress odoo module with its dependency modules in a file ZIP.
How to use?    
1 ) Go to custom addons path
2 ) odoo-module-packaging.py MODULE_NAME FILE1_EXTRA FILE2_EXTRA 
3 ) File MODULE_NAME-VERSION+BUILD.zip
"""


def packaging(*args):
    name = args[0]
    fextra = list(args[1:]) if len(args) > 1 else []

    if not os.path.exists(name):
        raise Exception("Don't exists %s" % name)

    manifest = "%s/__manifest__.py" % name
    version = None
    depends = [name]

    with open(manifest, "rb") as m:
        content = m.read()
        try:
            if isinstance(content, bytes):
                content = content.decode('utf-8')
            else:
                content = str(content)
            data = ast.literal_eval(content)

            version = data.get('version', None)
            for p in data.get('depends', []):
                if os.path.exists(p):
                    depends.append(p)

        finally:
            m.close()
    if version:
        name = "%s-%s+%s.zip" % (name, version,
                                 datetime.now().utcnow().strftime("%s"))
        zf = zipfile.ZipFile(name, "w")

        for d in depends:
            for root, dirs, files in os.walk(d):
                for file in files:
                    fpath = os.path.join(root, file)
                    zf.write(fpath)

        for fpath in fextra:
            if os.path.exists(fpath):
                zf.write(fpath)
        zf.close()
        print(name)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        packaging(*sys.argv[1:])
    else:
        print(help)
