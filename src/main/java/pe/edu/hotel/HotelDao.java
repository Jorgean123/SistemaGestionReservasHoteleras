package pe.edu.hotel;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.*;

public class HotelDao {
  public List<Map<String, Object>> query(String sql, Object... args) throws SQLException {
    try (Connection c = Database.open();
        PreparedStatement p = c.prepareStatement(sql)) {
      bind(p, args);
      try (ResultSet r = p.executeQuery()) {
        return rows(r);
      }
    }
  }

  static void bind(PreparedStatement p, Object... args) throws SQLException {
    for (int i = 0; i < args.length; i++) p.setObject(i + 1, args[i]);
  }

  static List<Map<String, Object>> rows(ResultSet r) throws SQLException {
    List<Map<String, Object>> list = new ArrayList<>();
    while (r.next()) {
      Map<String, Object> m = new LinkedHashMap<>();
      for (int i = 1; i <= r.getMetaData().getColumnCount(); i++)
        m.put(r.getMetaData().getColumnLabel(i), r.getObject(i));
      list.add(m);
    }
    return list;
  }

  public List<Map<String, Object>> rooms() throws SQLException {
    return query("SELECT * FROM habitaciones ORDER BY numero");
  }

  public List<Map<String, Object>> guests(String search) throws SQLException {
    return query(
        "SELECT * FROM clientes WHERE nombre LIKE ? OR documento LIKE ? ORDER BY id DESC",
        "%" + search + "%",
        "%" + search + "%");
  }

  public List<Map<String, Object>> bookings(String search, String state) throws SQLException {
    return query(
        "SELECT r.*, c.nombre, c.documento, h.numero, h.tipo FROM reservas r JOIN clientes c ON"
            + " c.id=r.cliente_id JOIN habitaciones h ON h.id=r.habitacion_id WHERE (c.nombre LIKE"
            + " ? OR c.documento LIKE ? OR CAST(r.id AS CHAR)=?) AND (?='' OR r.estado=?) ORDER BY"
            + " r.fecha_entrada DESC,r.id DESC",
        "%" + search + "%",
        "%" + search + "%",
        search,
        state,
        state);
  }

  public long guest(String name, String document, String phone, String email) throws SQLException {
    name = Rules.text(name, 3, 100, "Nombre");
    document = Rules.text(document, 6, 15, "Documento");
    phone = Rules.text(phone, 6, 20, "Teléfono");
    email = Rules.text(email, 0, 100, "Correo");
    if (!email.isEmpty() && !email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"))
      throw new IllegalArgumentException("Ingrese un correo válido.");
    try (Connection c = Database.open();
        PreparedStatement p =
            c.prepareStatement(
                "INSERT INTO clientes(nombre,documento,telefono,email,fecha_registro)"
                    + " VALUES(?,?,?,?,NOW())",
                Statement.RETURN_GENERATED_KEYS)) {
      bind(p, name, document, phone, email);
      p.executeUpdate();
      try (ResultSet r = p.getGeneratedKeys()) {
        r.next();
        return r.getLong(1);
      }
    }
  }

  public long reserve(
      long guest, long room, LocalDate start, LocalDate end, int people, String notes)
      throws SQLException {
    notes = Rules.text(notes, 0, 250, "Observaciones");
    try (Connection c = Database.open()) {
      c.setAutoCommit(false);
      try {
        BigDecimal rate;
        int capacity;
        try (PreparedStatement p =
            c.prepareStatement(
                "SELECT capacidad,precio_noche,habilitada FROM habitaciones WHERE id=? FOR"
                    + " UPDATE")) {
          bind(p, room);
          try (ResultSet r = p.executeQuery()) {
            if (!r.next() || !r.getBoolean("habilitada"))
              throw new IllegalArgumentException("Habitación no disponible.");
            capacity = r.getInt(1);
            rate = r.getBigDecimal(2);
          }
        }
        long nights = Rules.stay(start, end, people, capacity);
        try (PreparedStatement p =
            c.prepareStatement(
                "SELECT id FROM reservas WHERE habitacion_id=? AND estado<>'CANCELADA' AND"
                    + " fecha_entrada<? AND fecha_salida>? FOR UPDATE")) {
          bind(p, room, end, start);
          try (ResultSet r = p.executeQuery()) {
            if (r.next())
              throw new IllegalArgumentException(
                  "La habitación ya tiene una reserva en estas fechas. Elija otra habitación o"
                      + " cambie la estancia.");
          }
        }
        try (PreparedStatement p =
            c.prepareStatement(
                "INSERT INTO"
                    + " reservas(estado,fecha_creacion,fecha_entrada,fecha_salida,noches,numero_huespedes,observaciones,precio_noche,total,cliente_id,habitacion_id)"
                    + " VALUES('PENDIENTE',NOW(),?,?,?,?,?,?,?,?,?)",
                Statement.RETURN_GENERATED_KEYS)) {
          bind(
              p,
              start,
              end,
              nights,
              people,
              notes,
              rate,
              rate.multiply(BigDecimal.valueOf(nights)),
              guest,
              room);
          p.executeUpdate();
          try (ResultSet r = p.getGeneratedKeys()) {
            r.next();
            long id = r.getLong(1);
            c.commit();
            return id;
          }
        }
      } catch (SQLException | RuntimeException e) {
        c.rollback();
        throw e;
      }
    }
  }

  public void state(long id, String state) throws SQLException {
    if (!Set.of("CONFIRMADA", "CANCELADA").contains(state))
      throw new IllegalArgumentException("Estado no válido.");
    try (Connection c = Database.open();
        PreparedStatement p =
            c.prepareStatement(
                "UPDATE reservas SET estado=? WHERE id=? AND (estado='PENDIENTE' OR"
                    + " (estado='CONFIRMADA' AND ?='CANCELADA'))")) {
      bind(p, state, id, state);
      if (p.executeUpdate() != 1)
        throw new IllegalArgumentException("La reserva ya cambió de estado o no existe.");
    }
  }
}
