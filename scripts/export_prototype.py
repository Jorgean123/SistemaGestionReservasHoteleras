"""Guarda respuestas HTML como referencia estática; no constituye revisión en navegador."""
from pathlib import Path
from urllib.request import urlopen
import re, shutil
ROOT=Path(__file__).resolve().parents[1]
out=ROOT/'docs'/'prototipo';out.mkdir(exist_ok=True)
pages=['panel','reservas','habitaciones','huespedes','nueva-reserva']
for page in pages:
    with urlopen('http://localhost:8080/hotel/'+page,timeout=20) as r:html=r.read().decode('utf-8')
    html=html.replace('/hotel/assets/','assets/')
    for route in pages:html=html.replace('/hotel/'+route,route+'.html')
    html=re.sub(r'(name="csrf" value=")[^"]*',r'\1PROTOTIPO-SIN-SESION',html)
    html=html.replace('</head>','<script defer src="assets/prototipo.js"></script></head>')
    (out/(page+'.html')).write_text(html,encoding='utf-8')
shutil.copytree(ROOT/'src/main/webapp/assets',out/'assets',dirs_exist_ok=True)
(out/'assets/prototipo.js').write_text("document.querySelectorAll('form').forEach(f => f.addEventListener('submit', e => {e.preventDefault(); alert('Esta es una referencia estática. Use http://localhost:8080/hotel/ para guardar o buscar datos.');}));",encoding='utf-8')
(out/'LEEME.txt').write_text('Abrir panel.html para recorrer la estructura estática. Para operar datos, usar http://localhost:8080/hotel/. Copias HTML obtenidas del servidor; no son capturas ni revisión visual. Tokens CSRF sustituidos.\n',encoding='utf-8')
print('Cinco vistas HTML exportadas sin tokens de sesión.')
