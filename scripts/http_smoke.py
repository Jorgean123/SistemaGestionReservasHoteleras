"""Pruebas HTTP reales en Tomcat; elimina únicamente sus propios registros temporales."""
import urllib.request, urllib.parse, urllib.error, http.cookiejar
import re, json, uuid, datetime, subprocess, os
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
BASE='http://localhost:8080/hotel'
opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
results=[]
def call(path, data=None):
    body=urllib.parse.urlencode(data).encode() if data is not None else None
    try:
        with opener.open(BASE+path,body,timeout=20) as r: return r.status,r.read().decode('utf-8')
    except urllib.error.HTTPError as e: return e.code,e.read().decode('utf-8')
def check(name, passed):
    results.append({'prueba':name,'resultado':'OK' if passed else 'FALLO'})
    if not passed: raise AssertionError(name)
config={}
for line in Path('C:/apache-tomcat-11.0.24/conf/hotel-db.properties').read_text().splitlines():
    if '=' in line and not line.startswith('#'):
        k,v=line.split('=',1);config[k]=v
def sql(statement):
    env=os.environ.copy();env['MYSQL_PWD']=config['password']
    return subprocess.run(['C:/Program Files/MySQL/MySQL Server 9.0/bin/mysql.exe','-h','127.0.0.1','-u',config['user'],'hotel_reservas','--batch','--skip-column-names','--default-character-set=utf8mb4','-e',statement],env=env,capture_output=True,check=True).stdout.decode('utf-8').strip()
document='H'+uuid.uuid4().hex[:12]
room_number='H'+uuid.uuid4().hex[:8]
guest=room=None
try:
    for path in ['/panel','/reservas','/habitaciones','/huespedes','/nueva-reserva']:
        status,html=call(path);check('GET '+path+' responde 200',status==200 and '<html lang="es">' in html)
    csrf=re.search('name="csrf" value="([^"]+)"',html)[1]
    status,_=call('/huespedes',{'action':'guest','csrf':'incorrecto'});check('Rechazo CSRF',status==403)
    name='Prueba HTTP <script>alert(1)</script>'
    data={'action':'guest','csrf':csrf,'nombre':name,'documento':document,'telefono':'999999999','email':'test@example.invalid'}
    status,html=call('/huespedes',data);check('Registro de huésped y escape HTML',status==200 and 'Prueba HTTP &lt;script&gt;' in html)
    guest=int(sql(f"SELECT id FROM clientes WHERE documento='{document}'"))
    status,_=call('/huespedes',data);check('Documento duplicado responde 409',status==409)
    sql(f"INSERT INTO habitaciones(capacidad,descripcion,habilitada,numero,precio_noche,tipo) VALUES(2,'Temporal HTTP',1,'{room_number}',145,'DOBLE')")
    room=int(sql(f"SELECT id FROM habitaciones WHERE numero='{room_number}'"))
    start=datetime.date.today()+datetime.timedelta(days=20);end=start+datetime.timedelta(days=3)
    data={'action':'reserve','csrf':csrf,'cliente':guest,'habitacion':room,'entrada':start.strftime('%d/%m/%Y'),'salida':end.strftime('%d/%m/%Y'),'personas':2,'observaciones':'Prueba temporal'}
    status,html=call('/nueva-reserva',data);check('Creación de reserva por formulario y fechas día/mes/año',status==200 and 'registrada. Puede confirmarla' in html and start.strftime('%d/%m/%Y') in html and end.strftime('%d/%m/%Y') in html)
    booking=int(sql(f'SELECT id FROM reservas WHERE habitacion_id={room}'))
    check('Importe persistido S/ 435.00',sql(f'SELECT total FROM reservas WHERE id={booking}')=='435.00')
    status,html=call('/nueva-reserva',data);check('Solapamiento devuelve 400 con explicación',status==400 and 'ya tiene una reserva' in html)
    bad=data|{'entrada':end.strftime('%d/%m/%Y'),'salida':start.strftime('%d/%m/%Y')}
    status,_=call('/nueva-reserva',bad);check('Fechas invertidas rechazadas',status==400)
    bad=data|{'personas':3}
    status,_=call('/nueva-reserva',bad);check('Capacidad excedida rechazada',status==400)
    for state in ['CONFIRMADA','CANCELADA']:
        status,_=call('/reservas',{'action':'state','csrf':csrf,'id':booking,'estado':state})
        check('Transición a '+state,status==200 and sql(f'SELECT estado FROM reservas WHERE id={booking}')==state)
    status,html=call('/reservas?q='+document+'&estado=CANCELADA');check('Filtros de reservas',status==200 and room_number in html)
    status,_=call('/nueva-reserva',data);check('Reserva tras cancelación',status==200)
finally:
    if room:
        sql(f'DELETE FROM reservas WHERE habitacion_id={room}; DELETE FROM habitaciones WHERE id={room}')
    if guest:sql(f'DELETE FROM clientes WHERE id={guest}')
    out=ROOT/'docs'/'evidencias';out.mkdir(parents=True,exist_ok=True)
    (out/'http-resultados.json').write_text(json.dumps({'fecha':datetime.datetime.now().isoformat(),'base_url':BASE,'resultados':results,'limpieza':'Registros temporales eliminados'},ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(results,ensure_ascii=False,indent=2))
