package pe.edu.hotel;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.*;

@WebServlet(urlPatterns = {"/panel", "/reservas", "/nueva-reserva", "/huespedes", "/habitaciones"})
public class HotelServlet extends HttpServlet {
  private final HotelDao dao = new HotelDao();

  protected void doGet(HttpServletRequest req, HttpServletResponse res)
      throws ServletException, IOException {
    req.setCharacterEncoding("UTF-8");
    res.setContentType("text/html;charset=UTF-8");
    res.setHeader("Cache-Control", "no-store");
    res.setHeader("X-Content-Type-Options", "nosniff");
    res.setHeader("X-Frame-Options", "DENY");
    res.setHeader(
        "Content-Security-Policy",
        "default-src 'self'; style-src 'self'; script-src 'self'; img-src 'self' data:; form-action"
            + " 'self'; frame-ancestors 'none'");
    if (req.getSession().getAttribute("csrf") == null)
      req.getSession().setAttribute("csrf", UUID.randomUUID().toString());
    String page = req.getServletPath().substring(1);
    req.setAttribute("page", page);
    req.setAttribute("today", Rules.today());
    try {
      req.setAttribute("rooms", dao.rooms());
      req.setAttribute("guests", dao.guests(Optional.ofNullable(req.getParameter("q")).orElse("")));
      req.setAttribute(
          "bookings",
          dao.bookings(
              Optional.ofNullable(req.getParameter("q")).orElse(""),
              Optional.ofNullable(req.getParameter("estado")).orElse("")));
      req.getRequestDispatcher("/WEB-INF/views/app.jsp").forward(req, res);
    } catch (SQLException e) {
      log("Error JDBC", e);
      res.setStatus(503);
      req.setAttribute(
          "error",
          "No se pudo conectar con la base de datos. Revise la configuración del servidor.");
      req.getRequestDispatcher("/WEB-INF/views/error.jsp").forward(req, res);
    }
  }

  protected void doPost(HttpServletRequest req, HttpServletResponse res)
      throws ServletException, IOException {
    req.setCharacterEncoding("UTF-8");
    if (req.getSession(false) == null
        || !Objects.equals(req.getSession().getAttribute("csrf"), req.getParameter("csrf"))) {
      res.sendError(403, "Formulario expirado. Recargue la página.");
      return;
    }
    try {
      switch (Optional.ofNullable(req.getParameter("action")).orElse("")) {
        case "guest" -> {
          dao.guest(
              req.getParameter("nombre"),
              req.getParameter("documento"),
              req.getParameter("telefono"),
              req.getParameter("email"));
          req.getSession().setAttribute("flash", "Huésped registrado correctamente.");
        }
        case "reserve" -> {
          long id =
              dao.reserve(
                  Long.parseLong(req.getParameter("cliente")),
                  Long.parseLong(req.getParameter("habitacion")),
                  Web.parseDate(
                      Rules.text(req.getParameter("entrada"), 10, 10, "Fecha de entrada")),
                  Web.parseDate(
                      Rules.text(req.getParameter("salida"), 10, 10, "Fecha de salida")),
                  Integer.parseInt(req.getParameter("personas")),
                  req.getParameter("observaciones"));
          req.getSession()
              .setAttribute(
                  "flash", "Reserva #" + id + " registrada. Puede confirmarla desde el listado.");
        }
        case "state" -> {
          dao.state(Long.parseLong(req.getParameter("id")), req.getParameter("estado"));
          req.getSession().setAttribute("flash", "Estado de la reserva actualizado.");
        }
        default -> throw new IllegalArgumentException("Operación no válida.");
      }
      res.sendRedirect(
          req.getContextPath()
              + ("guest".equals(req.getParameter("action")) ? "/huespedes" : "/reservas"));
    } catch (IllegalArgumentException | java.time.DateTimeException e) {
      res.setStatus(400);
      req.setAttribute("error", e.getMessage());
      doGet(req, res);
    } catch (SQLException e) {
      log("Error al guardar", e);
      res.setStatus(409);
      req.setAttribute(
          "error",
          e.getErrorCode() == 1062
              ? "Ya existe un huésped con este documento."
              : "No fue posible guardar. Verifique que el huésped y la habitación existan.");
      doGet(req, res);
    }
  }
}
