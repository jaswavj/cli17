<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import= "java.util.*"%>
<jsp:useBean id="op1" class="billing.billingBean" />
<jsp:useBean id="prod" class="product.productBean" />
<%
///////////////////  Sales  /////////////////
double thisSale =op1.getThisMonthPhSale();
double lastSale =op1.getLastMonthPhSale();
double saleMargin =thisSale-lastSale;
double saleMarginPercent = 0;
if (lastSale != 0) {
    saleMarginPercent = (saleMargin / lastSale) * 100;
}
String saleColor = (saleMarginPercent >= 0) ? "green" : "red";
//////////////////  Purchase  /////////////////
double thisPurchase =op1.getThisMonthPhPurchase();
double lastPurchase =op1.getLastMonthPhPurchase();
double purchaseMargin =thisPurchase-lastPurchase;
double purchaseMarginPercent = 0;
if (lastPurchase != 0) {
    purchaseMarginPercent = (purchaseMargin / lastPurchase) * 100;
}
String PurchaseColor = (purchaseMarginPercent >= 0) ? "green" : "red";

///////////////////  Today's Sales  /////////////////
double todaySales = op1.getTodaySales();
int todayBillCount = op1.getTodayBillCount();

///////////////////  Profit  /////////////////
// Calculate this month's date range
java.util.Calendar cal = java.util.Calendar.getInstance();
cal.set(java.util.Calendar.DAY_OF_MONTH, 1);
String thisMonthStart = new java.text.SimpleDateFormat("yyyy-MM-dd").format(cal.getTime());
cal.set(java.util.Calendar.DAY_OF_MONTH, cal.getActualMaximum(java.util.Calendar.DAY_OF_MONTH));
String thisMonthEnd = new java.text.SimpleDateFormat("yyyy-MM-dd").format(cal.getTime());

// Calculate last month's date range
cal.add(java.util.Calendar.MONTH, -1);
cal.set(java.util.Calendar.DAY_OF_MONTH, 1);
String lastMonthStart = new java.text.SimpleDateFormat("yyyy-MM-dd").format(cal.getTime());
cal.set(java.util.Calendar.DAY_OF_MONTH, cal.getActualMaximum(java.util.Calendar.DAY_OF_MONTH));
String lastMonthEnd = new java.text.SimpleDateFormat("yyyy-MM-dd").format(cal.getTime());

// Get profit data for this month
Vector thisMonthProfitData = op1.getProfitAnalysisReport(thisMonthStart, thisMonthEnd);
double thisProfit = 0.0;
for (int i = 0; i < thisMonthProfitData.size(); i++) {
    Vector row = (Vector) thisMonthProfitData.elementAt(i);
    double totalCost = Double.parseDouble(row.elementAt(4).toString());
    double saleTotal = Double.parseDouble(row.elementAt(5).toString());
    // Only include records where cost data is available (> 0)
    if (totalCost > 0) {
        thisProfit += (saleTotal - totalCost);
    }
}

// Get profit data for last month
Vector lastMonthProfitData = op1.getProfitAnalysisReport(lastMonthStart, lastMonthEnd);
double lastProfit = 0.0;
for (int i = 0; i < lastMonthProfitData.size(); i++) {
    Vector row = (Vector) lastMonthProfitData.elementAt(i);
    double totalCost = Double.parseDouble(row.elementAt(4).toString());
    double saleTotal = Double.parseDouble(row.elementAt(5).toString());
    // Only include records where cost data is available (> 0)
    if (totalCost > 0) {
        lastProfit += (saleTotal - totalCost);
    }
}

double profitMargin = thisProfit - lastProfit;
double profitMarginPercent = 0;
if (lastProfit != 0) {
    profitMarginPercent = (profitMargin / lastProfit) * 100;
}
String profitColor = (profitMarginPercent >= 0) ? "green" : "red";

///////////////////  Expenses  /////////////////
// Get this month's expenses
double thisExpense = 0.0;
try {
    Vector thisMonthExpenses = prod.getExpenseReport(thisMonthStart, thisMonthEnd, 0);
    if (thisMonthExpenses != null) {
        for (int i = 0; i < thisMonthExpenses.size(); i++) {
            Vector row = (Vector) thisMonthExpenses.get(i);
            if (row.size() > 4) {
                thisExpense += Double.parseDouble(row.get(4).toString());
            }
        }
    }
} catch (Exception e) {
    System.err.println("Error loading this month expenses: " + e.getMessage());
}

// Get last month's expenses
double lastExpense = 0.0;
try {
    Vector lastMonthExpenses = prod.getExpenseReport(lastMonthStart, lastMonthEnd, 0);
    if (lastMonthExpenses != null) {
        for (int i = 0; i < lastMonthExpenses.size(); i++) {
            Vector row = (Vector) lastMonthExpenses.get(i);
            if (row.size() > 4) {
                lastExpense += Double.parseDouble(row.get(4).toString());
            }
        }
    }
} catch (Exception e) {
    System.err.println("Error loading last month expenses: " + e.getMessage());
}

double expenseMargin = thisExpense - lastExpense;
double expenseMarginPercent = 0;
if (lastExpense != 0) {
    expenseMarginPercent = (expenseMargin / lastExpense) * 100;
}
String expenseColor = (expenseMarginPercent >= 0) ? "red" : "green"; // Lower expense is better

// Calculate net profit including expenses
double netProfitWithExpenses = thisProfit - thisExpense;

// Get today's date
java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd-MMM-yyyy");
String todayDate = sdf.format(new java.util.Date());

/////////////////////  Sales Graph  //////////////////
Vector vec = op1.getSalesReportCharts();  // Each element is a Vector or ArrayList
    StringBuilder labels = new StringBuilder();
    StringBuilder salesData = new StringBuilder();

    for (int i = 0; i < vec.size(); i++) {
        Vector row = (Vector) vec.elementAt(i);
        String date = row.elementAt(0).toString();   // first column is date
        String total = row.elementAt(1).toString();  // second column is total sales

        labels.append("\"").append(date).append("\"");
        if (!total.isEmpty() && !total.equals("0")) {
            salesData.append(total);
        } else {
            salesData.append("0");
        }

        if (i < vec.size() - 1) {
            labels.append(", ");
            salesData.append(", ");
        }
    }

/////////////////////  Top Customers and Suppliers Data  //////////////////
Vector<Vector> topCustomers = op1.getTopCustomers();
Vector<Vector> topSuppliers = op1.getTopSuppliers();
Vector<Vector> outstandingCustomers = op1.getOutstandingCustomers();
Vector<Vector> outstandingSuppliers = op1.getOutstandingSuppliers();

/////////////////////  Purchase Graph  //////////////////
Vector vecPurchase = op1.getPurchaseReportCharts();  // Each element is a Vector or ArrayList
    StringBuilder purchaseData = new StringBuilder();

    for (int i = 0; i < vecPurchase.size(); i++) {
        Vector row = (Vector) vecPurchase.elementAt(i);
        String total = row.elementAt(1).toString();  // second column is total purchase

        if (!total.isEmpty() && !total.equals("0")) {
            purchaseData.append(total);
        } else {
            purchaseData.append("0");
        }

        if (i < vecPurchase.size() - 1) {
            purchaseData.append(", ");
        }
    }

%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Executive Dashboard</title>
    <%@ include file="/assets/common/head.jsp" %>
    <style>
        /* Custom Dashboard Styles */
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
        .trend-indicator {
            font-size: 0.9rem;
            font-weight: 600;
        }
        .trend-up { color: #198754; }
        .trend-down { color: #dc3545; }
        .chart-container {
            background: white;
            border-radius: 12px;
            padding: 15px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
            /* height: 100%; Removed to prevent infinite resizing loop */
        }
        .chart-wrapper {
            position: relative;
            height: 250px;
            width: 100%;
        }
        .chart-wrapper-sm {
            position: relative;
            height: 180px;
            width: 100%;
        }
        .welcome-banner {
            background: var(--primary-gradient);
            color: white;
            border-radius: 10px;
            padding: 15px 25px;
            margin-bottom: 20px;
            box-shadow: 0 4px 10px rgba(118, 75, 162, 0.2);
        }
    </style>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
    
    <div class="container-fluid py-4 px-4">
        <!-- Welcome Banner -->
        

        <!-- Summary Cards -->
        <div class="row g-4 mb-4">
            <!-- Today's Sales Card -->
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
            
            <!-- Sales Card -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 border-primary">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Total Sales (This Month)</h6>
                        <h4 class="fw-bold text-dark mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", thisSale) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="trend-indicator <%= saleMarginPercent >= 0 ? "trend-up" : "trend-down" %> me-1" style="font-size: 0.7rem;">
                                <i class="fas <%= saleMarginPercent >= 0 ? "fa-arrow-up" : "fa-arrow-down" %>"></i> 
                                <%= String.format("%.1f", Math.abs(saleMarginPercent)) %>%
                            </span>
                            <span class="text-muted" style="font-size: 0.65rem;">vs last month</span>
                        </div>
                        <i class="fas fa-chart-line card-icon text-primary" style="font-size: 2.5rem;"></i>
                    </div>
                </div>
            </div>

            <!-- Purchase Card -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 border-success">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Total Purchase (This Month)</h6>
                        <h4 class="fw-bold text-dark mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", thisPurchase) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="trend-indicator <%= purchaseMarginPercent >= 0 ? "trend-up" : "trend-down" %> me-1" style="font-size: 0.7rem;">
                                <i class="fas <%= purchaseMarginPercent >= 0 ? "fa-arrow-up" : "fa-arrow-down" %>"></i> 
                                <%= String.format("%.1f", Math.abs(purchaseMarginPercent)) %>%
                            </span>
                            <span class="text-muted" style="font-size: 0.65rem;">vs last month</span>
                        </div>
                        <i class="fas fa-shopping-cart card-icon text-success" style="font-size: 2.5rem;"></i>
                    </div>
                </div>
            </div>

            <!-- Net Margin Card (Calculated) -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 border-info">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Net Difference</h6>
                        <h4 class="fw-bold text-dark mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", thisSale - thisPurchase) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="text-muted" style="font-size: 0.65rem;">Sales - Purchase</span>
                        </div>
                        <i class="fas fa-wallet card-icon text-info" style="font-size: 2.5rem;"></i>
                    </div>
                </div>
            </div>
            
             <!-- Last Month Sales Card -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 border-warning">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Last Month Sales</h6>
                        <h4 class="fw-bold text-dark mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", lastSale) %></h4>
                        <div class="d-flex align-items-center">
                             <span class="text-muted" style="font-size: 0.65rem;">Previous Period</span>
                        </div>
                        <i class="fas fa-history card-icon text-warning" style="font-size: 2.5rem;"></i>
                    </div>
                </div>
            </div>
            
            <!-- Profit Card -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 border-success">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Gross Profit (This Month)</h6>
                        <h4 class="fw-bold text-dark mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", thisProfit) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="trend-indicator <%= profitMarginPercent >= 0 ? "trend-up" : "trend-down" %> me-1" style="font-size: 0.7rem;">
                                <i class="fas <%= profitMarginPercent >= 0 ? "fa-arrow-up" : "fa-arrow-down" %>"></i> 
                                <%= String.format("%.1f", Math.abs(profitMarginPercent)) %>%
                            </span>
                            <span class="text-muted" style="font-size: 0.65rem;">vs last month</span>
                        </div>
                        <i class="fas fa-chart-pie card-icon text-success" style="font-size: 2.5rem;"></i>
                    </div>
                </div>
            </div>
            
            <!-- Expenses Card -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4" style="border-color: #5b21b6 !important;">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Expenses (This Month)</h6>
                        <h4 class="fw-bold text-dark mb-2" style="font-size: 1.1rem;">&#8377; <%= String.format("%,.2f", thisExpense) %></h4>
                        <div class="d-flex align-items-center">
                            <span class="trend-indicator <%= expenseMarginPercent < 0 ? "trend-up" : "trend-down" %> me-1" style="font-size: 0.7rem;">
                                <i class="fas <%= expenseMarginPercent >= 0 ? "fa-arrow-up" : "fa-arrow-down" %>"></i> 
                                <%= String.format("%.1f", Math.abs(expenseMarginPercent)) %>%
                            </span>
                            <span class="text-muted" style="font-size: 0.65rem;">vs last month</span>
                        </div>
                        <i class="fas fa-receipt card-icon" style="font-size: 2.5rem; color: #5b21b6;"></i>
                    </div>
                </div>
            </div>
            
            <!-- Net Profit Card -->
            <div class="col-xl-2 col-lg-3 col-md-4 col-sm-6">
                <div class="card dashboard-card h-100 border-start border-4 <%= netProfitWithExpenses >= 0 ? "border-success" : "border-danger" %>">
                    <div class="card-body position-relative" style="padding: 0.75rem;">
                        <h6 class="text-muted text-uppercase fw-bold mb-2" style="font-size: 0.7rem;">Net Profit (This Month)</h6>
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
            <!-- Main Combined Chart -->
            <div class="col-lg-8">
                <div class="chart-container">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <h5 class="fw-bold mb-0">Financial Overview <small class="text-muted">(Last 16 Days)</small></h5>
                        <div class="btn-group btn-group-sm">
                             <button class="btn btn-outline-secondary active">Daily</button>
                        </div>
                    </div>
                    <div class="chart-wrapper">
                        <canvas id="combinedChart"></canvas>
                    </div>
                </div>
            </div>

            <!-- Distribution / Pie Chart (Placeholder or derived data) -->
            <!-- Since we don't have category data here, let's use the Purchase vs Sales comparison bar chart -->
            <div class="col-lg-4">
                <div class="chart-container">
                    <h5 class="fw-bold mb-3">Sales vs Purchase <small class="text-muted">(This Month)</small></h5>
                    <div class="chart-wrapper">
                        <canvas id="comparisonChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Detailed Graphs Row -->
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
        
        <!-- Customer & Supplier Dashboards -->
        <div class="row g-4 mt-1">
            <!-- Top Customers by Sales -->
            <div class="col-lg-6">
                <div class="chart-container">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h5 class="fw-bold mb-0"><i class="fas fa-users text-primary me-2"></i>Top Customers (This Month)</h5>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th style="width: 5%;">#</th>
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
                                        int billCount = (Integer) row.get(2);
                                %>
                                    <tr>
                                        <td><%= i + 1 %></td>
                                        <td><strong><%= name %></strong></td>
                                        <td class="text-end text-primary fw-bold">&#8377; <%= String.format("%,.2f", sales) %></td>
                                        <td class="text-center"><span class="badge bg-info"><%= billCount %></span></td>
                                    </tr>
                                <% } } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            
            <!-- Top Suppliers by Purchase -->
            <div class="col-lg-6">
                <div class="chart-container">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h5 class="fw-bold mb-0"><i class="fas fa-truck text-success me-2"></i>Top Suppliers (This Month)</h5>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th style="width: 5%;">#</th>
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
                                        int orderCount = (Integer) row.get(2);
                                %>
                                    <tr>
                                        <td><%= i + 1 %></td>
                                        <td><strong><%= name %></strong></td>
                                        <td class="text-end text-success fw-bold">&#8377; <%= String.format("%,.2f", purchase) %></td>
                                        <td class="text-center"><span class="badge bg-info"><%= orderCount %></span></td>
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
            <!-- Outstanding Customer Balances -->
            <div class="col-lg-6">
                <div class="chart-container">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h5 class="fw-bold mb-0"><i class="fas fa-money-bill-wave text-warning me-2"></i>Top Outstanding Customers</h5>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th style="width: 5%;">#</th>
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
                                        double outstanding = (Double) row.get(1);
                                        double pending = (Double) row.get(2);
                                %>
                                    <tr>
                                        <td><%= i + 1 %></td>
                                        <td><strong><%= name %></strong></td>
                                        
                                        <td class="text-end text-warning fw-bold">&#8377; <%= String.format("%,.2f", pending) %></td>
                                    </tr>
                                <% } } %>
                            </tbody>
                            <% if (outstandingCustomers.size() > 0) {
                                double totalOutstanding = 0;
                                for (Vector row : outstandingCustomers) {
                                    totalOutstanding += (Double) row.get(1);
                                }
                            %>
                            <tfoot class="table-light">
                                <tr>
                                    <th colspan="2" class="text-end">Total (Top 5):</th>
                                    <th class="text-end text-danger">&#8377; <%= String.format("%,.2f", totalOutstanding) %></th>
                                </tr>
                            </tfoot>
                            <% } %>
                        </table>
                    </div>
                </div>
            </div>
            
            <!-- Outstanding Supplier Balances -->
            <div class="col-lg-6">
                <div class="chart-container">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h5 class="fw-bold mb-0"><i class="fas fa-file-invoice-dollar text-danger me-2"></i>Top Outstanding Suppliers</h5>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th style="width: 5%;">#</th>
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
                                        <td><%= i + 1 %></td>
                                        <td><strong><%= name %></strong></td>
                                        <td class="text-end text-danger fw-bold">&#8377; <%= String.format("%,.2f", outstanding) %></td>
                                    </tr>
                                <% } } %>
                            </tbody>
                            <% if (outstandingSuppliers.size() > 0) {
                                double totalOutstanding = 0;
                                for (Vector row : outstandingSuppliers) {
                                    totalOutstanding += (Double) row.get(1);
                                }
                            %>
                            <tfoot class="table-light">
                                <tr>
                                    <th colspan="2" class="text-end">Total (Top 5):</th>
                                    <th class="text-end text-danger">&#8377; <%= String.format("%,.2f", totalOutstanding) %></th>
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
        // Data from Server
        const labels = [<%= labels.toString() %>];
        const salesData = [<%= salesData.toString() %>];
        const purchaseData = [<%= purchaseData.toString() %>];

        // Common Chart Options
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
                    cornerRadius: 8,
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: { borderDash: [2, 4], color: '#e9ecef' },
                    ticks: { callback: function(value) { return '\u20B9' + value; } }
                },
                x: {
                    grid: { display: false }
                }
            },
            interaction: {
                mode: 'nearest',
                axis: 'x',
                intersect: false
            }
        };

        // 1. Combined Chart (Line for Sales, Bar for Purchase)
        new Chart(document.getElementById('combinedChart'), {
            type: 'line',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'Sales',
                        data: salesData,
                        borderColor: '#667eea',
                        backgroundColor: 'rgba(102, 126, 234, 0.1)',
                        borderWidth: 3,
                        fill: true,
                        tension: 0.4,
                        pointRadius: 0,
                        pointHoverRadius: 6
                    },
                    {
                        label: 'Purchase',
                        data: purchaseData,
                        borderColor: '#764ba2',
                        backgroundColor: 'rgba(118, 75, 162, 0.1)',
                        borderWidth: 2,
                        borderDash: [5, 5],
                        fill: false,
                        tension: 0.4,
                        pointRadius: 0,
                        pointHoverRadius: 6
                    }
                ]
            },
            options: commonOptions
        });

        // 2. Comparison Chart (Doughnut - Total Sales vs Total Purchase)
        // Using the monthly totals (same as cards) for consistency
        const totalSalesMonth = <%= thisSale %>;
        const totalPurchaseMonth = <%= thisPurchase %>;

        new Chart(document.getElementById('comparisonChart'), {
            type: 'doughnut',
            data: {
                labels: ['Total Sales', 'Total Purchase'],
                datasets: [{
                    data: [totalSalesMonth, totalPurchaseMonth],
                    backgroundColor: ['#667eea', '#764ba2'],
                    hoverOffset: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom' },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                let label = context.label || '';
                                if (label) {
                                    label += ': ';
                                }
                                label += '\u20B9' + context.parsed.toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2});
                                return label;
                            }
                        }
                    }
                },
                cutout: '70%'
            }
        });

        // 3. Detailed Sales Chart
        const marginChart = new Chart(document.getElementById('marginChart'), {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Sales Collection',
                    data: salesData,
                    backgroundColor: '#667eea',
                    borderRadius: 4,
                    barPercentage: 0.6
                }]
            },
            options: commonOptions
        });

        // 4. Detailed Purchase Chart
        const purchaseChart = new Chart(document.getElementById('purchaseChart'), {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Purchase Expenses',
                    data: purchaseData,
                    backgroundColor: '#764ba2',
                    borderRadius: 4,
                    barPercentage: 0.6
                }]
            },
            options: commonOptions
        });

        // Download Handlers
        document.getElementById('downloadMargin').addEventListener('click', function() {
            const link = document.createElement('a');
            link.download = 'sales_chart.png';
            link.href = marginChart.toBase64Image();
            link.click();
        });

        document.getElementById('downloadPurchase').addEventListener('click', function() {
            const link = document.createElement('a');
            link.download = 'purchase_chart.png';
            link.href = purchaseChart.toBase64Image();
            link.click();
        });
    </script>
</body>
</html>
