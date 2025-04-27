import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UnitListScreen extends StatefulWidget {
  final String token;

  const UnitListScreen({super.key, required this.token});

  @override
  State<UnitListScreen> createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  List<dynamic> units = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUnits();
  }

  Future<void> fetchUnits() async {
    final url = Uri.parse('http://192.168.2.100:8000/api/unit');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          units = List.from(data['data'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'خطا در دریافت اطلاعات';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطا: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست واحدها'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (errorMessage != null)
              ? Center(child: Text(errorMessage!))
              : units.isEmpty
                  ? const Center(child: Text('هیچ واحدی یافت نشد.'))
                  : ListView.builder(
                      itemCount: units.length,
                     itemBuilder: (context, index) {
                        if (index >= units.length) {
                          return const SizedBox(); // یا یک ویجت خالی
                        }
                        final unit = units[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.apartment_outlined),
                            title: Text(
                              (unit['name'] ?? 'بدون نام').toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
