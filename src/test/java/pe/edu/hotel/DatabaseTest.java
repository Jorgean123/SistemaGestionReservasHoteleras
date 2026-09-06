package pe.edu.hotel;

import static org.junit.jupiter.api.Assertions.*;

import java.sql.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

@EnabledIfEnvironmentVariable(named = "HOTEL_INTEGRATION", matches = "true")
class DatabaseTest {
  HotelDao dao = new HotelDao();
  long guest, room;

  @BeforeEach
  void setup() throws Exception {
    guest =
        dao.guest(
            "PRUEBA AUTOMATIZADA",
            "T" + UUID.randomUUID().toString().substring(0, 12),
            "999000999",
            "prueba@example.invalid");
    try (var c = Database.open();
        var p =
            c.prepareStatement(
                "INSERT INTO"
                    + " habitaciones(capacidad,descripcion,habilitada,numero,precio_noche,tipo)"
                    + " VALUES(2,'Prueba temporal',1,?,145.00,'DOBLE')",
                Statement.RETURN_GENERATED_KEYS)) {
      p.setString(1, "T" + UUID.randomUUID().toString().substring(0, 8));
      p.executeUpdate();
      try (var r = p.getGeneratedKeys()) {
        r.next();
        room = r.getLong(1);
      }
    }
  }

  @AfterEach
  void cleanup() throws Exception {
    try (var c = Database.open()) {
      for (String sql :
          List.of(
              "DELETE FROM reservas WHERE habitacion_id=?",
              "DELETE FROM habitaciones WHERE id=?",
              "DELETE FROM clientes WHERE id=?")) {
        try (var p = c.prepareStatement(sql)) {
          p.setLong(1, sql.contains("clientes") ? guest : room);
          p.executeUpdate();
        }
      }
    }
  }

  @Test
  void persistsPriceAndRejectsOverlapAndAllowsAdjacent() throws Exception {
    LocalDate d = Rules.today().plusDays(40);
    long id = dao.reserve(guest, room, d, d.plusDays(3), 2, "");
    var b = dao.query("SELECT * FROM reservas WHERE id=?", id).getFirst();
    assertEquals("435.00", b.get("total").toString());
    assertEquals("PENDIENTE", b.get("estado"));
    assertThrows(
        IllegalArgumentException.class,
        () -> dao.reserve(guest, room, d.plusDays(2), d.plusDays(4), 2, ""));
    assertTrue(dao.reserve(guest, room, d.plusDays(3), d.plusDays(4), 2, "") > 0);
  }

  @Test
  void cancellationReleasesAndCannotReconfirm() throws Exception {
    LocalDate d = Rules.today().plusDays(50);
    long id = dao.reserve(guest, room, d, d.plusDays(2), 1, "");
    dao.state(id, "CONFIRMADA");
    dao.state(id, "CANCELADA");
    assertThrows(IllegalArgumentException.class, () -> dao.state(id, "CONFIRMADA"));
    assertTrue(dao.reserve(guest, room, d, d.plusDays(2), 1, "") > 0);
  }

  @Test
  void invalidGuestRollsBack() throws Exception {
    LocalDate d = Rules.today().plusDays(60);
    assertThrows(SQLException.class, () -> dao.reserve(-1, room, d, d.plusDays(2), 1, ""));
    assertEquals(0, dao.query("SELECT id FROM reservas WHERE habitacion_id=?", room).size());
  }

  @Test
  void concurrentReservationsOnlyOneSucceeds() throws Exception {
    LocalDate d = Rules.today().plusDays(70);
    CountDownLatch start = new CountDownLatch(1);
    try (var pool = Executors.newFixedThreadPool(2)) {
      Callable<Boolean> attempt =
          () -> {
            start.await();
            try {
              dao.reserve(guest, room, d, d.plusDays(2), 1, "");
              return true;
            } catch (IllegalArgumentException e) {
              return false;
            }
          };
      Future<Boolean> a = pool.submit(attempt), b = pool.submit(attempt);
      start.countDown();
      assertNotEquals(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS));
    }
  }

  @Test
  void duplicateDocumentRejected() throws Exception {
    String doc =
        dao.query("SELECT documento FROM clientes WHERE id=?", guest)
            .getFirst()
            .get("documento")
            .toString();
    assertThrows(SQLException.class, () -> dao.guest("Otro huésped", doc, "999000000", ""));
  }
}
