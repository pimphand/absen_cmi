import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/customer.dart';

class AddCustomerForm extends StatefulWidget {
  final VoidCallback onSuccess;
  final Customer? customer;

  const AddCustomerForm({
    Key? key,
    required this.onSuccess,
    this.customer,
  }) : super(key: key);

  @override
  State<AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<AddCustomerForm> {
  int _step = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Step 1 controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedStateId;
  String? _selectedStateName;
  String? _selectedCityId;
  String? _selectedCityName;

  // Step 2 controllers
  final TextEditingController _npwpController = TextEditingController();
  File? _storePhoto;
  File? _ownerPhoto;
  bool _isLoading = false;
  String? _error;

  List<Map<String, String>> _provinces = [];
  List<Map<String, String>> _cities = [];
  bool _loadingProvinces = false;
  bool _loadingCities = false;

  @override
  void initState() {
    super.initState();
    _fetchProvinces();

    // If in edit mode, populate the form
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      _storeNameController.text = widget.customer!.storeName;
      _addressController.text = widget.customer!.address;

      // Set province and city
      if (widget.customer!.state != null &&
          widget.customer!.state!.isNotEmpty) {
        _selectedStateName = widget.customer!.state;
        // Find and set the province ID
        for (var province in _provinces) {
          if (province['name'] == widget.customer!.state) {
            _selectedStateId = province['id'];
            break;
          }
        }
      }

      if (widget.customer!.city != null && widget.customer!.city!.isNotEmpty) {
        _selectedCityName = widget.customer!.city;
      }
    }
  }

  Future<void> _fetchProvinces() async {
    setState(() {
      _loadingProvinces = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://www.emsifa.com/api-wilayah-indonesia/api/provinces.json'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _provinces = data
              .map<Map<String, String>>(
                  (e) => {'id': e['id'], 'name': e['name']})
              .toList();
        });

        // After fetching provinces, if in edit mode, set the province and fetch cities
        if (widget.customer != null &&
            widget.customer!.state != null &&
            widget.customer!.state!.isNotEmpty) {
          for (var province in _provinces) {
            if (province['name'] == widget.customer!.state) {
              _selectedStateId = province['id'];
              _selectedStateName = province['name'];
              await _fetchCities(province['id']!);
              break;
            }
          }
        }
      }
    } catch (e) {
      // ignore error for now
    } finally {
      setState(() {
        _loadingProvinces = false;
      });
    }
  }

  Future<void> _fetchCities(String provinceId) async {
    setState(() {
      _loadingCities = true;
      _cities = [];
      _selectedCityId = null;
      _selectedCityName = null;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://www.emsifa.com/api-wilayah-indonesia/api/regencies/$provinceId.json'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _cities = data
              .map<Map<String, String>>(
                  (e) => {'id': e['id'], 'name': e['name']})
              .toList();
        });

        // After fetching cities, if in edit mode, set the city
        if (widget.customer != null &&
            widget.customer!.city != null &&
            widget.customer!.city!.isNotEmpty) {
          for (var city in _cities) {
            if (city['name'] == widget.customer!.city) {
              _selectedCityId = city['id'];
              _selectedCityName = city['name'];
              break;
            }
          }
        }
      }
    } catch (e) {
      // ignore error for now
    } finally {
      setState(() {
        _loadingCities = false;
      });
    }
  }

  Future<void> _pickImage(bool isStorePhoto) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isStorePhoto) {
          _storePhoto = File(picked.path);
        } else {
          _ownerPhoto = File(picked.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey2.currentState!.validate()) return;

    // Only require photos for new customers
    if (widget.customer == null &&
        (_storePhoto == null || _ownerPhoto == null)) {
      setState(() {
        _error = 'Foto toko dan foto pemilik wajib diisi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      var uri = Uri.parse(
          '${ApiConfig.baseUrl}/customers${widget.customer != null ? '/${widget.customer!.id}' : ''}');
      var request =
          http.MultipartRequest(widget.customer != null ? 'POST' : 'POST', uri);
      request.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = _nameController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['store_name'] = _storeNameController.text;
      request.fields['address'] = _addressController.text;
      request.fields['state'] = _selectedStateName ?? '';
      request.fields['city'] = _selectedCityName ?? '';
      if (_npwpController.text.isNotEmpty) {
        request.fields['npwp'] = _npwpController.text;
      }

      // Only add photos if they are selected
      if (_storePhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'store_photo', _storePhoto!.path));
      }
      if (_ownerPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'owner_photo', _ownerPhoto!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        widget.onSuccess();
      } else {
        setState(() {
          _error =
              'Gagal ${widget.customer != null ? 'mengubah' : 'menambah'} customer. Status: ${response.statusCode}\nPesan: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: IndexedStack(
            index: _step,
            children: [
              Form(
                key: _formKey1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer != null
                          ? 'Edit Customer'
                          : 'Tambah Customer',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Nama Pemilik'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                          labelText: 'Nomor Telepon (Whatsapp)'),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(labelText: 'Nama Toko'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration:
                          const InputDecoration(labelText: 'Alamat Toko'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _loadingProvinces
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: _selectedStateId,
                            items: _provinces
                                .map((e) => DropdownMenuItem(
                                      value: e['id'],
                                      child: Text(e['name'] ?? ''),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              final prov =
                                  _provinces.firstWhere((e) => e['id'] == v);
                              setState(() {
                                _selectedStateId = v;
                                _selectedStateName = prov['name'];
                              });
                              _fetchCities(v!);
                            },
                            decoration:
                                const InputDecoration(labelText: 'Provinsi'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Wajib diisi' : null,
                          ),
                    const SizedBox(height: 16),
                    _loadingCities
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: _selectedCityId,
                            items: _cities
                                .map((e) => DropdownMenuItem(
                                      value: e['id'],
                                      child: Text(e['name'] ?? ''),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              final city =
                                  _cities.firstWhere((e) => e['id'] == v);
                              setState(() {
                                _selectedCityId = v;
                                _selectedCityName = city['name'];
                              });
                            },
                            decoration:
                                const InputDecoration(labelText: 'Kota'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Wajib diisi' : null,
                          ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_formKey1.currentState!.validate()) {
                                      setState(() => _step = 1);
                                    }
                                  },
                            child: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Form(
                key: _formKey2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer != null
                          ? 'Edit Customer'
                          : 'Tambah Customer',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _npwpController,
                      decoration:
                          const InputDecoration(labelText: 'NPWP (optional)'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isLoading ? null : () => _pickImage(true),
                            child: Text(_storePhoto == null
                                ? 'Pilih Foto Toko${widget.customer != null ? ' (optional)' : ''}'
                                : 'Foto Toko Terpilih'),
                          ),
                        ),
                        if (_storePhoto != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child:
                                Icon(Icons.check_circle, color: Colors.green),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isLoading ? null : () => _pickImage(false),
                            child: Text(_ownerPhoto == null
                                ? 'Pilih Foto Pemilik${widget.customer != null ? ' (optional)' : ''}'
                                : 'Foto Pemilik Terpilih'),
                          ),
                        ),
                        if (_ownerPhoto != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child:
                                Icon(Icons.check_circle, color: Colors.green),
                          ),
                      ],
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => setState(() => _step = 0),
                            child: const Text('Kembali'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _addressController.dispose();
    _npwpController.dispose();
    super.dispose();
  }
}
