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
import 'screens/bestseller_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/manageproduct_screen.dart';
import 'screens/manageorders_screen.dart';
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
          '/bestseller': (context) => const BestsellerScreen(),
          '/client/shop': (context) => const ShopScreen(),
          '/admin/manageproduct': (context) => const ManageProductScreen(),
          '/admin/manageorders': (context) => const ManageOrdersScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/my-orders': (context) => const MyOrdersScreen(),
          '/contact': (context) => const ContactScreen(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => const NotFoundScreen(),
        ),
      ),
    );
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
            ListTile(title: const Text('Shop'), leading: const Icon(Icons.store), onTap: () => Navigator.pushNamed(context, '/client/shop')),
            ListTile(title: const Text('Bestsellers'), leading: const Icon(Icons.star), onTap: () => Navigator.pushNamed(context, '/bestseller')),
            const Divider(),
            FutureBuilder<bool>(
              future: Provider.of<AuthService>(context, listen: false).isAdmin(),
              builder: (ctx, snap) {
                final isAdmin = snap.data == true;
                if (!isAdmin) return const SizedBox.shrink();
                return Column(children: [
                  ListTile(title: const Text('Manage Products'), leading: const Icon(Icons.admin_panel_settings), onTap: () => Navigator.pushNamed(context, '/admin/manageproduct')),
                  ListTile(title: const Text('Manage Orders'), leading: const Icon(Icons.list_alt), onTap: () => Navigator.pushNamed(context, '/admin/manageorders')),
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
