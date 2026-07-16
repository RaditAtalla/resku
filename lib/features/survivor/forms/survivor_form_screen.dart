import 'package:flutter/material.dart';

// Screen where survivors input their details and status to be shared in the mesh.
class SurvivorFormScreen extends StatefulWidget {
  const SurvivorFormScreen({super.key});

  @override
  State<SurvivorFormScreen> createState() => _SurvivorFormScreenState();
}

class _SurvivorFormScreenState extends State<SurvivorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _status = 'Safe';
  final List<String> _needs = [];

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Logic to create and save SurvivorRecord
      debugPrint('Status update for $_name: status=$_status, needs=$_needs');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status Broadcast Updated locally!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Survivor Status'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name / Anonymous ID'),
              validator: (val) => val == null || val.isEmpty ? 'Please enter an identifier' : null,
              onSaved: (val) => _name = val ?? '',
            ),
            const SizedBox(height: 16),
            const Text('Triage Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _status,
              items: ['Safe', 'Injured', 'Critical']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 16),
            const Text('Needed Resources:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...['Food & Water', 'First Aid / Medical', 'Shelter', 'Tools / Warmth'].map((need) {
              return CheckboxListTile(
                title: Text(need),
                value: _needs.contains(need),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _needs.add(need);
                    } else {
                      _needs.remove(need);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Broadcast Status to Mesh'),
            ),
          ],
        ),
      ),
    );
  }
}
