package pe.edu.hotel;

import java.time.*;
import java.time.temporal.ChronoUnit;

public final class Rules {
  public static LocalDate today() {
    return LocalDate.now(ZoneId.of("America/Lima"));
  }

  public static long stay(LocalDate start, LocalDate end, int people, int capacity) {
    long nights = ChronoUnit.DAYS.between(start, end);
    if (start.isBefore(today()))
      throw new IllegalArgumentException("La entrada no puede ser anterior a hoy.");
    if (nights < 1 || nights > 365)
      throw new IllegalArgumentException("La estancia debe tener entre 1 y 365 noches.");
    if (people < 1 || people > capacity)
      throw new IllegalArgumentException(
          "El número de huéspedes supera la capacidad de la habitación.");
    return nights;
  }

  public static String text(String value, int min, int max, String label) {
    String s = value == null ? "" : value.trim();
    if (s.length() < min || s.length() > max)
      throw new IllegalArgumentException(label + ": longitud no válida.");
    return s;
  }
}
