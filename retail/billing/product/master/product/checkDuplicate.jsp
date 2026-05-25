<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
<jsp:useBean id="prod" class="product.productBean" />
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");
try {
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        out.print("{\"nameDuplicate\":false,\"codeDuplicate\":false}");
        return;
    }

    String name       = request.getParameter("name");
    String code       = request.getParameter("code");
    int    excludeId  = 0;
    try { excludeId = Integer.parseInt(request.getParameter("excludeId")); } catch (Exception e) {}

    boolean nameDuplicate = false;
    boolean codeDuplicate = false;

    if (name != null && !name.trim().isEmpty()) {
        if (excludeId > 0) {
            // Edit mode: exclude the current product
            nameDuplicate = prod.checkTheProductNameExistId(name.trim(), excludeId) != 0;
        } else {
            nameDuplicate = prod.checkTheProductNameExist(name.trim()) != 0;
        }
    }

    if (code != null && !code.trim().isEmpty()) {
        int codeMatch = prod.checkTheProductCodeExist(code.trim());
        // In edit mode, allow same code to belong to the current product
        codeDuplicate = (codeMatch != 0 && codeMatch != excludeId);
    }

    out.print("{\"nameDuplicate\":" + nameDuplicate + ",\"codeDuplicate\":" + codeDuplicate + "}");
} catch (Exception e) {
    out.print("{\"nameDuplicate\":false,\"codeDuplicate\":false}");
}
%>
