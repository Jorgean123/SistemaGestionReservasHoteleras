// Automated tests in an isolated, headless browser; never connects to a user's session.
const fs=require('fs');const path=require('path');
const runtime=process.env.CODEX_NODE_MODULES;
const {chromium}=require(runtime ? path.join(runtime,'playwright-core') : 'playwright-core');
const assert=require('node:assert/strict');
const output=path.resolve('docs/evidencias/apf2');fs.mkdirSync(output,{recursive:true});
const base=process.env.HOTEL_BASE_URL||'http://localhost:8088/hotel';
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const context=await browser.newContext({viewport:{width:1440,height:1000},locale:'es-PE'});
 const page=await context.newPage();const results=[];
 const ok=(name)=>{results.push({name,passed:true});console.log('OK '+name);};
 try {
  for(const route of ['panel','habitaciones','huespedes','reservas','nueva-reserva']){const response=await page.goto(base+'/'+route+'.xhtml');assert.equal(response.status(),200);assert.equal(await page.locator('h1').count(),1);assert.equal(await page.getByText('Casa Serena',{exact:false}).count(),0);ok('Ruta JSF '+route);}
  await page.goto(base+'/huespedes.xhtml');await page.locator('[id="guest:save"]').click();await page.getByText('Ingrese el nombre completo.',{exact:true}).first().waitFor();ok('Validación JSF obligatorios');
  const key='APF2'+Date.now().toString().slice(-10); fs.writeFileSync(path.join(output,'test-marker.json'),JSON.stringify({document:key}));
  await page.locator('[id="guest:nombre"]').fill('Huésped de demostración APF2');await page.locator('[id="guest:documento"]').fill(key);await page.locator('[id="guest:telefono"]').fill('000000000');await page.locator('[id="guest:email"]').fill('demo@example.com');
  await page.locator('[id="guest:save"]').click();await page.getByText('Huésped registrado correctamente.',{exact:true}).waitFor();ok('Alta de huésped JSF con redirección');
  await page.screenshot({path:path.join(output,'03-formulario-jsf.png'),fullPage:true});
  await page.locator('[id="search:q"]').fill(key);await page.locator('[id="search:submit"]').click();assert.match(await page.locator('[id="guests"]').innerText(),new RegExp(key));ok('Búsqueda en h:dataTable');
  await page.goto(base+'/nueva-reserva.xhtml');
  const option=page.locator('[id="booking:cliente"] option').filter({hasText:key});await page.locator('[id="booking:cliente"]').selectOption(await option.getAttribute('value'));
  const room=await page.locator('[id="booking:habitacion"] option:not([disabled])').nth(1).getAttribute('value');await page.locator('[id="booking:habitacion"]').selectOption(room);
  const start=new Date();start.setUTCDate(start.getUTCDate()+100);const end=new Date(start);end.setUTCDate(end.getUTCDate()+2);const fmt=d=>`${String(d.getUTCDate()).padStart(2,'0')}/${String(d.getUTCMonth()+1).padStart(2,'0')}/${d.getUTCFullYear()}`;
  await page.locator('[id="booking:entrada"]').fill(fmt(start));await page.locator('[id="booking:salida"]').fill(fmt(end));await page.locator('[id="booking:personas"]').fill('1');await page.locator('[id="booking:observaciones"]').fill('Registro temporal para evidencias APF2.');
  await page.locator('[id="booking:save"]').click();await page.getByText(/registrada en estado PENDIENTE/).waitFor();ok('Reserva JSF persistida');
  let row=page.locator('tr').filter({hasText:key});await row.getByRole('button',{name:'Confirmar',exact:true}).click();await page.getByText('Estado de la reserva actualizado.',{exact:true}).waitFor();ok('Confirmación JSF');
  await page.goto(base+'/panel.xhtml');await page.screenshot({path:path.join(output,'02-panel-bootstrap.png'),fullPage:true});
  await page.goto(base+'/reservas.xhtml');await page.screenshot({path:path.join(output,'04-tabla-datos-jsf.png'),fullPage:true});
  await page.locator('[id="search:q"]').fill(key);await page.locator('[id="search:state"]').selectOption('CONFIRMADA');await page.locator('[id="search:submit"]').click();assert.match(await page.locator('[id="list:bookings"]').innerText(),new RegExp(key));ok('Filtro por estado y documento');
  row=page.locator('tr').filter({hasText:key});await row.getByRole('button',{name:'Cancelar',exact:true}).click();await page.getByText('Estado de la reserva actualizado.',{exact:true}).waitFor();assert.match(await page.locator('tr').filter({hasText:key}).innerText(),/CANCELADA/);ok('Cancelación JSF');
  const post=await context.request.post(base+'/huespedes.xhtml',{form:{'guest':'guest','guest:save':'Guardar huésped'}});assert.equal(post.status(),403);ok('POST sin ViewState rechazado');
  await page.setViewportSize({width:390,height:844});await page.goto(base+'/panel.xhtml');assert(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth));await page.getByRole('button',{name:'Abrir navegación'}).click();await page.getByRole('link',{name:'Habitaciones',exact:true}).click();await page.locator('h1').filter({hasText:'Habitaciones'}).waitFor();ok('Navegación móvil Bootstrap');await page.screenshot({path:path.join(output,'mobile.png'),fullPage:true});
  await page.setViewportSize({width:1440,height:1000});
  const xml=fs.readFileSync('src/main/webapp/WEB-INF/web.xml','utf8');const escape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
  await page.setContent(`<html lang="es"><meta charset="utf-8"><style>body{font:18px Segoe UI;margin:45px;color:#142b48}h1{font-size:26px}pre{font:18px/1.55 Consolas;white-space:pre-wrap;border-top:1px solid #ccc;padding-top:20px}</style><h1>src/main/webapp/WEB-INF/web.xml</h1><p>Archivo real de configuración · Sistema de Gestión y Reservas Hoteleras</p><pre>${escape(xml)}</pre></html>`);await page.screenshot({path:path.join(output,'01-web-xml.png'),fullPage:true});ok('Captura de configuración real');
  fs.writeFileSync(path.join(output,'browser-results.json'),JSON.stringify({base,results},null,2));
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
