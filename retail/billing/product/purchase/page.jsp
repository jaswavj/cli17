<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, javax.servlet.http.*" %>
<jsp:useBean id="poBean" class="product.purchaseOrderBean" />
<jsp:useBean id="prodMasterBean" class="product.productBean" />
<%
    // Check if receiving goods from PO
    int poId = 0;
    String mode = "standalone";
    Vector poHeader = null;
    Vector poItems = null;
    Vector advancePayment = null;
    double advancePaid = 0;
    double advanceBalance = 0;
    
    String poIdParam = request.getParameter("poId");
    if (poIdParam != null && !poIdParam.isEmpty()) {
        try {
            poId = Integer.parseInt(poIdParam);
            mode = "from-po";
            
            // Load PO header and pending items
            poHeader = poBean.getPOHeader(poId);
            Vector result = poBean.getPOPendingItems(poId);
            
            if (result.size() > 1) {
                poItems = (Vector) result.get(1); // Items are at index 1
            } else {
                poId = 0;
                mode = "standalone";
            }
            
            // Load advance payment if exists
            if (poId > 0) {
                advancePayment = poBean.getPOAdvancePayment(poId);
                if (advancePayment.size() >= 3) {
                    advancePaid = (Double) advancePayment.get(1);
                    advanceBalance = (Double) advancePayment.get(2);
                }
            }
        } catch (Exception e) {
            poId = 0;
            mode = "standalone";
            out.println("<!-- Error loading PO: " + e.getMessage() + " -->");
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Purchase Item - Billing App</title>
    <%@ include file="/assets/common/head.jsp" %>
</head>
<style>
    /* Table wrapper for horizontal scroll */
    .table-wrapper {
        overflow-x: auto;
        overflow-y: auto;
        min-height: 280px;
        max-height: calc(100vh - 500px);
    }
    
    /* Fixed Table Layout */
    .table-fixed-layout {
        min-width: 1240px;
        table-layout: fixed;
        width: 100%;
    }

    /* Column Width Definitions */
    .table-fixed-layout th:nth-child(1), .table-fixed-layout td:nth-child(1) { width: 50px; }
    .table-fixed-layout th:nth-child(2), .table-fixed-layout td:nth-child(2) { width: 50px; }
    .table-fixed-layout th:nth-child(3), .table-fixed-layout td:nth-child(3) { width: 240px; }
    .table-fixed-layout th:nth-child(4), .table-fixed-layout td:nth-child(4) { width: 60px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .table-fixed-layout th:nth-child(5), .table-fixed-layout td:nth-child(5) { width: 100px; }
    .table-fixed-layout th:nth-child(6), .table-fixed-layout td:nth-child(6) { width: 60px; }
    .table-fixed-layout th:nth-child(7), .table-fixed-layout td:nth-child(7) { width: 80px; }
    .table-fixed-layout th:nth-child(8), .table-fixed-layout td:nth-child(8) { width: 80px; }
    .table-fixed-layout th:nth-child(9), .table-fixed-layout td:nth-child(9) { width: 60px; }
    .table-fixed-layout th:nth-child(10), .table-fixed-layout td:nth-child(10) { width: 60px; }
    .table-fixed-layout th:nth-child(11), .table-fixed-layout td:nth-child(11) { width: 90px; }
    .table-fixed-layout th:nth-child(12), .table-fixed-layout td:nth-child(12) { width: 90px; }
    .table-fixed-layout th:nth-child(13), .table-fixed-layout td:nth-child(13) { width: 90px; }
    .table-fixed-layout th:nth-child(14), .table-fixed-layout td:nth-child(14) { width: 100px; }
    .table-fixed-layout th:nth-child(15), .table-fixed-layout td:nth-child(15) { width: 90px; }
</style>
<body style="height: 100vh; overflow: hidden;" onload="Load();loadPOItems()">

    <div class="container-fluid h-100 d-flex flex-column">
        <!-- Navbar -->
        <%@ include file="/assets/navbar/navbar.jsp" %>
        
        <input type="hidden" id="_proAddRowCount" name="_proAddRowCount" value="0">
        <input type="hidden" id="_proDelRowCount" name="_proDelRowCount" value="0">
        <input type="hidden" id="poId" name="poId" value="<%= poId %>">
        <input type="hidden" id="mode" name="mode" value="<%= mode %>">
        <input type="hidden" id="advancePaid" name="advancePaid" value="<%= advancePaid %>">
        <% if (mode.equals("from-po") && poHeader != null) { %>
        <input type="hidden" id="supplierIdFromPO" value="<%= poHeader.get(10) %>">
        <% } %>

        <!-- Supplier Details (Top) -->
        <div class="card flex-shrink-0 my-1">
            <div class="card-body py-2">
                <% if (mode.equals("from-po")) { %>
                <div class="alert alert-info mb-2 py-1">
                    <i class="fas fa-truck me-2"></i>
                    <strong>Receiving Goods from PO:</strong> <%= poHeader != null ? poHeader.get(0).toString() : "" %>
                </div>
                <% } %>
                <div class="row g-1">
                    <div class="col-md-3">
                        <div class="input-outline">
                            <select class="form-select" name="supplier" id="supplier" onchange="setPaymentTypeBasedOnGst();">
                                <option value="0">Select Supplier</option>
                                <!-- Populated by JS -->
                            </select>
                            
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="input-outline">
                            <input type="text" class="form-control" id="invoiceNo" name="invoiceNo">
                            <label>Invoice No.</label>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="input-outline">
                            <input type="date" class="form-control" id="invoiceDate" name="invoiceDate" value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>">
                            <label>Invoice Date</label>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Product Table (Middle - Flexible) -->
        <div class="m-0 flex-grow-1 table-wrapper">
            <table class="table table-bordered table-sm mb-0 table-fixed-layout">
                <thead>
                    <tr>
                        <th>Add</th>
                        <th>Del</th>
                        <th>Item Name <button type="button" class="btn btn-success py-0 px-1 ms-1" style="font-size:0.68rem;line-height:1.4;" onclick="openAddProductModal()" title="Add New Product"><i class="fas fa-plus"></i></button></th>
                        <th>Qty</th>
                        <th>Cost</th>
                        <th>MRP</th>
                        <th>Disc%</th>
                        <th>Tax%</th>
                        <th>Free</th>
                        <th>History</th>
                        <th>Cost Tot</th>
                        <th>MRP Tot</th>
                        <th>Tax Tot</th>
                        <th>Net Tot</th>
                        <th>Unit Cost</th>
                    </tr>
                </thead>
                <tbody id="productTable">
                    <!-- Rows added by JS -->
                </tbody>
                <tfoot style="background-color: #f8f9fa;">
                    <tr>
                        <td colspan="10" class="text-end fw-bold pe-2">Summary Total:</td>
                        <td id="sumCostTotal" class="fw-bold">0.00</td>
                        <td id="sumMrpTotal" class="fw-bold">0.00</td>
                        <td id="sumTaxTotal" class="fw-bold">0.00</td>
                        <td id="sumNetTotal" class="fw-bold">0.00</td>
                        <td></td>
                    </tr>
                </tfoot>
            </table>
        </div>

        <!-- Payment Details (Bottom) -->
        <div class="card flex-shrink-0 my-1">
            <div class="card-body py-2">
                <% if (mode.equals("from-po") && advancePaid > 0) { %>
                <div class="alert alert-success mb-2 py-1">
                    <i class="fas fa-info-circle me-2"></i>
                    <strong>Advance Paid:</strong> ₹<%= String.format("%.3f", advancePaid) %> | 
                    <strong>Remaining:</strong> ₹<%= String.format("%.3f", advanceBalance) %>
                </div>
                <% } %>
                <div class="row g-1">
                    <div class="col-md-2">
                        <div class="input-outline">
                            <select class="form-select" id="payType" name="payType">
                                <option value="0">Select Payment Type</option>
                                <!-- Populated by JS -->
                            </select>
                            
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="input-outline">
                            <select class="form-select" id="bank" name="bank">
                                <option value="0">Select Mode</option>
                            </select>
                           
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="input-outline">
                            <input type="number" class="form-control bg-light" id="grandTotal" name="grandTotal" step="0.001" readonly value="0.00">
                            <label>Total Amount</label>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="input-outline">
                            <input type="number" class="form-control" id="paidAmount" name="paidAmount" step="0.001" value="0.00">
                            <label>Paid Now</label>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="input-outline">
                            <input type="number" class="form-control" id="extraDisc" name="extraDisc" step="0.001" value="0.00">
                            <label>Extra Discount</label>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="input-outline">
                            <input type="number" class="form-control bg-light" id="balanceAmount" name="balanceAmount" step="0.001" readonly value="0.00">
                            <label>Balance</label>
                        </div>
                    </div>
                </div>
                <div class="row g-1 mt-1">
                    <div class="col-md-2">
                        <button type="button" class="btn btn-outline-violet w-100 h-100" id="saveBtn" onclick="savePurchaseBill()">
                            <i class="fas fa-save me-2"></i>Save
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Purchase History Modal -->
    <div class="modal fade" id="purchaseHistoryModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Last 6 Purchase History</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div id="historyContent">
                        <div class="text-center">
                            <div class="spinner-border" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        var contextPath = '<%=contextPath%>';
    </script>
    <script src="<%=contextPath%>/product/purchase/purchase.js?v=<%= System.currentTimeMillis() %>"></script>
    <script>
        // Set payment type based on supplier GST status
        function setPaymentTypeBasedOnGst() {
            var supplier = $('#supplier').val();
            
            if (!supplier || supplier == '0') {
                return;
            }
            
            // Fetch supplier GST status
            $.ajax({
                type: 'POST',
                url: 'details.jsp',
                data: { 
                    status: 7,
                    supplierId: supplier 
                },
                success: function(result) {
                    var isGst = parseInt(result.trim());
                    
                    if (isGst === 1) {
                        // GST registered - auto-select Bank (assuming Bank is id=2)
                        $('#payType').val('2');
                    } else {
                        // Not GST registered - auto-select Cash (id=1)
                        $('#payType').val('1');
                    }
                    
                    // Trigger change event to enable/disable bank dropdown
                    $('#payType').trigger('change');
                }
            });
        }
        
        // Fix for table header gradient issue if present
        document.addEventListener("DOMContentLoaded", function() {
            setTimeout(function() {
                document.querySelectorAll("table thead th").forEach(th => {
                    th.style.removeProperty("background-color");
                    th.style.removeProperty("color");
                    th.style.removeProperty("background");
                });
            }, 100);
        });
        
        // Function to load PO items into table
        function loadPOItems() {
            var mode = $('#mode').val();
            
            if (mode === 'from-po') {
                // Load items from PO
                <% if (poItems != null && poItems.size() > 0) { %>
                var poItems = [];
                <% for (int i = 0; i < poItems.size(); i++) { 
                    Vector item = (Vector) poItems.get(i);
                %>
                poItems.push({
                    name: '<%= item.get(0).toString().replace("'", "\\'") %>',
                    pack: <%= item.get(12) %>,
                    qtyperpack: <%= item.get(13) %>,
                    free: <%= item.get(14) %>,
                    cost: <%= item.get(3) %>,
                    mrp: <%= item.get(7) %>,
                    disc: <%= item.get(15) %>,
                    tax: <%= item.get(11) %>,
                    productId: <%= item.get(9) %>,
                    poDetailId: <%= item.get(8) %>,
                    pendingQty: <%= item.get(6) %>
                });
                <% } %>
                
                // Populate rows
                for (var i = 0; i < poItems.length; i++) {
                    addProductRowFromPO(i, poItems[i]);
                }
                
                // Focus on invoice field instead
                $('#invoiceNo').focus();
                <% } %>
            } else {
                // Standalone mode - add one empty row
                addProductRow(event, 0);
            }
        }
        
        // Function to add a pre-filled row from PO data
        function addProductRowFromPO(rowIndex, itemData) {
            var proRowCount = rowIndex;
            
            // Escape double quotes in product name to prevent attribute breaking
            var escapedName = itemData.name.replace(/"/g, '&quot;');
            
            $("#productTable").append("<tr id='_productTableRow_" + proRowCount + "'>"
                + "<td class='text-center'><button type='button' class='btn btn-sm btn-success' id='_addProcRow_" + proRowCount + "' onclick='addProductRow();' disabled><i class='fas fa-plus'></i></button></td>"
                + "<td class='text-center'><button type='button' class='btn btn-sm btn-danger' id='_delProcRow_" + proRowCount + "' onclick='deleteProductRow(this);'><i class='fas fa-trash'></i></button></td>"
                + '<td><input type="text" class="form-control form-control-sm" id="_productName_' + proRowCount + '" name="_productName_' + proRowCount + '" value="' + escapedName + '" readonly></td>'
                + "<td><div class='d-flex flex-column'><div class='d-flex align-items-center gap-1'><input type='text' class='form-control form-control-sm' id='_totqty_" + proRowCount + "' name='_totqty_" + proRowCount + "' value='" + (((parseFloat(itemData.pack) || 0) * (parseFloat(itemData.qtyperpack) || 0)).toFixed(3)) + "' style='min-width:65px;' onkeyup='calculateRow(" + proRowCount + ");'><span class='text-muted small' id='_totunit_" + proRowCount + "'></span></div><small class='text-primary' id='_convtotqty_" + proRowCount + "'></small><input type='hidden' id='_pack_" + proRowCount + "' name='_pack_" + proRowCount + "' value='1'><input type='hidden' id='_qtyperpack_" + proRowCount + "' name='_qtyperpack_" + proRowCount + "' value='" + (((parseFloat(itemData.pack) || 0) * (parseFloat(itemData.qtyperpack) || 0)).toFixed(3)) + "'></div></td>"
                + "<td><div class='d-flex flex-column'><input type='text' class='form-control form-control-sm' id='_cost_" + proRowCount + "' name='_cost_" + proRowCount + "' value='" + itemData.cost + "' onkeyup='calculateRow(" + proRowCount + ");'><small class='text-info' id='_costperconv_" + proRowCount + "'></small></div></td>"
                + "<td><div class='d-flex flex-column'><input type='text' class='form-control form-control-sm' id='_mrp_" + proRowCount + "' name='_mrp_" + proRowCount + "' value='" + itemData.mrp + "' onkeyup='calculateRow(" + proRowCount + ");'><small class='text-info' id='_mrpperconv_" + proRowCount + "'></small></div></td>"
                + "<td><input type='text' class='form-control form-control-sm' id='_disc_" + proRowCount + "' name='_disc_" + proRowCount + "' value='" + itemData.disc + "' onkeyup='calculateRow(" + proRowCount + ");'></td>"
                + "<td><input type='text' class='form-control form-control-sm' id='_tax_" + proRowCount + "' name='_tax_" + proRowCount + "' value='" + itemData.tax + "' onkeyup='calculateRow(" + proRowCount + ");'></td>"
                + "<td><input type='text' class='form-control form-control-sm' id='_freeqty_" + proRowCount + "' name='_freeqty_" + proRowCount + "' value='" + itemData.free + "' onkeyup='calculateRow(" + proRowCount + ");'></td>"
                + "<td class='text-center'><button type='button' class='btn btn-sm btn-info' id='_historyBtn_" + proRowCount + "' onclick='viewPurchaseHistory(" + proRowCount + ");'><i class='fas fa-history'></i></button></td>"
                + "<td><label id='_costtotal_" + proRowCount + "'>0.00</label></td>"
                + "<td><label id='_mrptotal_" + proRowCount + "'>0.00</label></td>"
                + "<td><label id='_taxtotal_" + proRowCount + "'>0.00</label></td>"
                + "<td><label id='_nettotal_" + proRowCount + "'>0.00</label></td>"
                + "<td><label id='_unitcost_" + proRowCount + "'>0.00</label></td>"
                + "<input type='hidden' id='_productId_" + proRowCount + "' value='" + itemData.productId + "'>"
                + "<input type='hidden' id='_poDetailId_" + proRowCount + "' value='" + itemData.poDetailId + "'>"
                + "<input type='hidden' id='_pendingQty_" + proRowCount + "' value='" + itemData.pendingQty + "'>"
                + "</tr>");
            
            $('#_proAddRowCount').val(proRowCount);
            $('#_proDelRowCount').val(proRowCount + 1);
            
            // Calculate row totals
            calculateRow(proRowCount);
            // Fetch conversion data for this PO item
            fetchConversionData(proRowCount, itemData.name);
        }

        // Fetch conversion unit data for a pre-filled product row (PO items)
        function fetchConversionData(rowIndex, productName) {
            $.ajax({
                type: "POST",
                url: contextPath + "/product/purchase/details.jsp",
                data: { status: 1, productName: productName },
                success: function (_result) {
                    var resArr = _result.trim().split("<#>");
                    if (resArr.length > 1) {
                        var unitName = (resArr.length > 10) ? resArr[10] : '';
                        var convertionUnit = (resArr.length > 11) ? resArr[11].trim() : '';
                        var convertionCalc = (resArr.length > 12) ? parseFloat(resArr[12]) || 1 : 1;
                        $('#_productName_' + rowIndex).data('unitName', unitName);
                        $('#_productName_' + rowIndex).data('convertionUnit', convertionUnit);
                        $('#_productName_' + rowIndex).data('convertionCalc', convertionCalc);
                        if (unitName) {
                            $('#_totunit_' + rowIndex).text(unitName);
                        }
                        calculateRow(rowIndex);
                    }
                }
            });
        }
    </script>

<!-- Add Product Modal -->
<div class="modal fade" id="addProductModal" tabindex="-1" aria-labelledby="addProductModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header py-2" style="background:var(--page-header-card-bg);color:white;">
                <h6 class="modal-title mb-0" id="addProductModalLabel"><i class="fas fa-plus-circle me-2"></i>Add New Product</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body py-2">
                <form id="addProductModalForm" class="row g-2">
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">Category <span class="text-danger">*</span></label>
                        <select name="categoryId" id="modal_categoryId" class="form-select form-select-sm" required>
                            <option value="">Select Category</option>
                            <%
                                Vector modalCategories = prodMasterBean.getCategoryName();
                                if (modalCategories != null) {
                                    for (int mi = 0; mi < modalCategories.size(); mi++) {
                                        Vector mcat = (Vector) modalCategories.get(mi);
                                        if (mcat != null && mcat.size() >= 2) {
                            %>
                            <option value="<%=mcat.elementAt(1)%>"><%=mcat.elementAt(0)%></option>
                            <% }}} %>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">Brand <span class="text-danger">*</span></label>
                        <select name="brandId" id="modal_brandId" class="form-select form-select-sm" required>
                            <option value="">Select Brand</option>
                            <%
                                Vector modalBrands = prodMasterBean.getBrandsName();
                                if (modalBrands != null) {
                                    for (int mi = 0; mi < modalBrands.size(); mi++) {
                                        Vector mbrand = (Vector) modalBrands.get(mi);
                                        if (mbrand != null && mbrand.size() >= 2) {
                            %>
                            <option value="<%=mbrand.elementAt(1)%>"><%=mbrand.elementAt(0)%></option>
                            <% }}} %>
                        </select>
                    </div>
                    <div class="col-md-12">
                        <label class="form-label mb-1" style="font-size:0.85rem;">Product Name <span class="text-danger">*</span></label>
                        <input type="text" id="modal_productName" name="productName" class="form-control form-control-sm" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">Product Code</label>
                        <input type="text" id="modal_productCode" name="productCode" class="form-control form-control-sm">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">HSN Code</label>
                        <input type="text" id="modal_hsn" name="hsn" class="form-control form-control-sm">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">Unit/Size</label>
                        <select name="unitId" id="modal_unitId" class="form-select form-select-sm" required>
                            <option value="">Select Unit</option>
                            <%
                                Vector modalUnits = prodMasterBean.getUnits();
                                if (modalUnits != null) {
                                    for (int mi = 0; mi < modalUnits.size(); mi++) {
                                        Vector munit = (Vector) modalUnits.get(mi);
                                        if (munit != null && munit.size() >= 2) {
                                            String mUnitName = munit.elementAt(0).toString();
                                            String mUnitId   = munit.elementAt(1).toString();
                                            boolean mSelected = mUnitName.equalsIgnoreCase("Nos") || mUnitName.equalsIgnoreCase("NOS") || mUnitName.equalsIgnoreCase("PCS");
                            %>
                            <option value="<%=mUnitId%>" <%=mSelected?"selected":""%>><%=mUnitName%></option>
                            <% }}} %>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">Stock</label>
                        <input type="number" id="modal_stock" name="stock" class="form-control form-control-sm" value="0" min="0" step="0.01">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">Cost Price <span class="text-danger">*</span></label>
                        <input type="number" id="modal_cost" name="cost" class="form-control form-control-sm" step="0.001" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">MRP <span class="text-danger">*</span></label>
                        <input type="number" id="modal_mrp" name="mrp" class="form-control form-control-sm" step="0.001" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">GST %</label>
                        <select id="modal_gst" name="gst" class="form-select form-select-sm" required>
                            <option value="0" selected>0%</option>
                            <option value="5">5%</option>
                            <option value="12">12%</option>
                            <option value="18">18%</option>
                            <option value="28">28%</option>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">Discount Type</label>
                        <select id="modal_discType" name="discType" class="form-select form-select-sm" onchange="handleModalDiscTypeChange(this)">
                            <option value="0">None</option>
                            <option value="1">Rs</option>
                            <option value="2">%</option>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">Discount Value</label>
                        <input type="text" id="modal_discValue" name="discValue" class="form-control form-control-sm" value="0.00" readonly>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label mb-1" style="font-size:0.85rem;">Commission (Rs)</label>
                        <input type="number" id="modal_commission" name="commission" class="form-control form-control-sm" step="0.01" value="0.00">
                    </div>
                </form>
            </div>
            <div class="modal-footer py-2">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-primary btn-sm" id="saveNewProductBtn" onclick="saveNewProductModal()">
                    <i class="fas fa-save me-1"></i>Save Product
                </button>
            </div>
        </div>
    </div>
</div>

</body>
</html>
