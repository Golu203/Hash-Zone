import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/india_states_cities.dart';
import '../services/address_service.dart';

class UnifiedAddressForm extends StatefulWidget {
  final CustomerAddress2? initialAddress;
  final String? defaultFullName;
  final String? defaultPhone;
  final String? defaultCompany;
  final Function(CustomerAddress2 address) onSave;
  final String submitButtonText;
  final bool isSaving;

  const UnifiedAddressForm({
    super.key,
    this.initialAddress,
    this.defaultFullName,
    this.defaultPhone,
    this.defaultCompany,
    required this.onSave,
    this.submitButtonText = 'Save Address',
    this.isSaving = false,
  });

  @override
  State<UnifiedAddressForm> createState() => _UnifiedAddressFormState();
}

class _UnifiedAddressFormState extends State<UnifiedAddressForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _doorCtrl;
  late TextEditingController _roadCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _pinCtrl;
  late TextEditingController _landmarkCtrl;
  late TextEditingController _labelCtrl;

  String? _selectedState;
  String? _selectedCity;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialAddress;

    _nameCtrl = TextEditingController(text: init?.name ?? widget.defaultFullName ?? '');
    _phoneCtrl = TextEditingController(text: init?.phone ?? widget.defaultPhone ?? '');
    _companyCtrl = TextEditingController(text: init?.companyName ?? widget.defaultCompany ?? '');
    _doorCtrl = TextEditingController(text: init?.doorNumber ?? '');
    _roadCtrl = TextEditingController(text: init?.road ?? '');
    _areaCtrl = TextEditingController(text: init?.area ?? '');
    _pinCtrl = TextEditingController(text: init?.pincode ?? '');
    _landmarkCtrl = TextEditingController(text: init?.landmark ?? '');
    _labelCtrl = TextEditingController(text: init?.label ?? 'Home');

    _selectedState = init?.state.isNotEmpty == true ? init!.state : 'Tamil Nadu';
    _selectedCity = init?.city.isNotEmpty == true ? init!.city : 'Tiruppur';
    _isDefault = init?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _doorCtrl.dispose();
    _roadCtrl.dispose();
    _areaCtrl.dispose();
    _pinCtrl.dispose();
    _landmarkCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _openSearchDialog({
    required String title,
    required List<String> items,
    required Function(String) onSelect,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = items
                .where((item) => item.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              title: Text('Select $title', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 22)),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search $title...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) => setDialogState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(child: Text('No $title found', style: GoogleFonts.inter(fontSize: 13, color: Colors.black45)))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ListTile(
                                  title: Text(item, style: GoogleFonts.inter(fontSize: 14)),
                                  onTap: () {
                                    onSelect(item);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null || _selectedState!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a State')));
      return;
    }
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a City')));
      return;
    }

    final addr = CustomerAddress2(
      id: widget.initialAddress?.id ?? '',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      companyName: _companyCtrl.text.trim(),
      doorNumber: _doorCtrl.text.trim(),
      road: _roadCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
      city: _selectedCity!.trim(),
      state: _selectedState!.trim(),
      pincode: _pinCtrl.text.trim(),
      landmark: _landmarkCtrl.text.trim(),
      label: _labelCtrl.text.trim().isEmpty ? 'Address' : _labelCtrl.text.trim(),
      isDefault: _isDefault,
    );

    widget.onSave(addr);
  }

  @override
  Widget build(BuildContext context) {
    final states = IndiaGeoData.states;
    final cities = _selectedState != null ? IndiaGeoData.getCities(_selectedState!) : <String>[];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name & Phone
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: _dec('Full Name *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _dec('Phone Number *'),
                  validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid phone' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Company Name & Label
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _companyCtrl,
                  decoration: _dec('Company Name (Optional)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _labelCtrl,
                  decoration: _dec('Label (Home / Office / Factory)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Door / House & Road / Street
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _doorCtrl,
                  decoration: _dec('Door / Flat / Building No. *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _roadCtrl,
                  decoration: _dec('Road / Street / Block *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Area / Locality
          TextFormField(
            controller: _areaCtrl,
            decoration: _dec('Area / Locality *'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),

          // Searchable State & City Dropdowns
          Row(
            children: [
              // Searchable State Selector
              Expanded(
                child: InkWell(
                  onTap: () => _openSearchDialog(
                    title: 'State',
                    items: states,
                    onSelect: (state) {
                      setState(() {
                        _selectedState = state;
                        final availableCities = IndiaGeoData.getCities(state);
                        _selectedCity = availableCities.isNotEmpty ? availableCities.first : '';
                      });
                    },
                  ),
                  child: InputDecorator(
                    decoration: _dec('State *'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedState ?? 'Select State', style: GoogleFonts.inter(fontSize: 14)),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Searchable City Selector
              Expanded(
                child: InkWell(
                  onTap: () => _openSearchDialog(
                    title: 'City',
                    items: cities,
                    onSelect: (city) => setState(() => _selectedCity = city),
                  ),
                  child: InputDecorator(
                    decoration: _dec('City *'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedCity ?? 'Select City', style: GoogleFonts.inter(fontSize: 14)),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // PIN Code & Landmark
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: _dec('PIN Code (6 Digits) *'),
                  validator: (v) => v == null || v.trim().length != 6 ? '6 digits required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _landmarkCtrl,
                  decoration: _dec('Landmark (Optional)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Set as Default Address Checkbox
          CheckboxListTile(
            value: _isDefault,
            onChanged: (val) => setState(() => _isDefault = val ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('Set as Default Address', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: widget.isSaving ? null : _submit,
              child: widget.isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text(widget.submitButtonText, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
    );
  }
}
