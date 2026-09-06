package pe.edu.hotel;

import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.ResolverStyle;
import java.util.Locale;

public final class Web {
  private static final DateTimeFormatter DATE =
      DateTimeFormatter.ofPattern("dd/MM/uuuu").withResolverStyle(ResolverStyle.STRICT);

  public static String date(Object value) {
    return value == null ? "" : LocalDate.parse(value.toString()).format(DATE);
  }

  public static LocalDate parseDate(String value) {
    try {
      return LocalDate.parse(value == null ? "" : value.trim(), DATE);
    } catch (java.time.format.DateTimeParseException e) {
      throw new IllegalArgumentException("Ingrese una fecha válida en formato día/mes/año (dd/mm/aaaa).");
    }
  }

  public static String esc(Object x) {
    return x == null
        ? ""
        : x.toString()
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#39;");
  }

  public static String money(Object x) {
    return NumberFormat.getCurrencyInstance(Locale.forLanguageTag("es-PE")).format(x);
  }
}
