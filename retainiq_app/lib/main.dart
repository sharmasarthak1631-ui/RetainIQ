import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const RetainiqApp());
}

class RetainiqApp extends StatelessWidget {
  const RetainiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RETAINIQ - HR Control Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'System', 
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9), 
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)))),
          title: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.analytics_rounded, color: Colors.indigo.shade600, size: 24)),
                const SizedBox(width: 15),
                Text("RETAINIQ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey.shade900, fontSize: 22, letterSpacing: 1.2)),
                const SizedBox(width: 12),
                Container(height: 20, width: 2, color: Colors.grey.shade300),
                const SizedBox(width: 12),
                Text("Decision Support System", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() { _selectedIndex = index; });
            },
            backgroundColor: Colors.white,
            selectedIconTheme: IconThemeData(color: Colors.indigo.shade600),
            selectedLabelTextStyle: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
            unselectedIconTheme: IconThemeData(color: Colors.blueGrey.shade300),
            unselectedLabelTextStyle: TextStyle(color: Colors.blueGrey.shade400),
            extended: true,
            minExtendedWidth: 200,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.people_alt_rounded), label: Text('Directory')),
              NavigationRailDestination(icon: Icon(Icons.auto_awesome_rounded), label: Text('AI Agent')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _selectedIndex == 0 
                ? const DashboardScreen() 
                : _selectedIndex == 1 
                    ? const EmployeeDirectoryScreen()
                    : const AiAgentScreen(),
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  Map<String, dynamic> kpis = {};
  Map<String, dynamic> chartData = {};
  Map<String, dynamic> driverChartData = {};
  List<dynamic> tableData = [];
  List<dynamic> actionLogs = [];

  String simOutput = "";
  String? selectedIntervention;
  
  final TextEditingController empIdController = TextEditingController();
  final TextEditingController ownerController = TextEditingController();
  String? selectedLogIntervention;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
    fetchActionLogs();
  }

  Future<void> fetchDashboardData() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/dashboard'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          kpis = data['kpis'];
          chartData = data['chart'];
          driverChartData = data['driver_chart'];
          tableData = data['table'];
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchActionLogs() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/logs'));
      if (response.statusCode == 200) setState(() => actionLogs = json.decode(response.body)['logs']);
    } catch (e) { print(e); }
  }

  Future<void> runSimulation() async {
    if (selectedIntervention == null) return;
    try {
      final response = await http.post(Uri.parse('http://127.0.0.1:8000/api/simulate'), headers: {'Content-Type': 'application/json'}, body: json.encode({"intervention": selectedIntervention}));
      setState(() {
        final data = json.decode(response.body);
        simOutput = "Projected High Risk: ${data['new_high_risk']} (Saved: ₹${data['savings']})";
      });
    } catch (e) { print(e); }
  }

  Future<void> submitActionLog() async {
    if (empIdController.text.isEmpty || ownerController.text.isEmpty || selectedLogIntervention == null) return;
    try {
      final response = await http.post(Uri.parse('http://127.0.0.1:8000/api/log_action'), headers: {'Content-Type': 'application/json'}, body: json.encode({"emp_id": empIdController.text, "intervention": selectedLogIntervention, "owner": ownerController.text}));
      setState(() {
        actionLogs = json.decode(response.body)['logs'];
        empIdController.clear(); ownerController.clear(); selectedLogIntervention = null;
      });
      await fetchDashboardData();
    } catch (e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Colors.indigo));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: buildKpiCard("HIGH RISK", kpis['high'].toString(), Icons.warning_rounded, Colors.red)),
              const SizedBox(width: 24),
              Expanded(child: buildKpiCard("MEDIUM RISK", kpis['medium'].toString(), Icons.trending_flat_rounded, Colors.orange)),
              const SizedBox(width: 24),
              Expanded(child: buildKpiCard("LOW RISK", kpis['low'].toString(), Icons.check_circle_rounded, Colors.teal)),
              const SizedBox(width: 24),
              Expanded(child: buildKpiCard("COST AT RISK", "₹${kpis['cost']}", Icons.account_balance_wallet_rounded, Colors.indigo)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: buildSectionCard("Risk by Department", Icons.donut_large_rounded, SizedBox(height: 260, child: buildDepartmentDoughnut(chartData)))),
              const SizedBox(width: 24),
              Expanded(child: buildSectionCard("Top Contributing Drivers", Icons.sort_rounded, SizedBox(height: 260, child: buildHorizontalBars(driverChartData)))),
            ],
          ),
          const SizedBox(height: 24),
          buildSectionCard("High-Risk Employee Drill-Down", Icons.people_alt_rounded, SizedBox(width: double.infinity, child: buildEmployeeTable())),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: buildSectionCard(
                  "Intervention Simulator", Icons.science_rounded,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: "Select Intervention"), value: selectedIntervention, items: ["Career Path", "Manager Coaching", "Comp Review"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => selectedIntervention = val)),
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: runSimulation, icon: const Icon(Icons.play_arrow_rounded), label: const Text("Simulate Impact", style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white))),
                      if (simOutput.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.shade100)), child: Text(simOutput, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade900, height: 1.5)))
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: buildSectionCard(
                  "Closed-Loop Action Tracker", Icons.assignment_turned_in_rounded, 
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            TextField(controller: empIdController, decoration: const InputDecoration(labelText: "Employee ID")),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: "Assign Intervention"), value: selectedLogIntervention, items: ["Career Path", "Manager Coaching", "Comp Review", "Stay Interview"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => selectedLogIntervention = val)),
                            const SizedBox(height: 16),
                            TextField(controller: ownerController, decoration: const InputDecoration(labelText: "Owner")),
                            const SizedBox(height: 20),
                            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: submitActionLog, icon: const Icon(Icons.lock_clock_rounded), label: const Text("Lock Intervention", style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        flex: 1,
                        child: actionLogs.isEmpty 
                          ? Center(child: Text("No actions logged yet.", style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 16)))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                dataRowMaxHeight: 60,
                                columns: const [DataColumn(label: Text("Emp ID")), DataColumn(label: Text("Intervention")), DataColumn(label: Text("Pulse"))],
                                rows: actionLogs.map((log) => DataRow(cells: [DataCell(Text(log['emp_id'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700))), DataCell(Text(log['intervention'])), DataCell(Text(log['follow_up']))])).toList(),
                              ),
                            ),
                      )
                    ],
                  )
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildKpiCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]), child: Row(children: [Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.shade50, shape: BoxShape.circle), child: Icon(icon, color: color.shade600, size: 32)), const SizedBox(width: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.blueGrey.shade500, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))])]));
  }
  Widget buildSectionCard(String title, IconData icon, Widget content) {
    return Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: Colors.blueGrey.shade400, size: 22), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)))]), const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFE2E8F0))), content]));
  }
  Widget buildDepartmentDoughnut(Map<String, dynamic> data) {
    if (data.isEmpty) return const Center(child: Text("No Data"));
    final List<Color> colors = [Colors.indigo.shade500, Colors.teal.shade400, Colors.amber.shade500, Colors.pink.shade400, Colors.purple.shade400]; int colorIndex = 0; final keys = data.keys.toList();
    return Row(children: [Expanded(flex: 1, child: PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 50, sections: data.entries.map((entry) {final color = colors[colorIndex++ % colors.length]; return PieChartSectionData(color: color, value: entry.value.toDouble(), title: '${entry.value}', radius: 35, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white));}).toList()))), Expanded(flex: 1, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: keys.asMap().entries.map((entry) {int idx = entry.key; return Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: colors[idx % colors.length], shape: BoxShape.circle)), const SizedBox(width: 12), Text(entry.value, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700, fontSize: 14))]));}).toList()))]);
  }
  Widget buildHorizontalBars(Map<String, dynamic> data) {
    if (data.isEmpty) return const Center(child: Text("No Data"));
    int maxVal = data.values.fold(0, (max, v) => v > max ? v : max);
    return ListView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: data.entries.map((entry) { double percentage = maxVal == 0 ? 0 : entry.value / maxVal; return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(entry.key, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey.shade800, fontSize: 14)), Text('${entry.value}', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo.shade600, fontSize: 14))]), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: percentage, minHeight: 12, backgroundColor: Colors.indigo.shade50, valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400)))]));}).toList());
  }
  Widget buildEmployeeTable() {
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)), dataRowMaxHeight: 65, columns: const [DataColumn(label: Text("Employee ID", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))), DataColumn(label: Text("Department", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))), DataColumn(label: Text("Risk Score", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))), DataColumn(label: Text("Top Drivers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)))], rows: tableData.map((emp) { Color badgeColor = emp['Risk Band'] == 'High' ? Colors.red.shade50 : emp['Risk Band'] == 'Medium' ? Colors.orange.shade50 : Colors.teal.shade50; Color textColor = emp['Risk Band'] == 'High' ? Colors.red.shade700 : emp['Risk Band'] == 'Medium' ? Colors.orange.shade800 : Colors.teal.shade700; if (emp['Risk Score'] < 3) { badgeColor = Colors.teal.shade50; textColor = Colors.teal.shade700; } return DataRow(cells: [DataCell(Text(emp['Employee ID'].toString(), style: TextStyle(fontWeight: FontWeight.w800, color: Colors.indigo.shade700))), DataCell(Text(emp['Department'].toString(), style: const TextStyle(fontWeight: FontWeight.w500))), DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: textColor.withOpacity(0.3))), child: Text(emp['Risk Score'].toString(), style: TextStyle(color: textColor, fontWeight: FontWeight.w900)))), DataCell(Text(emp['Top Drivers'].toString(), style: TextStyle(color: Colors.blueGrey.shade600)))]);}).toList()))));
  }
}

class EmployeeDirectoryScreen extends StatefulWidget {
  const EmployeeDirectoryScreen({super.key});
  @override
  State<EmployeeDirectoryScreen> createState() => _EmployeeDirectoryScreenState();
}
class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  bool isLoading = true; List<dynamic> allEmployees = []; List<dynamic> filteredEmployees = [];
  String searchQuery = ""; String filterDept = "All"; String filterRisk = "All";
  @override
  void initState() { super.initState(); fetchEmployees(); }
  Future<void> fetchEmployees() async {
    try { final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/employees'));
      if (response.statusCode == 200) { final data = json.decode(response.body); setState(() { allEmployees = data['employees']; filteredEmployees = List.from(allEmployees); isLoading = false; }); }
    } catch (e) { print(e); }
  }
  void applyFilters() {
    setState(() {
      filteredEmployees = allEmployees.where((emp) {
        return (emp['Employee ID'].toString().toLowerCase().contains(searchQuery.toLowerCase())) &&
               (filterDept == "All" || emp['Department'] == filterDept) &&
               (filterRisk == "All" || emp['Risk Band'] == filterRisk);
      }).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Colors.indigo));
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Employee Directory", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade900)),
          const SizedBox(height: 8), Text("View and filter the entire organizational dataset.", style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade500)),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]),
            child: Row(
              children: [
                Expanded(flex: 2, child: TextField(onChanged: (val) {searchQuery = val; applyFilters();}, decoration: const InputDecoration(labelText: "Search by Employee ID...", prefixIcon: Icon(Icons.search_rounded)))),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: "Department"), value: filterDept, items: ["All", "Tech", "Sales", "Support", "HR", "Marketing", "Finance"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) {filterDept = val!; applyFilters();})),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: "Risk Band"), value: filterRisk, items: ["All", "High", "Medium", "Low"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) {filterRisk = val!; applyFilters();})),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: SingleChildScrollView(scrollDirection: Axis.vertical, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)), dataRowMaxHeight: 65, columnSpacing: 60, columns: const [DataColumn(label: Text("Employee ID", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))), DataColumn(label: Text("Department", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))), DataColumn(label: Text("Risk Band", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))), DataColumn(label: Text("Risk Score", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))), DataColumn(label: Text("Primary Drivers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)))], rows: filteredEmployees.map((emp) { Color badgeColor = emp['Risk Band'] == 'High' ? Colors.red.shade50 : emp['Risk Band'] == 'Medium' ? Colors.orange.shade50 : Colors.teal.shade50; Color textColor = emp['Risk Band'] == 'High' ? Colors.red.shade700 : emp['Risk Band'] == 'Medium' ? Colors.orange.shade800 : Colors.teal.shade700; return DataRow(cells: [DataCell(Text(emp['Employee ID'].toString(), style: TextStyle(fontWeight: FontWeight.w800, color: Colors.indigo.shade700))), DataCell(Text(emp['Department'].toString(), style: const TextStyle(fontWeight: FontWeight.w500))), DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: textColor.withOpacity(0.3))), child: Text(emp['Risk Band'].toString().toUpperCase(), style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 11)))), DataCell(Text(emp['Risk Score'].toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))), DataCell(Text(emp['Top Drivers'].toString(), style: TextStyle(color: Colors.blueGrey.shade600)))]);}).toList())))))),
        ],
      ),
    );
  }
}

class AiAgentScreen extends StatefulWidget {
  const AiAgentScreen({super.key});
  @override
  State<AiAgentScreen> createState() => _AiAgentScreenState();
}
class _AiAgentScreenState extends State<AiAgentScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isAnalyzing = false;
  
  String? chatDiagnosis;
  List<String> chatQuestions = [];
  String? chatAction;

  Future<void> runGeminiAnalysis() async {
    if (_promptController.text.isEmpty) return;
    setState(() => _isAnalyzing = true);
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/chatbot'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"message": _promptController.text}),
      );
      final data = json.decode(response.body);
      setState(() {
        chatDiagnosis = data['diagnosis'];
        chatQuestions = List<String>.from(data['questions']);
        chatAction = data['action'];
      });
    } catch (e) { print(e); }
    setState(() => _isAnalyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.indigo.shade600, size: 36),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("HR Advisor", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade900)),
                  Text("Ask questions about your live employee dataset for AI-driven recommendations.", style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade500)),
                ],
              )
            ],
          ),
          const SizedBox(height: 30),
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]),
              child: Column(
                children: [
                  Expanded(
                    child: chatDiagnosis == null && !_isAnalyzing
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.blueGrey.shade100),
                                const SizedBox(height: 16),
                                Text("How can I help you manage employee retention today?", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 18, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text("Try asking: 'Which department has the most burnout?' or 'What should I do about E004?'", style: TextStyle(color: Colors.blueGrey.shade300)),
                              ],
                            ),
                          )
                        : _isAnalyzing
                            ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.shade100)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [Icon(Icons.troubleshoot_rounded, size: 24, color: Colors.indigo.shade700), const SizedBox(width: 12), Text("Diagnosis", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo.shade900, fontSize: 18))]),
                                    const SizedBox(height: 8),
                                    Text(chatDiagnosis!, style: TextStyle(fontSize: 16, color: Colors.indigo.shade800, height: 1.5)),
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                                    
                                    Row(children: [Icon(Icons.forum_rounded, size: 24, color: Colors.indigo.shade700), const SizedBox(width: 12), Text("Stay Interview Strategy", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo.shade900, fontSize: 18))]),
                                    const SizedBox(height: 12),
                                    ...chatQuestions.map((q) => Padding(padding: const EdgeInsets.only(bottom: 12.0, left: 8.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo.shade400)), Expanded(child: Text(q, style: TextStyle(fontSize: 16, color: Colors.indigo.shade800, height: 1.3)))]))),
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                                    
                                    Row(children: [Icon(Icons.task_alt_rounded, size: 24, color: Colors.teal.shade700), const SizedBox(width: 12), Text("Prescribed Action", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal.shade900, fontSize: 18))]),
                                    const SizedBox(height: 8),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(8)), child: Text(chatAction!, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal.shade900, fontSize: 16))),
                                  ],
                                ),
                              ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promptController,
                          decoration: InputDecoration(
                            hintText: "Ask Gemini about your HR data...",
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          ),
                          onSubmitted: (_) => runGeminiAnalysis(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FloatingActionButton(
                        onPressed: runGeminiAnalysis,
                        backgroundColor: Colors.indigo.shade600,
                        elevation: 0,
                        child: const Icon(Icons.send_rounded, color: Colors.white),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}