import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absen_cmi/config/api_config.dart';
import 'package:absen_cmi/models/order.dart';
import 'package:absen_cmi/services/auth_service.dart';

class PaymentFormDialog extends StatefulWidget {
  final Order order;
  final VoidCallback onRefresh;

  const PaymentFormDialog({
    Key? key,
    required this.order,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<PaymentFormDialog> {
  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final methodController = TextEditingController();
  final amountController = TextEditingController();
  final scrollController = ScrollController();
  File? selectedImage;
  double initialRemaining = 0;
  double currentRemaining = 0;
  FocusNode? _currentFocus;

  @override
  void initState() {
    super.initState();
    initialRemaining = widget.order.remaining.toDouble();
    currentRemaining = initialRemaining;
  }

  @override
  void dispose() {
    dateController.dispose();
    methodController.dispose();
    amountController.dispose();
    scrollController.dispose();
    _currentFocus?.dispose();
    super.dispose();
  }

  void _scrollToFocusedField(FocusNode node) {
    _currentFocus = node;
    Future.delayed(const Duration(milliseconds: 200), () {
      if (node.hasFocus) {
        final RenderBox? renderBox =
            node.context?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final offset = renderBox.localToGlobal(Offset.zero);
          final screenHeight = MediaQuery.of(context).size.height;
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final visibleHeight = screenHeight - keyboardHeight;

          if (offset.dy > visibleHeight - 100) {
            scrollController.animateTo(
              scrollController.offset + (offset.dy - visibleHeight + 100),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tambah Pembayaran',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRemainingAmountCard(),
                const SizedBox(height: 24),
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDateField(),
                      const SizedBox(height: 16),
                      _buildMethodField(),
                      const SizedBox(height: 16),
                      _buildAmountField(),
                      const SizedBox(height: 24),
                      _buildImageUploadButton(),
                      if (selectedImage != null) ...[
                        const SizedBox(height: 16),
                        _buildImagePreview(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Simpan'),
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

  Widget _buildRemainingAmountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sisa Pembayaran',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(currentRemaining),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    final focusNode = FocusNode();
    focusNode.addListener(() => _scrollToFocusedField(focusNode));

    return TextFormField(
      controller: dateController,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: 'Tanggal',
        hintText: 'Pilih tanggal',
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          dateController.text = DateFormat('yyyy-MM-dd').format(date);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tanggal harus diisi';
        }
        return null;
      },
    );
  }

  Widget _buildMethodField() {
    final focusNode = FocusNode();
    focusNode.addListener(() => _scrollToFocusedField(focusNode));

    return TextFormField(
      controller: methodController,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: 'Metode Pembayaran',
        hintText: 'Masukkan metode pembayaran',
        prefixIcon: const Icon(Icons.payment),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Metode pembayaran harus diisi';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    final focusNode = FocusNode();
    focusNode.addListener(() => _scrollToFocusedField(focusNode));

    return TextFormField(
      controller: amountController,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: 'Jumlah',
        hintText: 'Masukkan jumlah pembayaran',
        prefixText: 'Rp ',
        helperText:
            'Maksimal ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(currentRemaining)}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        if (value.isNotEmpty) {
          final amount = double.tryParse(value) ?? 0;
          if (amount > initialRemaining) {
            amountController.text = initialRemaining.toInt().toString();
            amountController.selection = TextSelection.fromPosition(
              TextPosition(offset: amountController.text.length),
            );
            setState(() {
              currentRemaining = 0;
            });
          } else {
            setState(() {
              currentRemaining = initialRemaining - amount;
            });
          }
        } else {
          setState(() {
            currentRemaining = initialRemaining;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Jumlah harus diisi';
        }
        final amount = double.tryParse(value);
        if (amount == null) {
          return 'Jumlah harus berupa angka';
        }
        if (amount <= 0) {
          return 'Jumlah harus lebih dari 0';
        }
        if (amount > initialRemaining) {
          return 'Jumlah tidak boleh melebihi sisa pembayaran';
        }
        return null;
      },
    );
  }

  Widget _buildImageUploadButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        final ImagePicker picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            selectedImage = File(image.path);
          });
        }
      },
      icon: const Icon(Icons.upload_file),
      label: const Text('Upload Bukti Pembayaran'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: selectedImage != null
            ? Image.file(
                selectedImage!,
                fit: BoxFit.cover,
              )
            : Image.network(
                '${ApiConfig.assetsUrl}${widget.order.id}/payment.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (formKey.currentState!.validate()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AuthService.TOKEN_KEY);

        if (token == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token tidak ditemukan')),
          );
          return;
        }

        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              '${ApiConfig.baseUrl}/orders/add-payment/${widget.order.id}'),
        );

        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        });

        request.fields.addAll({
          'date': dateController.text,
          'payment_method': methodController.text,
          'amount': amountController.text,
        });

        if (selectedImage != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              selectedImage!.path,
            ),
          );
        }

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!mounted) return;
          // Show success message first
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil ditambahkan'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Pop the dialog first
          Navigator.of(context).pop();
          // Pop the detail screen to go back to order list
          Navigator.of(context).pop();
          // Trigger refresh
          widget.onRefresh();
        } else {
          throw Exception('Gagal menambahkan pembayaran: ${responseBody}');
        }
      } catch (e) {
        if (!mounted) return;
        // Show error message first
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Tutup',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        // Pop the dialog first
        Navigator.of(context).pop();
        // Pop the detail screen to go back to order list
        Navigator.of(context).pop();
        // Trigger refresh
        widget.onRefresh();
      }
    }
  }
}
