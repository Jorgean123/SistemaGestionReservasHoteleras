package pe.edu.hotel;

import java.nio.file.*;
import java.sql.*;
import java.util.Properties;

public final class Database {
  private Database() {}

  public static Connection open() throws SQLException {
    Properties p = new Properties();
    Path file = Path.of(System.getProperty("catalina.base", "."), "conf", "hotel-db.properties");
    try {
      if (Files.exists(file))
        try (var in = Files.newInputStream(file)) {
          p.load(in);
        }
      Class.forName("com.mysql.cj.jdbc.Driver");
    } catch (Exception e) {
      throw new SQLException("No se pudo cargar la configuración JDBC", e);
    }
    String url =
        System.getenv()
            .getOrDefault(
                "HOTEL_DB_URL",
                p.getProperty(
                    "url",
                    "jdbc:mysql://127.0.0.1:3306/hotel_reservas?connectionTimeZone=America/Lima"));
    String user = System.getenv().getOrDefault("HOTEL_DB_USER", p.getProperty("user", "root"));
    String password =
        System.getenv().getOrDefault("HOTEL_DB_PASSWORD", p.getProperty("password", ""));
    return DriverManager.getConnection(url, user, password);
  }
}
