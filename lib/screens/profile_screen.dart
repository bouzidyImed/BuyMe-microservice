import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final data = await Provider.of<AuthService>(context, listen: false).getCurrentUser();
      setState(() {
        _user = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final user = _user!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(user['email'] ?? ''),
          const SizedBox(height: 8),
          Text('Phone: ${user['phone'] ?? ''}'),
          const SizedBox(height: 8),
          Text('Address: ${user['address'] ?? ''}, ${user['city'] ?? ''}, ${user['country'] ?? ''} ${user['zip'] ?? ''}'),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('My Orders'),
            onTap: () {
              Navigator.pushNamed(context, '/my-orders');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Provider.of<AuthService>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
