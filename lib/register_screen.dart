import 'package:flutter/material.dart';

class AdminSetupScreen extends StatefulWidget {
  final Function(String businessName, List<Map<String, String>> employees, Map<String, bool> toggles) onSetupComplete;

  const AdminSetupScreen({Key? key, required this.onSetupComplete}) : super(key: key);

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _businessNameController = TextEditingController();
  final List<Map<String, String>> _employees = [];
  final _employeeNameController = TextEditingController();
  final _employeeEmailController = TextEditingController();

  bool _requirePhoto = false;
  bool _requireLocation = false;
  bool _enableTaskEntry = false;

  void _addEmployee() {
    final name = _employeeNameController.text.trim();
    final email = _employeeEmailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and email')),
      );
      return;
    }

    setState(() {
      _employees.add({'name': name, 'email': email});
      _employeeNameController.clear();
      _employeeEmailController.clear();
    });
  }

  void _removeEmployee(int index) {
    setState(() {
      _employees.removeAt(index);
    });
  }

  void _submit() {
    if (_businessNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter business name')),
      );
      return;
    }
    if (_employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one employee')),
      );
      return;
    }

    final toggles = {
      'requirePhoto': _requirePhoto,
      'requireLocation': _requireLocation,
      'enableTaskEntry': _enableTaskEntry,
    };

    widget.onSetupComplete(
      _businessNameController.text.trim(),
      _employees,
      toggles,
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _employeeNameController.dispose();
    _employeeEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Business'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Name', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(hintText: 'Enter your business name'),
            ),
            const SizedBox(height: 20),

            const Text('Add Initial Employees', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _employeeNameController,
                    decoration: const InputDecoration(hintText: 'Employee Name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _employeeEmailController,
                    decoration: const InputDecoration(hintText: 'Employee Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: _addEmployee,
                  tooltip: 'Add Employee',
                ),
              ],
            ),

            const SizedBox(height: 12),
            ..._employees.asMap().entries.map((entry) {
              int idx = entry.key;
              Map<String, String> emp = entry.value;
              return ListTile(
                title: Text(emp['name'] ?? ''),
                subtitle: Text(emp['email'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeEmployee(idx),
                ),
              );
            }).toList(),

            const Divider(height: 40),

            const Text('Setup Options', style: TextStyle(fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('Require daily photo'),
              value: _requirePhoto,
              onChanged: (val) => setState(() => _requirePhoto = val),
            ),
            SwitchListTile(
              title: const Text('Require location check-in'),
              value: _requireLocation,
              onChanged: (val) => setState(() => _requireLocation = val),
            ),
            SwitchListTile(
              title: const Text('Enable task entry'),
              value: _enableTaskEntry,
              onChanged: (val) => setState(() => _enableTaskEntry = val),
            ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Create Business Sheet & Start'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
