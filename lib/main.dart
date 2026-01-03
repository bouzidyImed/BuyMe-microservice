import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/manageproduct_screen.dart';
import 'screens/manageorders_screen.dart';
import 'screens/managecategories_screen.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
      ],
      child: MaterialApp(
        title: 'BuyMe Mobile',
        theme: AppTheme.theme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MainScreen(),
          '/admin': (context) => AdminGuard(child: const AdminMainScreen()),
          '/admin/manageproduct': (context) => AdminGuard(child: const AdminMainScreen(initialIndex: 0)),
          '/admin/manageorders': (context) => AdminGuard(child: const AdminMainScreen(initialIndex: 1)),
          '/admin/managecategories': (context) => AdminGuard(child: const AdminMainScreen(initialIndex: 2)),
          '/profile': (context) => AuthGuard(child: const ProfileScreen()),
          '/cart': (context) => AuthGuard(child: const CartScreen()),
          '/checkout': (context) => AuthGuard(child: const CheckoutScreen()),
          '/my-orders': (context) => AuthGuard(child: const MyOrdersScreen()),
          '/contact': (context) => const ContactScreen(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => const NotFoundScreen(),
        ),
      ),
    );
  }
}

class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Provider.of<AuthService>(context, listen: false).isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final isAdmin = snapshot.data == true;
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Unauthorized')),
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('You do not have permission to view this page.'),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/home'), child: const Text('Go Home')),
              ]),
            ),
          );
        }
        return child;
      },
    );
  }
}

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(builder: (ctx, auth, _) {
      if (!auth.isAuthenticated) {
        return Scaffold(
          appBar: AppBar(title: const Text('Login Required')),
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Please login'),
            ),
          ),
        );
      }
      return child;
    });
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    ProfileScreen(),
    CartScreen(),
    MyOrdersScreen(),
    ContactScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(children: [
        Image.asset('assets/images/logo-webdev.svg', height: 28),
        const SizedBox(width: 8),
        Text('BuyMe', style: TextStyle(color: Theme.of(context).primaryColor))
      ])),
      drawer: Drawer(
        child: SafeArea(
          child: Column(children: [
            ListTile(title: const Text('Home'), leading: const Icon(Icons.home), onTap: () => Navigator.pushReplacementNamed(context, '/home')),
            ListTile(title: const Text('Cart'), leading: const Icon(Icons.shopping_cart), onTap: () => Navigator.pushNamed(context, '/cart')),
            ListTile(title: const Text('My Orders'), leading: const Icon(Icons.list), onTap: () => Navigator.pushNamed(context, '/my-orders')),
            const Divider(),
            FutureBuilder<bool>(
              future: Provider.of<AuthService>(context, listen: false).isAdmin(),
              builder: (ctx, snap) {
                final isAdmin = snap.data == true;
                if (!isAdmin) return const SizedBox.shrink();
                return Column(children: [
                  ListTile(title: const Text('Manage Products'), leading: const Icon(Icons.admin_panel_settings), onTap: () => Navigator.pushNamed(context, '/admin/manageproduct')),
                  ListTile(title: const Text('Manage Orders'), leading: const Icon(Icons.list_alt), onTap: () => Navigator.pushNamed(context, '/admin/manageorders')),
                  ListTile(title: const Text('Manage Categories'), leading: const Icon(Icons.category), onTap: () => Navigator.pushNamed(context, '/admin/managecategories')),
                ]);
              },
            ),
            const Spacer(),
            Consumer<AuthService>(builder: (ctx, auth, _) {
              if (auth.isAuthenticated) {
                return ListTile(title: const Text('Logout'), leading: const Icon(Icons.logout), onTap: () async { await auth.logout(); Navigator.pushReplacementNamed(context, '/login'); });
              }
              return ListTile(title: const Text('Login'), leading: const Icon(Icons.login), onTap: () => Navigator.pushReplacementNamed(context, '/login'));
            })
          ]),
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_mail),
            label: 'Contact',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AdminMainScreen extends StatefulWidget {
  final int initialIndex;
  const AdminMainScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _selectedIndex;

  static const List<Widget> _screens = [
    ManageProductScreen(),
    ManageOrdersScreen(),
    ManageCategoriesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Image.asset('assets/images/logo-webdev.svg', height: 28),
          const SizedBox(width: 8),
          Text('BuyMe Admin', style: TextStyle(color: Theme.of(context).primaryColor))
        ]),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Admin Panel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              title: const Text('Manage Products'),
              leading: const Icon(Icons.inventory_2),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Manage Orders'),
              leading: const Icon(Icons.list_alt),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Manage Categories'),
              leading: const Icon(Icons.category),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            Consumer<AuthService>(builder: (ctx, auth, _) {
              return ListTile(
                title: const Text('Logout'),
                leading: const Icon(Icons.logout),
                onTap: () async {
                  await auth.logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              );
            }),
          ]),
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}