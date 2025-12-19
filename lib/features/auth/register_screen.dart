import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../home/main_wrapper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common Fields
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _instIdCtrl = TextEditingController(
    text: "demo_university",
  ); // Default for prototype

  // Role Specific
  String _selectedRole = 'student';

  // Student Fields
  final _studentIdCtrl = TextEditingController();
  final _programCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  // Faculty Fields
  final _employeeIdCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();

  // Shared
  final _deptCtrl = TextEditingController();

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      Map<String, dynamic> roleInfo = {};

      if (_selectedRole == 'student') {
        roleInfo = {
          "student_id": _studentIdCtrl.text.trim(),
          "program": _programCtrl.text.trim(),
          "year": int.tryParse(_yearCtrl.text.trim()) ?? 1,
          "department": _deptCtrl.text.trim(),
        };
      } else if (_selectedRole == 'faculty') {
        roleInfo = {
          "employee_id": _employeeIdCtrl.text.trim(),
          "department": _deptCtrl.text.trim(),
          "designation": _designationCtrl.text.trim(),
          "specialization": _specializationCtrl.text.trim(),
        };
      }

      await auth.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        role: _selectedRole,
        institutionId: _instIdCtrl.text.trim(),
        roleInfo: roleInfo,
      );

      if (mounted) {
        if (auth.status == AuthStatus.authenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainWrapper()),
            (route) => false,
          );
        } else if (auth.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.errorMessage ?? 'Registration failed'),
              backgroundColor: AppColors.primaryVariant,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthProvider>().status == AuthStatus.authenticating;

    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Basic Information",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _emailCtrl,
                  "Email",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _passCtrl,
                  "Password",
                  isObscure: true,
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(_firstNameCtrl, "First Name"),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(_lastNameCtrl, "Last Name"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(_instIdCtrl, "Institution ID"),

                const SizedBox(height: 24),
                Text(
                  "Role Selection",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: ['student', 'faculty', 'admin'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),

                const SizedBox(height: 24),
                if (_selectedRole != 'admin') ...[
                  Text(
                    _selectedRole == 'student'
                        ? "Student Details"
                        : "Faculty Details",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_selectedRole == 'student') ...[
                    _buildTextField(_studentIdCtrl, "Student ID"),
                    const SizedBox(height: 12),
                    _buildTextField(_programCtrl, "Program (e.g. CS)"),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _yearCtrl,
                      "Year",
                      keyboardType: TextInputType.number,
                    ),
                  ] else ...[
                    _buildTextField(_employeeIdCtrl, "Employee ID"),
                    const SizedBox(height: 12),
                    _buildTextField(_designationCtrl, "Designation"),
                    const SizedBox(height: 12),
                    _buildTextField(_specializationCtrl, "Specialization"),
                  ],
                  const SizedBox(height: 12),
                  _buildTextField(_deptCtrl, "Department"),
                ],

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : _handleRegister,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text("Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    bool isObscure = false,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: isObscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }
}
