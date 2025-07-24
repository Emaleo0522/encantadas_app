import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'theme/theme.dart';
import 'models/appointment.dart';
import 'models/transaction.dart';
import 'models/product.dart';
import 'models/provider.dart';
import 'widgets/add_appointment_form.dart';
import 'widgets/add_product_form.dart';
import 'widgets/add_provider_form.dart';
import 'widgets/add_sale_form.dart';
import 'screens/home_screen.dart';
import 'screens/turnos_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/ventas_screen.dart';
import 'screens/balance_screen.dart';
import 'screens/providers_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(AppointmentAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(ProductCategoryAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(ProviderAdapter());
  
  // Open Hive boxes
  await Hive.openBox<Appointment>('appointments');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Product>('products');
  await Hive.openBox<Provider>('providers');
  
  await initializeNotifications();
  
  runApp(const EncantadasApp());
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(
    defaultActionName: 'Open notification',
  );

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
    linux: initializationSettingsLinux,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
    },
  );
}

class EncantadasApp extends StatefulWidget {
  const EncantadasApp({super.key});

  @override
  State<EncantadasApp> createState() => _EncantadasAppState();
}

class _EncantadasAppState extends State<EncantadasApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light 
          ? ThemeMode.dark 
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encantadas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      locale: const Locale('es', 'ES'),
      home: MainNavigationScreen(onThemeToggle: toggleTheme),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  
  const MainNavigationScreen({
    super.key,
    required this.onThemeToggle,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TurnosScreen(),
    const StockScreen(),
    const VentasScreen(),
    const BalanceScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Get the FAB for the current screen
  Widget? _getCurrentFAB() {
    switch (_selectedIndex) {
      case 1: // TurnosScreen
        return FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddAppointmentForm(),
            );
          },
          tooltip: 'Agregar nuevo turno',
          child: const Icon(Icons.add),
        );
      case 2: // StockScreen
        return FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddProductForm(),
            );
          },
          tooltip: 'Agregar nuevo producto',
          child: const Icon(Icons.add),
        );
      case 3: // VentasScreen
        return FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddSaleForm(),
            );
          },
          tooltip: 'Registrar nueva venta',
          child: const Icon(Icons.add),
        );
      default:
        return FloatingActionButton(
          onPressed: widget.onThemeToggle,
          tooltip: 'Cambiar tema',
          child: Icon(
            Theme.of(context).brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Turnos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Ventas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Balance',
          ),
        ],
      ),
      floatingActionButton: _getCurrentFAB(),
    );
  }
}