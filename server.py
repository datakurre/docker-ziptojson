#!/usr/bin/env python3
from aiohttp import web

import asyncio
import contextlib
import io
import os
import subprocess
import tempfile
import traceback
import uuid
import zipfile


async def get(request):
    return web.Response(
        content_type="text/html",
        text="""\
<html>
<head><title>ZIP to PDF</title></head>
<body>
<form method="post" accept-charset="utf-8" enctype="multipart/form-data"
      style="display: flex; width: 100%; height: 100%; align-items: center; justify-content: center;">
<input type="file" name="file" />
<input type="submit" value="PDF" />
</form>
</body>
</html>
""")


@contextlib.contextmanager
def chdir(path):
    curdir = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(curdir)


async def post(request):
    try:
        pdf = await convert(request)
        response = web.StreamResponse()
        response.content_length = len(pdf)
        response.content_type = 'application/pdf'
        await response.prepare(request)
        await response.write(pdf)
        await response.drain()
        return response
    except:
        return web.Response(text=traceback.format_exc())


async def convert(request):
    data = await request.post()
    home = os.getcwd()
    with tempfile.TemporaryDirectory() as path:
        with chdir(path):
            with open('export.tex', 'w', encoding='utf-8') as fp:
                fp.write("""\
\\documentclass{minimal}
\\usepackage[a4paper,margin=10mm,bindingoffset=10mm]{geometry}
\\usepackage[utf8]{inputenc}
\\usepackage{minted}
\\setlength\parindent{0pt}
\\begin{document}
""")
                z = zipfile.ZipFile(data['file'].file)
                for f in z.namelist():
                    if not f.endswith('.json'):
                        continue
                    fp.write("""\
\\texttt{""" + f.replace('_', '\\_') + """:}
""")
                    g = str(uuid.uuid4())
                    fp.write("""\
\\inputminted[breaklines,breaksymbolleft=\\hspace{0pt}]{json}{""" + g + """}
""")
                    with open(g, 'wb') as fp2:
                        fp2.write(z.read(f))
                fp.write("""\
\\end{document}
""")
            p = subprocess.Popen([
                'pdflatex',
                '-shell-escape',
                '-interaction=nonstopmode',
                'export.tex',
            ])
            p.communicate()
            with open('export.pdf', 'rb') as fp:
                pdf = fp.read()
    return pdf


app = web.Application()
app.router.add_get('/', get)
app.router.add_post('/', post)

web.run_app(app)
