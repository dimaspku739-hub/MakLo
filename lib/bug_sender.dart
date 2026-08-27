// bug_sender.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<dynamic> senderList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  
  // Controller untuk drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- MODERN LIGHT BLUE THEME ---
  static const Color bgDark = Color(0xFF000000);
  static const Color accentBlue = Color(0xFF4FC3F7);
  static const Color darkBlue = Color(0xFF0288D1);
  static const Color softBlue = Color(0xFF29B6F6);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFF9E9E9E);

  Color get glassPrimary => const Color(0x1AFFFFFF);
  Color get glassSecondary => const Color(0x0DFFFFFF);

  LinearGradient get blueGradient => const LinearGradient(
        colors: [Color(0xFF01579B), Color(0xFF4FC3F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get secondaryGradient => const LinearGradient(
        colors: [Color(0xFF01579B), Color(0xFF4FC3F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  bool get canAddGlobal =>
      ["owner", "developer"].contains(widget.role.toLowerCase());

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchSenders();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSenders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final res = await http.get(
        Uri.parse("$apiBaseUrl/mySender?key=${widget.sessionKey}"),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["valid"] == true) {
        final connections = data["connections"] as List<dynamic>? ?? [];
        connections.sort((a, b) {
          final ag = a["isGlobal"] == true ? 0 : 1;
          final bg = b["isGlobal"] == true ? 0 : 1;
          if (ag != bg) return ag.compareTo(bg);
          return (a["sessionName"] ?? "").toString().compareTo(
                (b["sessionName"] ?? "").toString(),
              );
        });
        setState(() => senderList = connections);
      } else {
        setState(
          () => errorMessage = data["message"] ?? "Failed to fetch senders",
        );
      }
    } catch (e) {
      setState(() => errorMessage = "Connection failed: $e");
    } finally {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchSenders();
  }

  Future<void> _addSender(String number, bool isGlobal) async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          "$apiBaseUrl/getPairing?key=${widget.sessionKey}&number=$number&global=${isGlobal ? 1 : 0}",
        ),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["valid"] == true) {
        _showPairingDialog(number, data["pairingCode"].toString());
        _showSnackBar("Pairing code generated!", false);
      } else {
        _showSnackBar(data["message"] ?? "Failed to generate pairing code", true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", true);
    } finally {
      setState(() => isLoading = false);
      await _fetchSenders();
    }
  }

  Future<void> _deleteSender(String id, bool isGlobal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _buildDeleteDialog(isGlobal),
    );
    if (ok != true) return;

    setState(() => isLoading = true);
    try {
      final res = await http.delete(
        Uri.parse(
          "$apiBaseUrl/deleteSender?key=${widget.sessionKey}&id=$id&scope=${isGlobal ? 'global' : 'private'}",
        ),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["valid"] == true) {
        _showSnackBar("Sender deleted successfully!", false);
        await _fetchSenders();
      } else {
        _showSnackBar(data["message"] ?? "Failed to delete sender", true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildDeleteDialog(bool isGlobal) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgDark, bgDark.withOpacity(0.95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.white70, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                "Confirm Delete",
                style: TextStyle(
                  color: primaryWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isGlobal
                    ? "Global sender ini akan dihapus untuk semua user. This action cannot be undone."
                    : "Are you sure you want to delete this sender? This action cannot be undone.",
                style: const TextStyle(color: softGrey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Center(
                          child: Text(
                            "CANCEL",
                            style:
                                TextStyle(color: softGrey, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text(
                            "DELETE",
                            style: TextStyle(
                                color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    final phoneController = TextEditingController();
    bool isGlobal = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: TweenAnimationBuilder(
                duration: const Duration(milliseconds: 300),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bgDark, bgDark.withOpacity(0.95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: accentBlue.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: accentBlue.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: blueGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentBlue.withOpacity(0.4),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.phone_android,
                            color: primaryWhite, size: 28),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Add New Sender",
                        style: TextStyle(
                          color: primaryWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Enter phone number to add new WhatsApp sender",
                        style: TextStyle(color: softGrey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: glassSecondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryWhite.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: primaryWhite, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "62xxxxxxxxxx",
                            hintStyle: TextStyle(color: softGrey.withOpacity(0.5)),
                            prefixIcon:
                                const Icon(Icons.phone, color: accentBlue, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                      if (canAddGlobal) ...[
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: glassSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryWhite.withOpacity(0.1)),
                          ),
                          child: SwitchListTile(
                            value: isGlobal,
                            onChanged: (v) => setLocal(() => isGlobal = v),
                            title: const Text(
                              "Global Sender",
                              style: TextStyle(color: primaryWhite),
                            ),
                            subtitle: const Text(
                              "Tambah global sender untuk semua role",
                              style: TextStyle(color: softGrey, fontSize: 12),
                            ),
                            activeColor: accentBlue,
                            inactiveThumbColor: Colors.grey,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                child: const Center(
                                  child: Text(
                                    "CANCEL",
                                    style: TextStyle(
                                        color: softGrey, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final number = phoneController.text.trim();
                                if (number.isEmpty) {
                                  _showSnackBar("Please enter phone number", true);
                                  return;
                                }
                                if (isGlobal && !canAddGlobal) {
                                  _showSnackBar(
                                    "Hanya owner & developer yang dapat menambahkan Global Sender.",
                                    true,
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                await _addSender(number, isGlobal);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: blueGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentBlue.withOpacity(0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    "ADD SENDER",
                                    style: TextStyle(
                                        color: primaryWhite, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPairingDialog(String number, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgDark, bgDark.withOpacity(0.95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: accentBlue.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accentBlue.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: blueGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentBlue.withOpacity(0.4),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.qr_code_2, color: primaryWhite, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Pairing Required",
                  style: TextStyle(
                    color: primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Number: $number",
                  style: const TextStyle(color: softGrey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentBlue.withOpacity(0.1), darkBlue.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Pairing Code",
                        style: TextStyle(color: softGrey, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentBlue, width: 2),
                        ),
                        child: SelectableText(
                          code,
                          style: const TextStyle(
                            color: accentBlue,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          _showSnackBar("Code copied to clipboard!", false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentBlue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.copy, color: accentBlue, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                "COPY CODE",
                                style: TextStyle(
                                    color: accentBlue, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Center(
                            child: Text(
                              "CLOSE",
                              style: TextStyle(
                                  color: softGrey, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _refreshSenders();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: blueGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accentBlue.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "REFRESH",
                              style: TextStyle(
                                  color: primaryWhite, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: primaryWhite,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: primaryWhite, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.grey.withOpacity(0.9) : accentBlue.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSenderCard(Map<String, dynamic> sender, int index) {
    final name = sender["sessionName"] ?? "WhatsApp Sender";
    final id = (sender["id"] ?? name).toString();
    final isGlobal = sender["isGlobal"] == true;
    final canDelete = sender["canDelete"] != false;
    final isEven = index % 2 == 0;

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEven
                ? [glassPrimary, glassSecondary]
                : [glassSecondary, glassPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryWhite.withOpacity(0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: blueGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentBlue.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      isGlobal ? Icons.public : Icons.phone_android,
                      color: primaryWhite,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: primaryWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ID: $id",
                          style: const TextStyle(color: softGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isGlobal ? accentBlue : darkBlue).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: (isGlobal ? accentBlue : darkBlue).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isGlobal ? "GLOBAL" : "PRIVATE",
                          style: TextStyle(
                            color: isGlobal ? accentBlue : darkBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _refreshSenders,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentBlue.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh, color: accentBlue, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "REFRESH",
                              style: TextStyle(
                                  color: accentBlue, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: canDelete ? () => _deleteSender(id, isGlobal) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: canDelete
                              ? Colors.grey.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: canDelete
                                ? Colors.grey.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              canDelete ? Icons.delete_outline : Icons.lock_outline,
                              color: canDelete ? Colors.white70 : softGrey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              canDelete ? "DELETE" : "LOCKED",
                              style: TextStyle(
                                color: canDelete ? Colors.white70 : softGrey,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [glassPrimary, glassSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryWhite.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: blueGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: primaryWhite, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Global sender hanya bisa ditambah owner/developer, tapi semua role bisa memakai global sender.",
              style: TextStyle(color: softGrey, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 600),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentBlue.withOpacity(0.1), darkBlue.withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentBlue.withOpacity(0.2)),
                ),
                child: const Icon(Icons.phone_iphone, color: accentBlue, size: 70),
              ),
              const SizedBox(height: 28),
              const Text(
                "No Senders Found",
                style: TextStyle(
                    color: primaryWhite, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Add your first WhatsApp sender to get started",
                style: TextStyle(color: softGrey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: _showAddDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: blueGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentBlue.withOpacity(0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: primaryWhite, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        "ADD NEW SENDER",
                        style: TextStyle(
                          color: primaryWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Colors.white70, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              "Failed to Load",
              style: TextStyle(
                  color: primaryWhite, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage ?? "Unknown error occurred",
              style: const TextStyle(color: softGrey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _refreshSenders,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: blueGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentBlue.withOpacity(0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, color: primaryWhite, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      "TRY AGAIN",
                      style: TextStyle(
                        color: primaryWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== DRAWER WIDGET ======
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: bgDark,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            // Header Drawer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: blueGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryWhite.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryWhite.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.bug_report,
                          color: primaryWhite,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.username,
                            style: const TextStyle(
                              color: primaryWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.role.toUpperCase(),
                            style: TextStyle(
                              color: primaryWhite.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryWhite.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.smartphone,
                          color: primaryWhite,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Total: ${senderList.length} Senders",
                          style: const TextStyle(
                            color: primaryWhite,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // Menu Item: All Senders
                  _buildDrawerItem(
                    icon: Icons.list_alt,
                    title: "All Senders",
                    subtitle: "${senderList.length} senders available",
                    onTap: () => _scaffoldKey.currentState?.closeDrawer(),
                  ),
                  
                  const Divider(
                    color: Colors.white24,
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  
                  // Daftar Sender
                  if (senderList.isNotEmpty)
                    Column(
                      children: senderList.map((sender) {
                        final name = sender["sessionName"] ?? "WhatsApp Sender";
                        final isGlobal = sender["isGlobal"] == true;
                        final id = (sender["id"] ?? name).toString();
                        
                        return _buildDrawerSenderItem(
                          name: name,
                          id: id,
                          isGlobal: isGlobal,
                          onTap: () {
                            _scaffoldKey.currentState?.closeDrawer();
                            _showSenderDetail(sender);
                          },
                        );
                      }).toList(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox,
                              color: softGrey.withOpacity(0.3),
                              size: 50,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No senders found",
                              style: TextStyle(
                                color: softGrey.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const Divider(
                    color: Colors.white24,
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  
                  // Menu Item: Add Sender
                  _buildDrawerItem(
                    icon: Icons.add_circle_outline,
                    title: "Add New Sender",
                    subtitle: canAddGlobal ? "Add private or global sender" : "Add private sender only",
                    onTap: () {
                      _scaffoldKey.currentState?.closeDrawer();
                      _showAddDialog();
                    },
                  ),
                  
                  // Menu Item: Refresh
                  _buildDrawerItem(
                    icon: Icons.refresh,
                    title: "Refresh List",
                    subtitle: "Update sender list",
                    onTap: () {
                      _scaffoldKey.currentState?.closeDrawer();
                      _refreshSenders();
                    },
                  ),
                  
                  const Divider(
                    color: Colors.white24,
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  
                  // Menu Item: Back
                  _buildDrawerItem(
                    icon: Icons.arrow_back,
                    title: "Back to Dashboard",
                    subtitle: "Return to main menu",
                    onTap: () {
                      _scaffoldKey.currentState?.closeDrawer();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: primaryWhite.withOpacity(0.05),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: accentBlue.withOpacity(0.5),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Bug Sender v1.0",
                    style: TextStyle(
                      color: softGrey.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: accentBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: primaryWhite,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: softGrey.withOpacity(0.6),
                fontSize: 12,
              ),
            )
          : null,
      onTap: onTap,
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white24,
        size: 20,
      ),
    );
  }

  Widget _buildDrawerSenderItem({
    required String name,
    required String id,
    required bool isGlobal,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (isGlobal ? accentBlue : darkBlue).withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isGlobal ? Icons.public : Icons.phone_android,
          color: isGlobal ? accentBlue : darkBlue,
          size: 16,
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: primaryWhite,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isGlobal ? "Global • ID: $id" : "Private • ID: $id",
        style: TextStyle(
          color: softGrey.withOpacity(0.5),
          fontSize: 10,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isGlobal ? accentBlue : darkBlue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isGlobal ? accentBlue : darkBlue).withOpacity(0.2),
          ),
        ),
        child: Text(
          isGlobal ? "GLOBAL" : "PRIVATE",
          style: TextStyle(
            color: isGlobal ? accentBlue : darkBlue,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  void _showSenderDetail(Map<String, dynamic> sender) {
    final name = sender["sessionName"] ?? "WhatsApp Sender";
    final id = (sender["id"] ?? name).toString();
    final isGlobal = sender["isGlobal"] == true;
    final canDelete = sender["canDelete"] != false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgDark, bgDark.withOpacity(0.95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: accentBlue.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: blueGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentBlue.withOpacity(0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Icon(
                  isGlobal ? Icons.public : Icons.phone_android,
                  color: primaryWhite,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  color: primaryWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (isGlobal ? accentBlue : darkBlue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isGlobal ? "GLOBAL SENDER" : "PRIVATE SENDER",
                  style: TextStyle(
                    color: isGlobal ? accentBlue : darkBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: glassSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryWhite.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "ID",
                          style: TextStyle(color: softGrey, fontSize: 12),
                        ),
                        Text(
                          id,
                          style: const TextStyle(
                            color: primaryWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Type",
                          style: TextStyle(color: softGrey, fontSize: 12),
                        ),
                        Text(
                          isGlobal ? "Global" : "Private",
                          style: const TextStyle(
                            color: primaryWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Created By",
                          style: TextStyle(color: softGrey, fontSize: 12),
                        ),
                        Text(
                          sender["createdBy"] ?? "Unknown",
                          style: const TextStyle(
                            color: primaryWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Center(
                          child: Text(
                            "CLOSE",
                            style: TextStyle(
                              color: softGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (canDelete) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _deleteSender(id, isGlobal);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: const Center(
                            child: Text(
                              "DELETE",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: accentBlue, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: blueGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accentBlue.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Text(
            "BUG SENDER",
            style: TextStyle(
              color: primaryWhite,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: IconButton(
              icon: AnimatedRotation(
                turns: isRefreshing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: const Icon(Icons.menu, color: accentBlue, size: 20),
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [accentBlue.withOpacity(0.15), bgDark, bgDark],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: isLoading && senderList.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: accentBlue,
                      strokeWidth: 3,
                    ),
                  )
                : errorMessage != null && senderList.isEmpty
                ? _buildErrorState()
                : Column(
                    children: [
                      _buildInfoBanner(),
                      Expanded(
                        child: senderList.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: accentBlue,
                                backgroundColor: glassSecondary,
                                onRefresh: _refreshSenders,
                                child: ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: senderList.length,
                                  itemBuilder: (context, index) => _buildSenderCard(
                                    Map<String, dynamic>.from(senderList[index]),
                                    index,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Custom Grid Painter for background
class _GridPainter extends CustomPainter {
  static const Color accentBlue = Color(0xFF4FC3F7);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final accentPaint = Paint()
      ..color = accentBlue.withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += gridSize * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }

    for (double y = 0; y <= size.height; y += gridSize * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }

    final dotPaint = Paint()
      ..color = accentBlue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += gridSize) {
      for (double y = 0; y <= size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}