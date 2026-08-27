// phone_lookup_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class PhoneLookupPage extends StatefulWidget {
  final String sessionKey;

  const PhoneLookupPage({
    super.key,
    required this.sessionKey,
  });

  @override
  State<PhoneLookupPage> createState() => _PhoneLookupPageState();
}

class _PhoneLookupPageState extends State<PhoneLookupPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  Map<String, String>? _phoneData;
  String? _errorMessage;

  // --- TEMA BIRU MUDA ---
  final Color primaryDark = Colors.black;
  final Color primaryWhite = Colors.white;
  final Color accentBlue = const Color(0xFF64B5F6);
  final Color primaryBlue = const Color(0xFF1A3A5C);
  final Color cardDark = const Color(0xFF0A1628);

  Future<void> _lookupPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = "Masukkan nomor telepon";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _phoneData = null;
    });

    try {
      final url = Uri.parse("https://free-lookup.net/$phone");
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body;
        
        Map<String, String> info = {};
        
        final divPattern = RegExp(r'<div class="report-summary__item">[\s\S]*?<div class="report-summary__label">(.*?)<\/div>[\s\S]*?<div class="report-summary__value">(.*?)<\/div>', caseSensitive: false);
        
        final matches = divPattern.allMatches(body);
        for (var match in matches) {
          if (match.groupCount >= 2) {
            String key = _cleanHtml(match.group(1) ?? '');
            String value = _cleanHtml(match.group(2) ?? '');
            if (key.isNotEmpty && value.isNotEmpty && value != "Not found" && value != "-") {
              info[key] = value;
            }
          }
        }
        
        if (info.isEmpty) {
          final tablePattern = RegExp(r'<tr>[\s\S]*?<td>(.*?)<\/td>[\s\S]*?<td>(.*?)<\/td>[\s\S]*?<\/tr>', caseSensitive: false);
          final tableMatches = tablePattern.allMatches(body);
          for (var match in tableMatches) {
            if (match.groupCount >= 2) {
              String key = _cleanHtml(match.group(1) ?? '');
              String value = _cleanHtml(match.group(2) ?? '');
              if (key.isNotEmpty && value.isNotEmpty && value != "Not found" && value != "-") {
                info[key] = value;
              }
            }
          }
        }
        
        if (info.isNotEmpty) {
          setState(() {
            _phoneData = info;
          });
        } else {
          setState(() {
            _errorMessage = "Data tidak ditemukan untuk nomor ini";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal terhubung ke server";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Koneksi gagal: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _cleanHtml(String text) {
    String cleaned = text.replaceAll(RegExp(r'<[^>]*>'), '');
    cleaned = cleaned.replaceAll('&nbsp;', ' ');
    cleaned = cleaned.replaceAll('&amp;', '&');
    cleaned = cleaned.replaceAll('&lt;', '<');
    cleaned = cleaned.replaceAll('&gt;', '>');
    cleaned = cleaned.replaceAll('&quot;', '"');
    cleaned = cleaned.replaceAll('&#39;', "'");
    cleaned = cleaned.trim();
    return cleaned;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar("$label disalin ke clipboard");
  }

  void _copyAllData() {
    if (_phoneData == null) return;
    final allData = _phoneData!.entries.map((e) => "${e.key}: ${e.value}").join('\n');
    Clipboard.setData(ClipboardData(text: allData));
    _showSnackBar("Semua data disalin");
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: accentBlue),
        ),
      ),
    );
  }

  IconData _getInfoIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('phone') || lower.contains('number')) return Icons.phone_android;
    if (lower.contains('country')) return Icons.public;
    if (lower.contains('city') || lower.contains('location')) return Icons.location_city;
    if (lower.contains('carrier') || lower.contains('operator')) return Icons.signal_cellular_alt;
    if (lower.contains('type')) return Icons.devices;
    if (lower.contains('valid')) return Icons.check_circle;
    if (lower.contains('spam')) return Icons.warning;
    if (lower.contains('time') || lower.contains('zone')) return Icons.access_time;
    return Icons.info;
  }

  Color _getInfoColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('valid')) return Colors.green;
    if (lower.contains('spam') || lower.contains('fraud')) return Colors.grey;
    return accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: const Text(
          'PHONE LOOKUP',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryDark,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_phoneData != null)
            IconButton(
              icon: const Icon(Icons.copy_all, color: Color(0xFF64B5F6)),
              onPressed: _copyAllData,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Input Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentBlue.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: accentBlue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _phoneController,
                      style: TextStyle(color: primaryWhite, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Masukkan Nomor Telepon',
                        labelStyle: TextStyle(color: primaryWhite.withOpacity(0.7)),
                        hintText: 'Contoh: 6281234567890 atau +6281234567890',
                        hintStyle: TextStyle(color: primaryWhite.withOpacity(0.4)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentBlue.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentBlue, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: primaryDark,
                        prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF64B5F6)),
                        suffixIcon: _isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: accentBlue,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.phone,
                      onSubmitted: (_) => _lookupPhone(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _lookupPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: primaryWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isLoading ? Icons.hourglass_top : Icons.search, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isLoading ? 'MEMPROSES...' : 'LOOKUP PHONE',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentBlue),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: accentBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: primaryWhite, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Result Card
              if (_phoneData != null && _phoneData!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentBlue.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                                ),
                                child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DATA DITEMUKAN',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    '${_phoneData!.length} informasi ditemukan',
                                    style: TextStyle(color: primaryWhite.withOpacity(0.5), fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ..._phoneData!.entries.map((entry) => _buildDetailRow(entry.key, entry.value)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final icon = _getInfoIcon(label);
    final color = _getInfoColor(label);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: primaryWhite.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, color: color, size: 18),
            onPressed: () => _copyToClipboard(value, label),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
          ),
        ],
      ),
    );
  }
}