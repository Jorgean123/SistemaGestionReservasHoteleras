package pe.edu.hotel.dao;

import jakarta.enterprise.context.ApplicationScoped;
import java.sql.SQLException;
import java.util.List;
import pe.edu.hotel.HotelDao;
import pe.edu.hotel.model.HotelRow;

/** Adaptador DAO del APF1: mantiene sus transacciones y ofrece DTO a JSF. */
@ApplicationScoped
public class HotelRepository extends HotelDao {
  public List<HotelRow> roomsDto() throws SQLException { return rooms().stream().map(HotelRow::new).toList(); }
  public List<HotelRow> guestsDto(String q) throws SQLException { return guests(q).stream().map(HotelRow::new).toList(); }
  public List<HotelRow> bookingsDto(String q,String state) throws SQLException { return bookings(q,state).stream().map(HotelRow::new).toList(); }
}
