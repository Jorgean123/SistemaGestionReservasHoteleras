# Sistema de Gestión y Reservas Hoteleras

Proyecto APF1 de Desarrollo Web Integrado. Prototipo local de recepción con Java, JSP, Servlets y JDBC. La identidad visual «Casa Serena» es ficticia y sirve únicamente para la demostración académica.

## Abrir el sistema

**http://localhost:8080/hotel/**

El WAR está desplegado en `C:\apache-tomcat-11.0.24\webapps\hotel.war`. Se usa la base MySQL existente `hotel_reservas`; se conservan las cinco habitaciones originales y sus tarifas. No se requiere iniciar sesión: autenticación y roles quedan fuera de este avance.

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
| JDK de compilación | Eclipse Temurin 21.0.6 |
| JDK del Tomcat existente | Oracle JDK 25.0.3 |
| Maven | 3.9.11 |
| Tomcat | 11.0.24, puerto 8080 |
| Servlet / JSP | Jakarta Servlet 6.1 / Jakarta Pages 4.0 |
| MySQL | 9.0.1 |
| Connector/J | 9.7.0 |
| Pruebas | JUnit Jupiter 5.11.4 |

Tomcat 11 utiliza el espacio de nombres `jakarta.*`, evolución de Java EE. Es un contenedor Servlet/JSP, no una implementación completa de Jakarta EE. Véase la [guía oficial](https://tomcat.apache.org/migration-11.0.html).

## Compilar y desplegar en este equipo

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build.ps1 -Integration
powershell -ExecutionPolicy Bypass -File scripts/deploy.ps1
```

Maven está disponible localmente en `.tools/apache-maven-3.9.11`. Para otra máquina, instale JDK 21 y Maven 3.9.11 y ejecute `mvn verify`. Copie `target/hotel.war` a `webapps` de Tomcat.

Las pruebas JDBC se activan con `HOTEL_INTEGRATION=true` y requieren acceso a MySQL. Crean habitaciones, huéspedes y reservas temporales y eliminan únicamente esos registros. Sin esa variable se ejecutan solo las seis pruebas unitarias. La configuración puede leerse mediante `-Dcatalina.base=C:\apache-tomcat-11.0.24`.

## Configuración MySQL

La contraseña se almacena fuera del proyecto y del WAR, en `C:\apache-tomcat-11.0.24\conf\hotel-db.properties`. El ejemplo sin contraseña está en `config/hotel-db.properties.example`. También se aceptan `HOTEL_DB_URL`, `HOTEL_DB_USER` y `HOTEL_DB_PASSWORD`.

La conexión actual utiliza `root`, como exige el enunciado. `sslMode=DISABLED` corresponde a esta conexión local. Para instalaciones remotas deben configurarse TLS y credenciales con permisos limitados.

`sql/schema.sql` documenta el esquema existente, sin datos ni contraseñas y sin sentencias DROP TABLE. No necesita ejecutarse sobre la base actual. Para una instalación nueva, cree `hotel_reservas` con UTF-8, importe el esquema y luego ejecute `sql/seed_habitaciones.sql`. No se incluyen datos personales ni usuarios originales.

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

Se ejecutaron 11 pruebas Java/JDBC y 17 comprobaciones HTTP. Los resultados están en `docs/evidencias`. Se verifica concurrencia, reversión de transacciones, XSS por escape, CSRF, validación y persistencia. El navegador de la sesión no estuvo disponible; no se afirma haber realizado revisión visual ni interacción manual en navegador. La adaptación móvil está implementada mediante CSS y debe verificarse visualmente antes de exposición final.

Este avance no implementa autenticación, roles, edición de tarifas, check-in/check-out operacional, facturación ni pagos. `usuarios` se conserva como parte de la base original para futuras iteraciones. El acceso debe limitarse al entorno académico local.

## Informe y repositorio

Informe: `docs/Informe_APF1.docx` y fuente editable `docs/Informe_APF1.md`.

Pendientes del equipo: NRC, código universitario de Sandro Johnatan Zea Carrasco y enlace GitHub. No se inventó una URL ni se publicó el código en una cuenta no indicada. Para publicar, cree un repositorio y configure su URL real:

```powershell
git add .
git commit -m "Implementar avance APF1 de reservas hoteleras"
git branch -M main
git remote add origin URL_REAL_DEL_REPOSITORIO
git push -u origin main
```
