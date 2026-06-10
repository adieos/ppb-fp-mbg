import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:monitorbg/screens/kowner/kowner_create_report_screen.dart';
import 'package:monitorbg/screens/kowner/kowner_dashboard_screen.dart';
import 'package:monitorbg/screens/kowner/kowner_profile.dart';

// import 'kowner_dashboard_screen.dart';
// import 'kowner_reports_screen.dart';

// holds everything in memory
class KownerShell extends StatefulWidget {
  const KownerShell({super.key});

  @override
  State<KownerShell> createState() => _KownerShellState();
}

class _KownerShellState extends State<KownerShell> {
  int _currIndex = 0;

  static const _screens = [
    // TO DO: ganti ini ya
    KownerDashboardScreen(),
    KownerCreateReportScreen(),
    Text("pending reports (calender idk)"),
    KownerProfileTab(),
  ];

  // pake indexedstack = load all widgets in memory, switch based on index
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1C1F2E),
        indicatorColor: const Color(0xFF6C63FF).withOpacity(0.2),
        selectedIndex: _currIndex,
        onDestinationSelected: (n) => setState(() => _currIndex = n),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.menu_book, color: Colors.white),
            label: "Daftar Laporan",
          ),
          NavigationDestination(
            icon: Icon(Icons.create_outlined),
            selectedIcon: Icon(Icons.create, color: Colors.white),
            label: "Buat Laporan",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Colors.white),
            label: "Kalendar",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}
