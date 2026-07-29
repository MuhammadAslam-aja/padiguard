import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../services/api_mock_data.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final ApiMockData _mockDb = ApiMockData();
  List<Map<String, dynamic>> _usersList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (AppConstants.useMockApi) {
      if (mounted) {
        setState(() {
          _usersList = _mockDb.getAllUsers();
        });
      }
      return;
    }
    
    setState(() { _isLoading = true; });
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.get('api/admin/users');
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _usersList = List<Map<String, dynamic>>.from(response.data['users']);
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _addUser(String name, String email, String password, String role) async {
    if (AppConstants.useMockApi) {
      final success = _mockDb.adminAddUser(name, email, password, role);
      if (success) {
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User baru berhasil ditambahkan.'), backgroundColor: AppTheme.successColor),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email sudah terdaftar!'), backgroundColor: AppTheme.errorColor),
        );
      }
      return;
    }
    
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.post(
        'api/admin/users',
        data: {'name': name, 'email': email, 'password': password, 'role': role},
      );
      if (response.statusCode == 201 && response.data['success'] == true) {
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User baru berhasil ditambahkan.'), backgroundColor: AppTheme.successColor),
          );
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menambahkan user.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _editUser(String id, String name, String email, String role, String password) async {
    if (AppConstants.useMockApi) {
      final success = _mockDb.adminUpdateUser(id, name, email, role, password.isNotEmpty ? password : null);
      if (success) {
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data user berhasil diperbarui.'), backgroundColor: AppTheme.successColor),
        );
      }
      return;
    }
    
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.put(
        'api/admin/users/$id',
        data: {
          'name': name,
          'email': email,
          'role': role,
          if (password.isNotEmpty) 'password': password,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data user berhasil diperbarui.'), backgroundColor: AppTheme.successColor),
          );
        }
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui user.'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _deleteUser(String id) async {
    if (AppConstants.useMockApi) {
      final success = _mockDb.deleteUser(id);
      if (success) {
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User berhasil dihapus.'), backgroundColor: AppTheme.successColor),
        );
      }
      return;
    }
    
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.delete('api/admin/users/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User berhasil dihapus.'), backgroundColor: AppTheme.successColor),
          );
        }
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus user.'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  ImageProvider? _getUserAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (kIsWeb || avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://') || avatarUrl.startsWith('blob:')) {
      return NetworkImage(avatarUrl);
    }
    return FileImage(File(avatarUrl));
  }
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'petani';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Tambah User Baru', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email tidak boleh kosong';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                    validator: (val) => val == null || val.isEmpty ? 'Password tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.supervisor_account_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'petani', child: Text('Petani')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedRole = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final pass = passwordController.text;
                final role = selectedRole;
                
                Navigator.of(context, rootNavigator: true).pop();
                _addUser(name, email, pass, role);
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    String selectedRole = user['role'];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Data User', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email tidak boleh kosong';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Baru (Opsional)',
                      prefixIcon: Icon(Icons.lock_outline),
                      helperText: 'Kosongkan jika tidak ingin diubah',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.supervisor_account_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'petani', child: Text('Petani')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedRole = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final userId = user['id'];
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final role = selectedRole;
                final pass = passwordController.text;
                
                Navigator.of(context, rootNavigator: true).pop();
                _editUser(userId, name, email, role, pass);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus User', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus user "${user['name']}"? Semua data deteksinya juga akan terpengaruh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              final userId = user['id'];
              Navigator.of(context, rootNavigator: true).pop();
              _deleteUser(userId);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allUsers = _usersList;

    // Filter by search query & role
    final filteredUsers = allUsers.where((user) {
      final matchesSearch = user['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kelola User'),
            Text(
              'by Tirza Marsena (6150101220009)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: isDark ? const Color(0xFF4CAF50) : AppTheme.primaryLight,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Cari nama atau email...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Users List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                          Text('User tidak ditemukan', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isUserAdmin = user['role'] == 'admin';
                        final regDate = DateTime.parse(user['createdAt']);
                        final formattedReg = DateFormat('dd MMM yyyy').format(regDate);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F5E9),
                              backgroundImage: _getUserAvatar(user['avatar']),
                            ),
                            title: Text(
                              user['name'],
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['email'], style: const TextStyle(fontSize: 11)),
                                const SizedBox(height: 2),
                                Text('Terdaftar: $formattedReg', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isUserAdmin
                                        ? AppTheme.accentWarning.withOpacity(0.12)
                                        : AppTheme.successColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user['role'].toUpperCase(),
                                    style: TextStyle(
                                      color: isUserAdmin ? AppTheme.accentWarning : AppTheme.successColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.edit, size: 18, color: Colors.grey.shade500),
                                  onPressed: () => _showEditUserDialog(user),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                                  onPressed: () => _showDeleteConfirmation(user),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

}
