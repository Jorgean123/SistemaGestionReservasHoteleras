package pe.edu.hotel;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class RulesTest {
  @Test
  void computesNights() {
    assertEquals(3, Rules.stay(Rules.today(), Rules.today().plusDays(3), 2, 2));
  }

  @Test
  void rejectsSameDay() {
    assertThrows(
        IllegalArgumentException.class, () -> Rules.stay(Rules.today(), Rules.today(), 1, 1));
  }

  @Test
  void rejectsPast() {
    assertThrows(
        IllegalArgumentException.class,
        () -> Rules.stay(Rules.today().minusDays(1), Rules.today().plusDays(1), 1, 1));
  }

  @Test
  void rejectsCapacity() {
    assertThrows(
        IllegalArgumentException.class,
        () -> Rules.stay(Rules.today(), Rules.today().plusDays(2), 3, 2));
  }

  @Test
  void rejectsTooLong() {
    assertThrows(
        IllegalArgumentException.class,
        () -> Rules.stay(Rules.today(), Rules.today().plusDays(366), 1, 2));
  }

  @Test
  void escapesHtml() {
    assertEquals("&lt;script&gt;&amp;&quot;&#39;", Web.esc("<script>&\"'"));
  }
}
