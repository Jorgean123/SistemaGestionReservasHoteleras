# Avance de Proyecto Final 2 (APF2)

## Carátula

**Universidad Tecnológica del Perú**  
Facultad de Ingeniería  
Programa de Ingeniería de Sistemas e Informática  
Curso: Desarrollo Web Integrado (1000005154)  
Evaluación: Avance de Proyecto Final 2 — Semana 10  

**Sistema de Gestión y Reservas Hoteleras**  
**Implementación con Jakarta Faces (JSF), Facelets y Bootstrap**

**Integrantes**

- Acosta Loyola, Jorge Eduardo — U22205593
- Anchorena Pérez, César — U18209414
- Zea Carrasco, Sandro Johnatan — U23201057

**Docente:** Mgtr. Ing. César Augusto Cárdenas Latorre  
**Ciclo:** 2026 — Ciclo 2 (agosto)  
**Fecha:** 13 de octubre de 2026  
**NRC:** 1SI54.

[[IMAGE:evidencias/apf2/00-logo-utp.png|Identidad institucional]]

[[PAGE_BREAK]]

## Índice de contenidos

[[TOC]]

[[PAGE_BREAK]]

# CAPÍTULO 1. ASPECTOS GENERALES Y ESTADO DEL PROYECTO

## 1.1 Antecedentes y evolución desde APF1

El APF1 dejó una aplicación web de recepción con Java, Servlets, páginas JSP y persistencia JDBC en MySQL. Permitía consultar habitaciones, registrar huéspedes y crear, confirmar o cancelar reservas. También incluía validación de fechas y capacidad, control de disponibilidad, protección CSRF y consultas parametrizadas.

En el APF2 se conserva el dominio, el esquema relacional y las operaciones de persistencia del proyecto. La interfaz de las operaciones principales se reorganizó como vistas Facelets XHTML procesadas por Jakarta Faces. Managed Beans reciben las acciones de los formularios, mientras las clases DAO y DTO mantienen la separación entre presentación y datos.

La aplicación corresponde a una demostración académica local para el personal de recepción del hotel ficticio «Casa Serena». Las reservas pendientes y confirmadas bloquean las fechas; las canceladas las liberan. El sistema no procesa pagos ni representa comprobantes tributarios.

## 1.2 Objetivo del APF2

Implementar una interfaz web basada en componentes JSF y Bootstrap para gestionar habitaciones, huéspedes y reservas, conectándola con la base MySQL y la capa de persistencia desarrollada en el APF1.

## 1.3 Alcance de esta entrega

El avance comprende la migración de navegación y pantallas operativas a XHTML/Facelets; el uso de CDI Managed Beans y Expression Language (EL); la consulta y actualización de información con JDBC/DAO; tablas de datos con filtros y navegación por páginas; y estilos adaptables con Bootstrap 5.

La aplicación no incluye autenticación de usuarios, control de roles, pagos, facturación ni un proceso operacional de check-in/check-out. Estas funciones se mantienen como trabajo futuro.

# CAPÍTULO 2. CONFIGURACIÓN DE LA ARQUITECTURA JSF Y ENTORNO WEB

## 2.1 Entorno de ejecución

El proyecto se compila como archivo WAR con Maven 3.9.11 y Java con nivel de lenguaje objetivo 21. Se ejecuta en Apache Tomcat 11.0.24, usando Jakarta Servlet 6.1, Jakarta Faces 4.1.18 y Weld Servlet 6.0.4.Final para CDI. La persistencia usa MySQL Connector/J 9.7.0 y la instancia local MySQL 8.0.46.

En este equipo Tomcat atiende en `http://localhost:8088/hotel/`. Se eligió el puerto 8088 porque los puertos 8080 y 8081 ya estaban ocupados por servicios existentes; no se detuvieron ni modificaron dichos servicios. La configuración de conexión MySQL se mantiene fuera del repositorio y no forma parte del WAR.

## 2.2 Configuración de JSF y navegación

El descriptor `src/main/webapp/WEB-INF/web.xml` declara el `FacesServlet` de Jakarta Faces y lo asigna a las rutas `*.xhtml`. También establece el idioma predeterminado de la interfaz por medio de `faces-config.xml`, activa el almacenamiento de estado JSF en el servidor, define `panel.xhtml` como página de inicio y presenta una página controlada cuando vence la vista.

La configuración `WEB-INF/beans.xml` habilita la detección CDI basada en anotaciones. Las dependencias de Jakarta Faces y Weld se incluyen en el proyecto Maven para que Tomcat pueda procesar Facelets y crear los beans.

### Evidencia 1. Descriptor web.xml

[[IMAGE:evidencias/apf2/01-web-xml.png|Configuración efectiva del FacesServlet y de las sesiones]]

## 2.3 Organización por capas

La solución conserva la organización MVC, adaptada a JSF:

| Capa | Paquete o ubicación | Responsabilidad |
|---|---|---|
| Vistas | `src/main/webapp/*.xhtml` | Formularios, tablas, navegación y expresiones EL. |
| Plantilla visual | `WEB-INF/templates/layout.xhtml` | Estructura común, menú, mensajes y recursos compartidos. |
| Managed Bean | `pe.edu.hotel.beans.HotelBean` | Estado de la vista, validación del flujo y acciones del usuario. |
| DAO / repositorio | `pe.edu.hotel.dao.HotelRepository` | Consultas y operaciones de persistencia JDBC. |
| Modelo / DTO | `pe.edu.hotel.model.HotelRow` | Proyección de datos para las tablas y vistas; evita exponer JDBC en Facelets. |
| Compatibilidad y reglas | `pe.edu.hotel.HotelDao`, `Rules`, `Web`, `Database` | Reutilización de consultas, reglas de negocio, formatos y conexión a MySQL. |

La clase `HotelRepository` adapta los resultados del DAO existente a objetos `HotelRow`. De esta forma, las vistas no abren conexiones JDBC ni construyen consultas SQL.

# CAPÍTULO 3. DISEÑO DE INTERFACES CON BOOTSTRAP

## 3.1 Estilos y adaptación a dispositivos

Las vistas reutilizan una plantilla Facelets con una barra de navegación común, título y descripción contextual, mensajes de operación y pie de página. Bootstrap 5.3.8 se integra desde archivos locales empaquetados en la aplicación, evitando depender de una CDN durante la ejecución.

Las clases de cuadrícula `row`, `col-lg-*` y `col-md-*` adaptan los formularios y las tarjetas a distintos anchos. Las tablas se ubican dentro de contenedores responsivos y el menú puede contraerse para navegación móvil. El CSS propio complementa Bootstrap con la identidad visual de recepción.

## 3.2 Componentes empleados

- Barra de navegación adaptativa para panel, reservas, habitaciones y huéspedes.
- Tarjetas y cuadrículas para indicadores del panel y formularios.
- Etiquetas, mensajes de validación y alertas de resultado.
- Tablas con encabezados, filtros y acciones por fila.
- Botones de confirmación y cancelación con estilos diferenciados.

### Evidencia 2. Panel principal

[[IMAGE:evidencias/apf2/02-panel-bootstrap.png|Panel de recepción con indicadores y accesos]]

# CAPÍTULO 4. VISTAS FACELETS, MANAGED BEANS Y EXPRESSION LANGUAGE

## 4.1 Vistas XHTML

Las páginas `panel.xhtml`, `habitaciones.xhtml`, `huespedes.xhtml`, `reservas.xhtml` y `nueva-reserva.xhtml` usan Facelets y componentes Jakarta Faces como `<h:form>`, `<h:inputText>`, `<h:selectOneMenu>`, `<h:commandButton>`, `<h:messages>` y `<h:dataTable>`.

Los campos obligatorios, longitudes máximas y rangos se validan en los componentes JSF. Las reglas de negocio —como fechas, capacidad y disponibilidad— también se comprueban en el servidor y en la capa de persistencia.

## 4.2 Managed Bean y alcance

`HotelBean` se registra con `@Named("hotelBean")` y `@ViewScoped`. El alcance de vista conserva el estado necesario durante las solicitudes AJAX/postback de una misma vista y evita compartir accidentalmente los campos del formulario entre pantallas. El bean implementa `Serializable` e inyecta `HotelRepository` mediante CDI.

Al inicializarse, el bean carga habitaciones, huéspedes y reservas. Sus acciones principales son `saveGuest()`, `saveBooking()`, `searchGuests()`, `searchBookings()` y `changeState(...)`. Después de una operación exitosa se utiliza el patrón Post/Redirect/Get y mensajes flash para evitar reenvíos involuntarios del formulario.

## 4.3 Enlace con Expression Language

Las expresiones EL enlazan componentes con propiedades y acciones del bean. Por ejemplo:

```xhtml
<h:inputText id="nombre" value="#{hotelBean.nombre}" required="true"/>
<h:commandButton value="Guardar huésped" action="#{hotelBean.saveGuest}"/>
```

La tabla de huéspedes obtiene su lista desde el mismo bean:

```xhtml
<h:dataTable value="#{hotelBean.guests}" var="g">
    <h:column>#{g.nombre}</h:column>
</h:dataTable>
```

La vista enlaza datos y eventos; el bean coordina las operaciones, y el repositorio accede a la capa JDBC.

### Evidencia 3. Formulario JSF

[[IMAGE:evidencias/apf2/03-formulario-jsf.png|Formulario y directorio JSF con los DNI actuales de los integrantes]]

# CAPÍTULO 5. NAVEGACIÓN Y TABLAS DE DATOS DINÁMICAS

## 5.1 Flujo de navegación

El menú compartido permite acceder al panel, las reservas, las habitaciones y los huéspedes. Desde el panel o las demás vistas se puede abrir el formulario de nueva reserva. Los enlaces JSF usan outcomes implícitos y las operaciones de escritura redirigen a la pantalla de resultado conservando el mensaje correspondiente.

Un filtro de compatibilidad redirige las rutas anteriores sin extensión —por ejemplo, `/reservas`— a las vistas JSF `.xhtml`. Las páginas principales verificadas son `/panel.xhtml`, `/habitaciones.xhtml`, `/huespedes.xhtml`, `/reservas.xhtml` y `/nueva-reserva.xhtml`.

## 5.2 Datos y paginación

El componente `<h:dataTable>` presenta dinámicamente habitaciones, huéspedes y reservas con información obtenida desde MySQL mediante DAO/JDBC. Los resultados de reservas admiten búsqueda por huésped, documento o número y filtro por estado. El directorio de huéspedes permite buscar por nombre o documento. Las tablas se configuran para presentar hasta diez registros por página, con acciones anterior y siguiente.

En la vista de reservas, cada fila puede ofrecer confirmación para reservas pendientes y cancelación para reservas pendientes o confirmadas. El servidor vuelve a verificar las transiciones válidas y la disponibilidad antes de persistir los cambios.

### Evidencia 4. Tabla dinámica de reservas

[[IMAGE:evidencias/apf2/04-tabla-datos-jsf.png|Reservas recuperadas desde MySQL con DNI, habitación, fechas y estado]]

## 5.3 Validación funcional

Se ejecutó una prueba automatizada en navegador que comprobó quince escenarios: cinco rutas JSF; validación de campos obligatorios; registro y búsqueda de huésped; persistencia de una reserva; confirmación y cancelación; filtros por documento y estado; rechazo de POST sin ViewState; navegación móvil con Bootstrap; y captura de la configuración real.

Los quince escenarios reportaron resultado satisfactorio en `docs/evidencias/apf2/browser-results.json`. Además, la compilación Maven con pruebas de integración JDBC ejecutó once pruebas sin fallas. Los reportes de prueba son evidencia técnica; antes de entregar, se recomienda volver a ejecutarlos sobre la base y servidor que se utilizarán para la demostración.

Como verificación adicional, se consultó cada DNI en el filtro de `/reservas.xhtml` y se confirmó su recuperación desde MySQL: Jorge Acosta Loyola (45154878, reserva #27, habitación 101, 14–16/10/2026), César Anchorena Pérez (45784512, reserva #35, habitación 102, 18–20/10/2026) y Sandro Johnatan Zea Carrasco (16261548, reserva #36, habitación 201, 21–23/10/2026). Las tres reservas están pendientes. Se conservó como historial la reserva cancelada #34 de César. Los resultados de estas tres búsquedas se registran en `docs/evidencias/apf2/dni-search-results.json`.

[[IMAGE:evidencias/apf2/mobile.png|Vista compacta del directorio, con navegación colapsada y DNI visibles]]

# CAPÍTULO 6. CONCLUSIONES Y TRAZABILIDAD HACIA EL PROYECTO FINAL

## 6.1 Conclusiones técnicas

1. Jakarta Faces permitió modelar formularios, acciones, mensajes y tablas como componentes vinculados a un bean en lugar de resolver todo el flujo directamente en Servlets/JSP.
2. La separación entre Facelets, Managed Bean, repositorio y DTO mantiene la capa visual desacoplada de las consultas JDBC reutilizadas del APF1.
3. Bootstrap local y la plantilla común dieron consistencia a las pantallas y habilitaron navegación adaptativa sin depender de recursos externos.
4. La compilación, las pruebas JDBC y los escenarios de navegador aportan evidencia de funcionamiento de las rutas, formularios, filtros y transiciones de reserva.

## 6.2 Trabajo previsto para el Proyecto Final

- Completar autenticación, autorización y roles de recepción y administración.
- Revisar la creación y administración de usuarios con almacenamiento seguro de credenciales.
- Incorporar un flujo de check-in/check-out, manteniendo separada la reserva del registro operativo de estadía.
- Evaluar una API REST para integrar otros canales de reserva y desarrollar una estrategia de despliegue reproducible.
- Completar pruebas de seguridad, accesibilidad y validación visual en los dispositivos previstos.
- Confirmar con el equipo los datos académicos pendientes y respaldar en GitHub los cambios del APF2.

# CAPÍTULO 7. REFERENCIAS, EVIDENCIAS Y REPOSITORIO

## 7.1 Repositorio

**Repositorio del proyecto:** [https://github.com/Jorgean123/SistemaGestionReservasHoteleras](https://github.com/Jorgean123/SistemaGestionReservasHoteleras)

El enlace corresponde al repositorio del equipo utilizado para APF1. Al preparar este borrador, los cambios recientes de JSF y las evidencias APF2 estaban en el espacio de trabajo local y no se encontró un commit APF2 publicado. Por ello, no se adjunta una captura ficticia del historial: después de publicar los cambios, actualizar esta sección con el SHA de los commits y una captura del historial en GitHub.

## 7.2 Evidencias adjuntas

Las capturas incluidas en este informe se encuentran también en `docs/evidencias/apf2/`:

1. `01-web-xml.png`: configuración del `FacesServlet`.
2. `02-panel-bootstrap.png`: panel principal.
3. `03-formulario-jsf.png`: registro y directorio de huéspedes.
4. `04-tabla-datos-jsf.png`: tabla de reservas y acciones.
5. `mobile.png`: navegación adaptada a ventana móvil.
6. `dni-search-results.json`: resultado de búsqueda por DNI para los tres integrantes.

**Pendiente para la entrega final:** agregar la captura número 05 solicitada por la plantilla, con el historial de commits APF2 visible en GitHub.

## 7.3 Referencias técnicas

- Jakarta Faces 4.1: [https://jakarta.ee/specifications/faces/4.1/](https://jakarta.ee/specifications/faces/4.1/)
- Apache Tomcat 11: [https://tomcat.apache.org/tomcat-11.0-doc/](https://tomcat.apache.org/tomcat-11.0-doc/)
- Bootstrap 5: [https://getbootstrap.com/docs/5.3/](https://getbootstrap.com/docs/5.3/)
- MySQL Connector/J: [https://dev.mysql.com/doc/connector-j/en/](https://dev.mysql.com/doc/connector-j/en/)
- Repositorio del proyecto: [https://github.com/Jorgean123/SistemaGestionReservasHoteleras](https://github.com/Jorgean123/SistemaGestionReservasHoteleras)

## Estado del borrador

El contenido se redactó a partir de la guía oficial APF2, el informe APF1, la implementación y las evidencias disponibles. Antes de presentar el documento, el equipo debe comprobar los datos de portada y publicar los cambios APF2 para completar la evidencia de commits.
