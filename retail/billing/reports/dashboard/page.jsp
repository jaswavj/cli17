<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import= "java.util.*"%>
<jsp:useBean id="op1" class="billing.billingBean" />
<jsp:useBean id="prod" class="product.productBean" />
<%
///////////////////  Year / Month Selection  /////////////////
java.util.Calendar now = java.util.Calendar.getInstance();
int currentYear  = now.get(java.util.Calendar.YEAR);
int currentMonth = now.get(java.util.Calendar.MONTH) + 1;

String yearParam  = request.getParameter("year");
String monthParam = request.getParameter("month");

int selYear  = (yearParam  != null && !yearParam.isEmpty())  ? Integer.parseInt(yearParam)  : currentYear;
int selMonth = (monthParam != null && !monthParam.isEmpty()) ? Integer.parseInt(monthParam) : currentMonth;

java.util.Calendar selCal = java.util.Calendar.getInstance();
selCal.set(selYear, selMonth - 1, 1);
String selectedMonthStart = new java.text.SimpleDateFormat("yyyy-MM-dd").format(selCal.getTime());
selCal.set(java.util.Calendar.DAY_OF_MONTH, selCal.getActualMaximum(java.util.Calendar.DAY_OF_MONTH));
String selectedMonthEnd = new java.text.SimpleDateFormat("yyyy-MM-dd").format(selCal.getTime());

String[] monthNames = {"", "January", "February", "March", "April", "May", "June",
                       "July", "August", "September", "October", "November", "December"};
String selectedMonthLabel = monthNames[selMonth] + " " + selYear;

///////////////////  Sales  /////////////////
double thisSale = op1.getTotalSalesByDateRange(selectedMonthStart, selectedMonthEnd);

///////////////////  Purchase  /////////////////
double thisPurchase = op1.getTotalPurchasesByDateRange(selectedMonthStart, selectedMonthEnd);

///////////////////  Today's Sales  /////////////////
double todaySales     = op1.getTodaySales();
int    todayBillCount = op1.getTodayBillCount();

///////////////////  Gross Profit = Sale - Purchase  /////////////////
double grossProfit = thisSale - thisPurchase;

///////////////////  Expenses  /////////////////
double thisExpense = 0.0;
try {
    Vector thisMonthExpenses = prod.getExpenseReport(selectedMonthStart, selectedMonthEnd, 0);
    if (thisMonthExpenses != null) {
        for (int i = 0; i < thisMonthExpenses.size(); i++) {
            Vector row = (Vector) thisMonthExpenses.get(i);
            if (row.size() > 4) {
                thisExpense += Double.parseDouble(row.get(4).toString());
            }
        }
    }
} catch (Exception e) {
    System.err.println("Error loading expenses: " + e.getMessage());
}

///////////////////  Net Profit  /////////////////
double netProfitWithExpenses = grossProfit - thisExpense;

///////////////////  Today Date  /////////////////
java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd-MMM-yyyy");
String todayDate = sdf.format(new java.util.Date());

/////////////////////  Charts  //////////////////
Vector vec         = op1.getSalesChartByDateRange(selectedMonthStart, selectedMonthEnd);
Vector vecPurchase = op1.getPurchaseChartByDateRange(selectedMonthStart, selectedMonthEnd);

StringBuilder labels       = new StringBuilder();
StringBuilder salesData    = new StringBuilder();
StringBuilder purchaseData = new StringBuilder();

for (int i = 0; i < vec.size(); i++) {
    Vector row  = (Vector) vec.elementAt(i);
    String date  = row.elementAt(0).toString();
    String total = row.elementAt(1).toString();
    labels.append("\"").append(date).append("\"");
    salesData.append(total.isEmpty() || total.equals("0") ? "0" : total);
    if (i < vec.size() - 1) { labels.append(", "); salesData.append(", "); }
}

for (int i = 0; i < vecPurchase.size(); i++) {
    Vector row   = (Vector) vecPurchase.elementAt(i);
    String total = row.elementAt(1).toString();
    purchaseData.append(total.isEmpty() || total.equals("0") ? "0" : total);
    if (i < vecPurchase.size() - 1) purchaseData.append(", ");
}

/////////////////////  Top Customers and Suppliers  //////////////////
Vector<Vector> topCustomers         = op1.getTopCustomersByDateRange(selectedMonthStart, selectedMonthEnd);
Vector<Vector> topSuppliers         = op1.getTopSuppliersByDateRange(selectedMonthStart, selectedMonthEnd);
Vector<Vector> outstandingCustomers = op1.getOutstandingCustomers();
Vector<Vector> outstandingSuppliers = op1.getOutstandingSuppliers();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Executive Dashboard</title>
    <%@ include file="/assets/common/head.jsp" %>
    <style>
        body { background-color: #f8f9fa; }
        .dashboard-card {
            border: none;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
            transition: transform 0.2s;
            overflow: hidden;
            background: white;
        }
        .dashboard-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 15px rgba(0,0,0,0.1);
        }
        .card-icon {
            position: absolute;
            right: 20px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 3rem;
            opacity: 0.15;
        }
        .chart-container {
            background: white;
            border-radius: 12px;
            padding: 15px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        }
        .chart-wrapper    { position: relative; height: 250px; width: 100%; }
        .chart-wrapper-sm { position: relative; height: 180px; width: 100%; }
        .month-picker-bar {
            background: white;
            border-radius: 12px;
            padding: 12px 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
            margin-bottom: 20px;
        }
        .month-label-badge {
            font-size: 0.75rem;
            background: #e9ecef;
            color: #495057;
            border-radius: 20px;
            padding: 4px 12px;
        }
    </style>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>

    <div class="container-fluid py-4 px-4">

        <!-- Month / Year Picker -->
        <div class="month-picker-bar d-flex align-items-center flex-wrap gap-3">
            <span class="fw-bold text-muted" style="font-size:0.85rem;"><i class="fas fa-calendar-alt me-1"></i> Dashboard Period:</span>
            <form method="get" id="periodForm" class="d-flex align-items-center gap-2">
                <select name="month" class="form-select form-select-sm" style="width:auto;" onchange="document.getElementById('periodForm').submit()">
                    <% for (int m = 1; m <= 12; m++) { %>
                        <option value="<%= m %>" <%= (m == selMonth) ? "selected" : "" %>><%= monthNames[m] %></option>
                    <% } %>
                </select>
                <select name="year" class="form-select form-select-sm" style="width:auto;" onchange="document.getElementById('periodForm').submit()">
                    <% for (int y = 2020; y <= currentYear; y++) { %>
                        <option value="<%= y %>" <%= (y == selYear) ? "selected" : "" %>><%= y %></option>
                    <% } %>
                </select>
            </form>
            <span class="month-label-badge"><%= selectedMonthLabel %></span>
        </div>

        <!-- Summary Cards -->
        <div class="row g-4 mb-4">

            <!-- Today Sales -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 border-danger">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-1" style="font-size: 0.7rem;">Today's Sales</h6>
                        <p class="text-muted mb-2" style="font-size: 0.65rem; margin-top: -2px;">(<%= todayDate %>)</p>
                        <h4 class="fw-bold text-dark mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", todaySales) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="text-muted" style="font-size: 0.7rem;"><i class="fas fa-receipt me-1"></i> <%= todayBillCount %> Bills</span>
                        </div>
                        <i class="fas fa-calendar-day card-icon text-danger" style="font-size: 2.5rem;"></i>
                    </div>
                </div>
            </div>

            <!-- Total Sales -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 border-primary">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Total Sales</h6>
                        <h4 class="fw-bold text-dark mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", thisSale) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="text-muted" style="font-size: 0.65rem;"><%= selectedMonthLabel %></span>
                        </div>
                        <i class="fas fa-chart-line card-icon text-primary" style="font-size: 2.5rem;"></i>
                    </div>
                </div>
            </div>

            <!-- Total Purchase -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 border-success">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Total Purchase</h6>
                        <h4 class="fw-bold text-dark mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", thisPurchase) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="text-muted" style="font-size: 0.65rem;"><%= selectedMonthLabel %></span>
                        </div>
                        <i class="fas fa-shopping-cart card-icon text-success" style="font-size: 2.5rem;"></i>
                    </div>
                </div>
            </div>

            <!-- Gross Profit -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 border-info">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Gross Profit</h6>
                        <h4 class="fw-bold <%= grossProfit >= 0 ? "text-success" : "text-danger" %> mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", grossProfit) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="text-muted" style="font-size: 0.65rem;">Sales &minus; Purchase</span>
                        </div>
                        <i class="fas fa-chart-pie card-icon text-info" style="font-size: 2.5rem;"></i>
                    </div>
                </div>
            </div>

            <!-- Expenses -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4" style="border-color: #5b21b6 !important;">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Expenses</h6>
                        <h4 class="fw-bold text-dark mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", thisExpense) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="text-muted" style="font-size: 0.65rem;"><%= selectedMonthLabel %></span>
                        </div>
                        <i class="fas fa-receipt card-icon" style="font-size: 2.5rem; color: #5b21b6;"></i>
                    </div>
                </div>
            </div>

            <!-- Net Profit -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 <%= netProfitWithExpenses >= 0 ? "border-success" : "border-danger" %>">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Net Profit</h6>
                        <h4 class="fw-bold mb-2 <%= netProfitWithExpenses >= 0 ? "text-success" : "text-danger" %>" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", netProfitWithExpenses) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="text-muted" style="font-size: 0.65rem;">After Expenses</span>
                        </div>
                        <i class="fas fa-coins card-icon <%= netProfitWithExpenses >= 0 ? "text-success" : "text-danger" %>" style="font-size: 2.5rem;"></i>
                    </div>
                </div>
            </div>

        </div>

        <!-- Charts Section -->
        <div class="row g-4">
            <div class="col-lg-8">
                <div class="chart-container">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <h5 class="fw-bold mb-0">Financial Overview <small class="text-muted">(<%= selectedMonthLabel %>)</small></h5>
                    </div>
                    <div class="chart-wrapper">
                        <canvas id="combinedChart"></canvas>
                    </div>
                </div>
            </div>
            <div class="col-lg-4">
                <div class="chart-container">
                    <h5 class="fw-bold mb-3">Sales vs Purchase <small class="text-muted">(<%= selectedMonthLabel %>)</small></h5>
                    <div class="chart-wrapper">
                        <canvas id="comparisonChart"></canvas>
                    </div>
                </div>
            </div>
        </div>

        <!-- Detailed Graphs -->
        <div class="row g-4 mt-1">
            <div class="col-md-6">
                <div class="chart-container">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h5 class="fw-bold mb-0">Sales Trend</h5>
                        <button id="downloadMargin" class="btn btn-sm btn-outline-primary"><i class="fas fa-download me-1"></i> Save</button>
                    </div>
                    <div class="chart-wrapper-sm">
                        <canvas id="marginChart"></canvas>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="chart-container">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h5 class="fw-bold mb-0">Purchase Trend</h5>
                        <button id="downloadPurchase" class="btn btn-sm btn-outline-success"><i class="fas fa-download me-1"></i> Save</button>
                    </div>
                    <div class="chart-wrapper-sm">
                        <canvas id="purchaseChart"></canvas>
                    </div>
                </div>
            </div>
        </div>

        <!-- Top Customers & Suppliers -->
        <div class="row g-4 mt-1">
            <div class="col-lg-6">
                <div class="chart-container">
                    <h5 class="fw-bold mb-3"><i class="fas fa-users text-primary me-2"></i>Top Customers (<%= selectedMonthLabel %>)</h5>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th style="width:5%;">#</th>
                                    <th>Customer Name</th>
                                    <th class="text-end">Total Sales</th>
                                    <th class="text-center">Bills</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (topCustomers.size() == 0) { %>
                                    <tr><td colspan="4" class="text-center text-muted">No data available</td></tr>
                                <% } else {
                                    for (int i = 0; i < topCustomers.size(); i++) {
                                        Vector row = topCustomers.get(i);
                                        String name = (String) row.get(0);
                                        double sales = (Double) row.get(1);
                                        int billCnt = (Integer) row.get(2);
                                %>
                                <tr>
                                    <td><%= i+1 %></td>
                                    <td><strong><%= name %></strong></td>
                                    <td class="text-end text-primary fw-bold">&#8377; <%= String.format("%,.2f", sales) %></td>
                                    <td class="text-center"><span class="badge bg-info"><%= billCnt %></span></td>
                                </tr>
                                <% } } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <div class="col-lg-6">
                <div class="chart-container">
                    <h5 class="fw-bold mb-3"><i class="fas fa-truck text-success me-2"></i>Top Suppliers (<%= selectedMonthLabel %>)</h5>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th style="width:5%;">#</th>
                                    <th>Supplier Name</th>
                                    <th class="text-end">Total Purchase</th>
                                    <th class="text-center">Orders</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (topSuppliers.size() == 0) { %>
                                    <tr><td colspan="4" class="text-center text-muted">No data available</td></tr>
                                <% } else {
                                    for (int i = 0; i < topSuppliers.size(); i++) {
                                        Vector row = topSuppliers.get(i);
                                        String name = (String) row.get(0);
                                        double purchase = (Double) row.get(1);
                                        int orderCnt = (Integer) row.get(2);
                                %>
                                <tr>
                                    <td><%= i+1 %></td>
                                    <td><strong><%= name %></strong></td>
                                    <td class="text-end text-success fw-bold">&#8377; <%= String.format("%,.2f", purchase) %></td>
                                    <td class="text-center"><span class="badge bg-info"><%= orderCnt %></span></td>
                                </tr>
                                <% } } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <!-- Outstanding Balances -->
        <div class="row g-4 mt-1">
            <div class="col-lg-6">
                <div class="chart-container">
                    <h5 class="fw-bold mb-3"><i class="fas fa-money-bill-wave text-warning me-2"></i>Top Outstanding Customers</h5>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th style="width:5%;">#</th>
                                    <th>Customer Name</th>
                                    <th class="text-end">Outstanding Amount</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (outstandingCustomers.size() == 0) { %>
                                    <tr><td colspan="3" class="text-center text-muted">No outstanding balances</td></tr>
                                <% } else {
                                    for (int i = 0; i < outstandingCustomers.size(); i++) {
                                        Vector row = outstandingCustomers.get(i);
                                        String name = (String) row.get(0);
                                        double pending = (Double) row.get(2);
                                %>
                                <tr>
                                    <td><%= i+1 %></td>
                                    <td><strong><%= name %></strong></td>
                                    <td class="text-end text-warning fw-bold">&#8377; <%= String.format("%,.2f", pending) %></td>
                                </tr>
                                <% } } %>
                            </tbody>
                            <% if (outstandingCustomers.size() > 0) {
                                double totalOC = 0;
                                for (Vector row : outstandingCustomers) totalOC += (Double) row.get(1);
                            %>
                            <tfoot class="table-light">
                                <tr>
                                    <th colspan="2" class="text-end">Total (Top 5):</th>
                                    <th class="text-end text-danger">&#8377; <%= String.format("%,.2f", totalOC) %></th>
                                </tr>
                            </tfoot>
                            <% } %>
                        </table>
                    </div>
                </div>
            </div>
            <div class="col-lg-6">
                <div class="chart-container">
                    <h5 class="fw-bold mb-3"><i class="fas fa-file-invoice-dollar text-danger me-2"></i>Top Outstanding Suppliers</h5>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th style="width:5%;">#</th>
                                    <th>Supplier Name</th>
                                    <th class="text-end">Outstanding Amount</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (outstandingSuppliers.size() == 0) { %>
                                    <tr><td colspan="3" class="text-center text-muted">No outstanding balances</td></tr>
                                <% } else {
                                    for (int i = 0; i < outstandingSuppliers.size(); i++) {
                                        Vector row = outstandingSuppliers.get(i);
                                        String name = (String) row.get(0);
                                        double outstanding = (Double) row.get(1);
                                %>
                                <tr>
                                    <td><%= i+1 %></td>
                                    <td><strong><%= name %></strong></td>
                                    <td class="text-end text-danger fw-bold">&#8377; <%= String.format("%,.2f", outstanding) %></td>
                                </tr>
                                <% } } %>
                            </tbody>
                            <% if (outstandingSuppliers.size() > 0) {
                                double totalOS = 0;
                                for (Vector row : outstandingSuppliers) totalOS += (Double) row.get(1);
                            %>
                            <tfoot class="table-light">
                                <tr>
                                    <th colspan="2" class="text-end">Total (Top 5):</th>
                                    <th class="text-end text-danger">&#8377; <%= String.format("%,.2f", totalOS) %></th>
                                </tr>
                            </tfoot>
                            <% } %>
                        </table>
                    </div>
                </div>
            </div>
        </div>

    </div>

    <script>
        const labels       = [<%= labels.toString() %>];
        const salesData    = [<%= salesData.toString() %>];
        const purchaseData = [<%= purchaseData.toString() %>];

        const commonOptions = {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { position: 'top' },
                tooltip: {
                    mode: 'index',
                    intersect: false,
                    backgroundColor: 'rgba(0,0,0,0.8)',
                    padding: 10,
                    cornerRadius: 8
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: { borderDash: [2,4], color: '#e9ecef' },
                    ticks: { callback: v => '\u20B9' + v }
                },
                x: { grid: { display: false } }
            },
            interaction: { mode: 'nearest', axis: 'x', intersect: false }
        };

        new Chart(document.getElementById('combinedChart'), {
            type: 'line',
            data: {
                labels,
                datasets: [
                    { label: 'Sales',    data: salesData,    borderColor: '#667eea', backgroundColor: 'rgba(102,126,234,0.1)', borderWidth: 3, fill: true,  tension: 0.4, pointRadius: 0, pointHoverRadius: 6 },
                    { label: 'Purchase', data: purchaseData, borderColor: '#764ba2', backgroundColor: 'rgba(118,75,162,0.1)',  borderWidth: 2, fill: false, tension: 0.4, pointRadius: 0, pointHoverRadius: 6, borderDash: [5,5] }
                ]
            },
            options: commonOptions
        });

        new Chart(document.getElementById('comparisonChart'), {
            type: 'doughnut',
            data: {
                labels: ['Total Sales', 'Total Purchase'],
                datasets: [{ data: [<%= thisSale %>, <%= thisPurchase %>], backgroundColor: ['#667eea','#764ba2'], hoverOffset: 4 }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom' },
                    tooltip: { callbacks: { label: ctx => (ctx.label ? ctx.label+': ' : '') + '\u20B9' + ctx.parsed.toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2}) } }
                },
                cutout: '70%'
            }
        });

        const marginChart = new Chart(document.getElementById('marginChart'), {
            type: 'bar',
            data: { labels, datasets: [{ label: 'Sales', data: salesData, backgroundColor: '#667eea', borderRadius: 4, barPercentage: 0.6 }] },
            options: commonOptions
        });

        const purchaseChart = new Chart(document.getElementById('purchaseChart'), {
            type: 'bar',
            data: { labels, datasets: [{ label: 'Purchase', data: purchaseData, backgroundColor: '#764ba2', borderRadius: 4, barPercentage: 0.6 }] },
            options: commonOptions
        });

        document.getElementById('downloadMargin').addEventListener('click', () => {
            const a = document.createElement('a'); a.download='sales_chart.png'; a.href=marginChart.toBase64Image(); a.click();
        });
        document.getElementById('downloadPurchase').addEventListener('click', () => {
            const a = document.createElement('a'); a.download='purchase_chart.png'; a.href=purchaseChart.toBase64Image(); a.click();
        });
    </script>
</body>
</html>
