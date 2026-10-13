package pe.edu.hotel.web;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.Set;

@WebFilter("/*")
public class RequestFilter implements Filter {
  private static final Set<String> LEGACY=Set.of("/panel","/habitaciones","/huespedes","/reservas","/nueva-reserva");
  public void doFilter(ServletRequest request,ServletResponse response,FilterChain chain) throws IOException,ServletException {
    HttpServletRequest req=(HttpServletRequest)request; HttpServletResponse res=(HttpServletResponse)response;
    req.setCharacterEncoding("UTF-8");res.setHeader("X-Content-Type-Options","nosniff");res.setHeader("X-Frame-Options","DENY");
    String path=req.getServletPath();
    if("GET".equals(req.getMethod()) && (LEGACY.contains(path)||"/index.jsp".equals(path))){res.sendRedirect(req.getContextPath()+("/index.jsp".equals(path)?"/panel":path)+".xhtml");return;}
    if(path.endsWith(".xhtml")) {
      res.setHeader("Cache-Control","no-store");
      // JSF server-side ViewState is session-bound; reject POSTs with no state as well.
      if("POST".equals(req.getMethod()) && (req.getSession(false)==null || req.getParameter("jakarta.faces.ViewState")==null)){res.sendError(403);return;}
    }
    chain.doFilter(request,response);
  }
}
