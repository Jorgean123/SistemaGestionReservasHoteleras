package pe.edu.hotel.beans;

import jakarta.annotation.PostConstruct;
import jakarta.faces.application.FacesMessage;
import jakarta.faces.context.FacesContext;
import jakarta.faces.view.ViewScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.io.Serializable;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import pe.edu.hotel.Rules;
import pe.edu.hotel.Web;
import pe.edu.hotel.dao.HotelRepository;
import pe.edu.hotel.model.HotelRow;

/** Estado aislado por vista: los formularios de pestañas distintas no se mezclan. */
@Named("hotelBean") @ViewScoped
public class HotelBean implements Serializable {
  @Inject private HotelRepository dao;
  private List<HotelRow> rooms=List.of(), guests=List.of(), bookings=List.of();
  private String query="",state="",nombre="",documento="",telefono="",email="",entrada="",salida="",observaciones="";
  private Long cliente,habitacion;
  private int personas=1,first=0;
  private long occupied,pending,guestCount;
  private BigDecimal confirmed=BigDecimal.ZERO;
  private boolean available;

  @PostConstruct public void init() { load(); }
  public void load() {
    try {
      rooms=dao.roomsDto(); guests=dao.guestsDto(""); bookings=dao.bookingsDto("","");
      guestCount=guests.size(); pending=bookings.stream().filter(HotelRow::isConfirmable).count();
      confirmed=bookings.stream().filter(b->"CONFIRMADA".equals(b.getEstado())).map(HotelRow::getTotal).reduce(BigDecimal.ZERO,BigDecimal::add);
      LocalDate today=Rules.today();
      occupied=bookings.stream().filter(b->"CONFIRMADA".equals(b.getEstado()) && !Web.parseDate(b.getEntrada()).isAfter(today) && Web.parseDate(b.getSalida()).isAfter(today)).map(HotelRow::getNumero).distinct().count();
      available=true;
    } catch(SQLException e) { available=false; failure(e); }
  }
  public void searchGuests() { try { guests=dao.guestsDto(query); first=0; } catch(SQLException e){failure(e);} }
  public void searchBookings() { try { bookings=dao.bookingsDto(query,state); first=0; } catch(SQLException e){failure(e);} }
  public String saveGuest() {
    try { dao.guest(nombre,documento,telefono,email); return success("Huésped registrado correctamente.","huespedes"); }
    catch(IllegalArgumentException e){error(e.getMessage());} catch(SQLException e){failure(e);} return null;
  }
  public String saveBooking() {
    try {
      if(cliente==null || habitacion==null) throw new IllegalArgumentException("Seleccione un huésped y una habitación.");
      long id=dao.reserve(cliente,habitacion,Web.parseDate(entrada),Web.parseDate(salida),personas,observaciones);
      return success("Reserva #"+id+" registrada en estado PENDIENTE.","reservas");
    } catch(IllegalArgumentException e){error(e.getMessage());} catch(SQLException e){failure(e);} return null;
  }
  public String changeState(long id,String next) {
    try { dao.state(id,next);return success("Estado de la reserva actualizado.","reservas"); }
    catch(IllegalArgumentException e){error(e.getMessage());} catch(SQLException e){failure(e);} return null;
  }
  private String success(String message,String outcome) {
    FacesContext ctx=FacesContext.getCurrentInstance();ctx.addMessage(null,new FacesMessage(message));
    ctx.getExternalContext().getFlash().setKeepMessages(true);return outcome+"?faces-redirect=true";
  }
  private void error(String text) { FacesContext.getCurrentInstance().addMessage(null,new FacesMessage(FacesMessage.SEVERITY_ERROR,text,null)); }
  private void failure(SQLException e) {
    FacesContext.getCurrentInstance().getExternalContext().log("Error JDBC en JSF",e);
    error(e.getErrorCode()==1062 ? "Ya existe un huésped con este documento." : "No fue posible acceder a los datos. Intente nuevamente o contacte al administrador.");
  }
  public void next(){first+=10;} public void previous(){first=Math.max(0,first-10);}
  public boolean isMoreGuests(){return first+10<guests.size();} public boolean isMoreBookings(){return first+10<bookings.size();}
  public int getFirst(){return first;} public int getPage(){return first/10+1;}
  public List<HotelRow> getRooms(){return rooms;} public List<HotelRow> getGuests(){return guests;} public List<HotelRow> getBookings(){return bookings;}
  public long getOccupied(){return occupied;} public long getPending(){return pending;} public long getGuestCount(){return guestCount;}
  public String getConfirmed(){return Web.money(confirmed);} public String getToday(){return Web.date(Rules.today());}
  public boolean isAvailable(){return available;}
  public String getQuery(){return query;} public void setQuery(String v){query=v==null?"":v;}
  public String getState(){return state;} public void setState(String v){state=v==null?"":v;}
  public String getNombre(){return nombre;} public void setNombre(String v){nombre=v;}
  public String getDocumento(){return documento;} public void setDocumento(String v){documento=v;}
  public String getTelefono(){return telefono;} public void setTelefono(String v){telefono=v;}
  public String getEmail(){return email;} public void setEmail(String v){email=v;}
  public Long getCliente(){return cliente;} public void setCliente(Long v){cliente=v;}
  public Long getHabitacion(){return habitacion;} public void setHabitacion(Long v){habitacion=v;}
  public String getEntrada(){return entrada;} public void setEntrada(String v){entrada=v;}
  public String getSalida(){return salida;} public void setSalida(String v){salida=v;}
  public int getPersonas(){return personas;} public void setPersonas(int v){personas=v;}
  public String getObservaciones(){return observaciones;} public void setObservaciones(String v){observaciones=v;}
}
