package pe.edu.hotel.model;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Map;
import pe.edu.hotel.Web;

/** DTO de lectura: no expone JDBC a las vistas Facelets. */
public class HotelRow implements Serializable {
  private final Map<String,Object> values;
  public HotelRow(Map<String,Object> values) { this.values = new java.util.LinkedHashMap<>(values); }
  private String text(String key) { Object v=values.get(key); return v==null ? "" : v.toString(); }
  public long getId() { return ((Number) values.get("id")).longValue(); }
  public String getNombre() { return text("nombre"); }
  public String getDocumento() { return text("documento"); }
  public String getTelefono() { return text("telefono"); }
  public String getEmail() { return text("email"); }
  public String getNumero() { return text("numero"); }
  public String getTipo() { return text("tipo"); }
  public String getDescripcion() { return text("descripcion"); }
  public String getCapacidad() { return text("capacidad"); }
  public String getEstado() { return text("estado"); }
  public String getEntrada() { return Web.date(values.get("fecha_entrada")); }
  public String getSalida() { return Web.date(values.get("fecha_salida")); }
  public String getTarifa() { return Web.money(values.get("precio_noche")); }
  public BigDecimal getTotal() { return (BigDecimal)values.get("total"); }
  public String getImporte() { return Web.money(getTotal()); }
  public boolean isConfirmable() { return "PENDIENTE".equals(getEstado()); }
  public boolean isCancelable() { return isConfirmable() || "CONFIRMADA".equals(getEstado()); }
  public boolean isHabilitada() { Object v=values.get("habilitada"); return Boolean.TRUE.equals(v) || "1".equals(String.valueOf(v)); }
}
