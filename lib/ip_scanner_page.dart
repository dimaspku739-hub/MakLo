// ip_scanner_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class IpScannerPage extends StatefulWidget {
  final String sessionKey;

  const IpScannerPage({
    super.key,
    required this.sessionKey,
  });

  @override
  State<IpScannerPage> createState() => _IpScannerPageState();
}

class _IpScannerPageState extends State<IpScannerPage> {
  final TextEditingController _ipController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _ipData;
  String? _errorMessage;
  String _myPublicIp = "";

  // --- TEMA BIRU MUDA ---
  final Color primaryDark = Colors.black;
  final Color primaryWhite = Colors.white;
  final Color accentBlue = const Color(0xFF64B5F6);
  final Color primaryBlue = const Color(0xFF1A3A5C);
  final Color cardDark = const Color(0xFF0A1628);

  @override
  void initState() {
    super.initState();
    _getMyIp();
  }

  Future<void> _getMyIp() async {
    try {
      final response = await http.get(
        Uri.parse("https://api.ipify.org?format=json"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _myPublicIp = data['ip'];
          _ipController.text = _myPublicIp;
        });
      }
    } catch (e) {
      print("Error getting IP: $e");
    }
  }

  Future<void> _checkIp() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() {
        _errorMessage = "Masukkan alamat IP";
      });
      return;
    }

    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) {
      setState(() {
        _errorMessage = "Format IP tidak valid (contoh: 8.8.8.8)";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _ipData = null;
    });

    try {
      final url = Uri.parse("http://ip-api.com/json/$ip?fields=status,country,regionName,city,isp,org,as,query,lat,lon,timezone,mobile,proxy,hosting");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _ipData = data;
          });
        } else {
          setState(() {
            _errorMessage = "IP tidak ditemukan atau tidak valid";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data IP";
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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar("$label disalin ke clipboard");
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

  IconData _getFlagIcon(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'ID': return Icons.location_on;
      case 'US': return Icons.location_on;
      case 'GB': return Icons.location_on;
      case 'JP': return Icons.location_on;
      case 'CN': return Icons.location_on;
      default: return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: const Text(
          'IP SCANNER',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryDark,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ipController,
                            style: TextStyle(color: primaryWhite, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Masukkan Alamat IP',
                              labelStyle: TextStyle(color: primaryWhite.withOpacity(0.7)),
                              hintText: 'Contoh: 8.8.8.8',
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
                              prefixIcon: const Icon(Icons.dns, color: Color(0xFF64B5F6)),
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
                            onSubmitted: (_) => _checkIp(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            _ipController.text = _myPublicIp;
                            _checkIp();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkIp,
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
                              _isLoading ? 'MEMPROSES...' : 'CEK IP',
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
              if (_ipData != null) ...[
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // IP Address Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accentBlue.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INFORMASI IP',
                                style: TextStyle(
                                  color: accentBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.dns,
                                label: "Alamat IP",
                                value: _ipData!['query']?.toString() ?? '-',
                                showCopyButton: true,
                              ),
                              _buildInfoRow(
                                icon: Icons.public,
                                label: "Negara",
                                value: _ipData!['country']?.toString() ?? '-',
                              ),
                              _buildInfoRow(
                                icon: Icons.location_city,
                                label: "Region / Kota",
                                value: "${_ipData!['regionName']?.toString() ?? '-'} / ${_ipData!['city']?.toString() ?? '-'}",
                              ),
                              _buildInfoRow(
                                icon: Icons.map,
                                label: "Koordinat",
                                value: "Lat: ${_ipData!['lat']?.toString() ?? '-'}, Lon: ${_ipData!['lon']?.toString() ?? '-'}",
                              ),
                              _buildInfoRow(
                                icon: Icons.access_time,
                                label: "Zona Waktu",
                                value: _ipData!['timezone']?.toString() ?? '-',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Provider Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accentBlue.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INFORMASI PROVIDER',
                                style: TextStyle(
                                  color: accentBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.business,
                                label: "ISP",
                                value: _ipData!['isp']?.toString() ?? '-',
                                showCopyButton: true,
                              ),
                              _buildInfoRow(
                                icon: Icons.devices,
                                label: "Organisasi",
                                value: _ipData!['org']?.toString() ?? '-',
                              ),
                              _buildInfoRow(
                                icon: Icons.router,
                                label: "AS",
                                value: _ipData!['as']?.toString() ?? '-',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Status Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accentBlue.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS',
                                style: TextStyle(
                                  color: accentBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildStatusRow(
                                icon: Icons.phone_android,
                                label: "Mobile",
                                value: _ipData!['mobile'] == true,
                              ),
                              _buildStatusRow(
                                icon: Icons.security,
                                label: "Proxy",
                                value: _ipData!['proxy'] == true,
                              ),
                              _buildStatusRow(
                                icon: Icons.cloud,
                                label: "Hosting",
                                value: _ipData!['hosting'] == true,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool showCopyButton = false,
  }) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryWhite.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentBlue, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: primaryWhite.withOpacity(0.7),
                    fontSize: 12,
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
          if (showCopyButton)
            IconButton(
              icon: Icon(Icons.copy, color: accentBlue, size: 18),
              onPressed: () => _copyToClipboard(value, label),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required bool value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryWhite.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentBlue, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: primaryWhite,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: value ? Colors.grey.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value ? Colors.white70 : Colors.greenAccent,
                width: 0.5,
              ),
            ),
            child: Text(
              value ? "YA" : "TIDAK",
              style: TextStyle(
                color: value ? Colors.white70 : Colors.greenAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}