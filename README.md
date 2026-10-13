# Sistema de Gestión y Reservas Hoteleras

Proyecto APF1 de Desarrollo Web Integrado. Prototipo local de recepción con Java, JSP, Servlets y JDBC. La identidad visual «Casa Serena» es ficticia y sirve únicamente para la demostración académica.

## Abrir el sistema

**http://localhost:8088/hotel/**

El WAR se despliega en `C:\apache-tomcat-11.0.24\webapps\hotel.war`. Tomcat usa el puerto 8088 para no interferir con los servicios XAMPP que ya ocupan 8080 y 8081. En este equipo, `hotel_reservas` se creó desde `sql/schema.sql` y `sql/seed_habitaciones.sql` porque no existía; contiene cinco habitaciones iniciales, sin huéspedes ni reservas recuperados. No se requiere iniciar sesión: autenticación y roles quedan fuera de este avance.

## Funcionalidades

- Panel: ocupación confirmada para hoy, pendientes, huéspedes y valor histórico de reservas confirmadas.
- Habitaciones: catálogo, capacidad y tarifa por noche.
- Huéspedes: registro y búsqueda por nombre o documento; control de documento duplicado.
- Reservas: alta, filtros, confirmación y cancelación.
- Estancias de 1 a 365 noches; validación de capacidad, fechas y disponibilidad en el servidor.
- Prevención de reservas superpuestas con bloqueo de habitación y transacción InnoDB.
- Consultas parametrizadas, escape HTML, protección CSRF y patrón POST/Redirect/GET.

## Tecnologías y entorno verificado

| Componente | Versión |
|---|---|
| JDK de compilación y Tomcat | Eclipse Temurin 25.0.2 (`--release 21`) |
| Maven | 3.9.11 |
| Tomcat | 11.0.24, puerto 8088 |
| Servlet / JSP | Jakarta Servlet 6.1 / Jakarta Pages 4.0 |
| MySQL | 8.0.46 |
| Connector/J | 9.7.0 |
| Pruebas | JUnit Jupiter 5.11.4 |

Tomcat 11 utiliza el espacio de nombres `jakarta.*`, evolución de Java EE. Es un contenedor Servlet/JSP, no una implementación completa de Jakarta EE. Véase la [guía oficial](https://tomcat.apache.org/migration-11.0.html).

## Compilar y desplegar en este equipo

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build.ps1 -Integration
powershell -ExecutionPolicy Bypass -File scripts/deploy.ps1
```

Maven está disponible localmente en `.tools/apache-maven-3.9.11`. Para otra máquina, instale JDK 21 y Maven 3.9.11 y ejecute `mvn verify`. Copie `target/hotel.war` a `webapps` de Tomcat.

Para iniciar Tomcat en esta máquina:

```powershell
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-25.0.2.10-hotspot'
$env:JRE_HOME=$env:JAVA_HOME
$env:CATALINA_HOME='C:\apache-tomcat-11.0.24'
$env:CATALINA_BASE=$env:CATALINA_HOME
& "$env:CATALINA_HOME\bin\startup.bat"
```

Las pruebas JDBC se activan con `HOTEL_INTEGRATION=true` y requieren acceso a MySQL. Crean habitaciones, huéspedes y reservas temporales y eliminan únicamente esos registros. Sin esa variable se ejecutan solo las seis pruebas unitarias. La configuración puede leerse mediante `-Dcatalina.base=C:\apache-tomcat-11.0.24`.

## Configuración MySQL

La contraseña se almacena fuera del proyecto y del WAR, en `C:\apache-tomcat-11.0.24\conf\hotel-db.properties`. El ejemplo sin contraseña está en `config/hotel-db.properties.example`. También se aceptan `HOTEL_DB_URL`, `HOTEL_DB_USER` y `HOTEL_DB_PASSWORD`.

La conexión actual utiliza `root`, como exige el enunciado. `sslMode=DISABLED` corresponde a esta conexión local. Para instalaciones remotas deben configurarse TLS y credenciales con permisos limitados.

`sql/schema.sql` documenta el esquema sin datos ni contraseñas y sin sentencias DROP TABLE. En este equipo se ejecutó porque `hotel_reservas` no existía; luego se ejecutó `sql/seed_habitaciones.sql`. Para otra instalación nueva, cree `hotel_reservas` con UTF-8, importe el esquema y cargue el catálogo inicial. No se recuperaron huéspedes, reservas ni usuarios anteriores.

## Recorrido de demostración

1. Abra **Huéspedes** y registre nombre, DNI o pasaporte, teléfono y correo opcional.
2. Abra **Nueva reserva**, seleccione ese huésped y una habitación.
3. Seleccione entrada desde hoy, salida posterior y cantidad de huéspedes válida. Ingrese las fechas en formato día/mes/año (`dd/mm/aaaa`), por ejemplo `05/09/2026`.
4. Guarde la reserva; aparecerá como **PENDIENTE** y bloqueará las fechas.
5. Confírmela desde **Reservas**. Su importe se incorpora al valor confirmado del panel.
6. Intente reservar la misma habitación con fechas superpuestas: el servidor lo rechazará.
7. Cancele la reserva: esas fechas vuelven a quedar disponibles.

La fecha de salida no bloquea la siguiente estancia: una reserva puede empezar el mismo día en que termina otra. Las canceladas no se pueden reactivar. Los importes son tarifas de alojamiento; no representan pagos ni comprobantes tributarios.

## Organización

```text
src/main/java/pe/edu/hotel/
  Database.java       Configuración y conexión JDBC
  HotelDao.java       Consultas y transacciones
  Rules.java          Reglas de negocio
  HotelServlet.java   Controlador HTTP
  Web.java            Escape HTML y formato monetario
src/main/webapp/
  WEB-INF/views/      Vistas JSP protegidas del acceso directo
  assets/            CSS y JavaScript sin dependencias externas
src/test/java/        Pruebas unitarias y de integración
sql/                 Esquema y catálogo inicial
scripts/             Compilación, despliegue y pruebas HTTP
docs/                Informe APF1, diagramas y evidencias
```

## Verificación y límites

En esta recuperación, `scripts/build.ps1 -Integration` compiló el WAR y pasó 11 pruebas Java/JDBC (5 de integración y 6 unitarias). También se comprobaron cinco rutas HTTP, todas con respuesta 200, y la visualización de las cinco habitaciones iniciales. Las 17 comprobaciones de `docs/evidencias/http-resultados.json` son evidencia previa; no se repitieron aquí porque Python no está instalado. El script `scripts/http_smoke.py` permite configurar `HOTEL_BASE_URL` y `MYSQL_BIN` para volver a ejecutarlas. El navegador de la sesión no estuvo disponible; no se afirma haber realizado revisión visual ni interacción manual en navegador. La adaptación móvil está implementada mediante CSS y debe verificarse visualmente antes de exposición final.

Este avance no implementa autenticación, roles, edición de tarifas, check-in/check-out operacional, facturación ni pagos. La tabla `usuarios` está vacía y se conserva para futuras iteraciones. El acceso debe limitarse al entorno académico local.

## Informe y repositorio

Informe: `docs/Informe_APF1.docx` y fuente editable `docs/Informe_APF1.md`.

Repositorio: [Jorgean123/SistemaGestionReservasHoteleras](https://github.com/Jorgean123/SistemaGestionReservasHoteleras).

Si el informe original está abierto en Word, la versión más reciente se guarda como `docs/Informe_APF1_actualizado.docx` y se incluye como `Informe_APF1.docx` en el ZIP.

Pendientes del equipo: NRC y código universitario de Sandro Johnatan Zea Carrasco. Para descargar el código:

```powershell
git clone https://github.com/Jorgean123/SistemaGestionReservasHoteleras.git
```
