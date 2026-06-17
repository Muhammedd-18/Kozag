import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

class DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text.length > newValue.text.length) return newValue;
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) return oldValue;
    String newText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) newText += '/';
      newText += text[i];
    }
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

class TimeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text.length > newValue.text.length) return newValue;
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 4) return oldValue;
    String newText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2) newText += ':';
      newText += text[i];
    }
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

class ChildFormData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController birthTimeController = TextEditingController();
  final TextEditingController birthPlaceController = TextEditingController();
  final TextEditingController gestationWeekController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController headCircumController = TextEditingController();
  final TextEditingController doctorController = TextEditingController();
  final TextEditingController midwivesController = TextEditingController();
  String gender = 'Kız';
  String deliveryType = 'Normal Doğum';

  final TextEditingController feverController = TextEditingController();
  bool hasDisease = false;
  List<String> selectedDiseases = [];
  bool isPremature = false;
  bool inIncubator = false;
  final TextEditingController incubatorDaysController = TextEditingController();
  List<String> selectedVaccines = [];
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _tcController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _maidenNameController = TextEditingController();
  final TextEditingController _pregnancyWeekController = TextEditingController();

  final FocusNode _tcFocusNode = FocusNode();
  String? _tcErrorText;

  bool _isPregnant = true;
  bool _isMultiplePregnancy = false;

  List<ChildFormData> _childrenForms = [ChildFormData()];

  final List<String> _diseaseOptions = [
    'Sarılık (Yenidoğan)', 'Down Sendromu', 'Doğumsal Kalp Hastalığı',
    'Yarık Damak/Dudak', 'Solunum Sıkıntısı (RDS)', 'Spina Bifida',
    'Fenilketonüri (PKU)', 'Çarpık Ayak (Pes Equinovarus)'
  ];

  final List<String> _vaccineOptions = [
    'Hepatit B Aşısı (1. Doz)', 'K Vitamini İğnesi', 'Göz Damlası/Merhemi', 'Hepatit B İmmünoglobulini (HBIG)'
  ];

  @override
  void initState() {
    super.initState();
    _tcFocusNode.addListener(() {
      if (!_tcFocusNode.hasFocus) {
        setState(() {
          if (_tcController.text.isNotEmpty && _tcController.text.length != 11) {
            _tcErrorText = 'TC Kimlik No 11 haneli olmalıdır!';
          } else {
            _tcErrorText = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tcFocusNode.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 3)));
  }

  void _saveData() async {
    if (_tcController.text.isEmpty || _nameController.text.isEmpty || _maidenNameController.text.isEmpty) {
      _showError('Lütfen anne temel bilgilerini eksiksiz doldurun!');
      return;
    }
    if (_tcController.text.length != 11) {
      _showError('TC Kimlik Numarası 11 hane olmalıdır!');
      return;
    }
    if (_isPregnant && _pregnancyWeekController.text.isEmpty) {
      _showError('Lütfen hamilelik haftasını doldurun!');
      return;
    }

    if (!_isPregnant) {
      for (int i = 0; i < _childrenForms.length; i++) {
        var form = _childrenForms[i];
        if (form.nameController.text.isEmpty || form.birthDateController.text.isEmpty ||
            form.birthTimeController.text.isEmpty || form.birthPlaceController.text.isEmpty ||
            form.gestationWeekController.text.isEmpty || form.weightController.text.isEmpty ||
            form.heightController.text.isEmpty || form.headCircumController.text.isEmpty ||
            form.doctorController.text.isEmpty || form.midwivesController.text.isEmpty ||
            form.feverController.text.isEmpty) {
          _showError('Lütfen ${i + 1}. bebeğin tüm metin alanlarını eksiksiz doldurun!');
          return;
        }
        if (form.inIncubator && form.incubatorDaysController.text.isEmpty) {
          _showError('Lütfen ${i + 1}. bebeğin küvezde kalma süresini doldurun!');
          return;
        }
      }
    }

    try {
      final db = await DatabaseHelper.instance.database;
      String tc = _tcController.text.trim();
      final existingUser = await db.query('users', where: 'tc_no = ?', whereArgs: [tc]);
      int motherId;

      if (existingUser.isNotEmpty) {
        motherId = existingUser.first['id'] as int;
        await db.update(
            'users',
            {
              'name': _nameController.text.trim(),
              'maiden_name': _maidenNameController.text.trim(),
              'is_pregnant': _isPregnant ? 1 : 0,
              'pregnancy_week': _isPregnant ? (int.tryParse(_pregnancyWeekController.text) ?? 0) : 0,
            },
            where: 'id = ?',
            whereArgs: [motherId]
        );
      } else {
        Map<String, dynamic> motherRow = {
          'tc_no': tc,
          'name': _nameController.text.trim(),
          'maiden_name': _maidenNameController.text.trim(),
          'is_pregnant': _isPregnant ? 1 : 0,
          'pregnancy_week': _isPregnant ? (int.tryParse(_pregnancyWeekController.text) ?? 0) : 0,
          'registration_date': DateTime.now().toIso8601String(), // YENİ: ZAMAN ÇIPASI
        };
        motherId = await DatabaseHelper.instance.createUser(motherRow);
      }

      if (motherId > 0 && !_isPregnant) {
        for (var form in _childrenForms) {
          Map<String, dynamic> childRow = {
            'parent_id': motherId,
            'child_name': form.nameController.text.trim(), 'birth_date': form.birthDateController.text.trim(),
            'birth_time': form.birthTimeController.text.trim(), 'birth_place': form.birthPlaceController.text.trim(),
            'gestation_week': int.tryParse(form.gestationWeekController.text) ?? 0, 'gender': form.gender,
            'weight_gr': int.tryParse(form.weightController.text) ?? 0, 'height': double.tryParse(form.heightController.text) ?? 0.0,
            'head_circumference': double.tryParse(form.headCircumController.text) ?? 0.0, 'is_multiple_pregnancy': _isMultiplePregnancy ? 1 : 0,
            'delivery_type': form.deliveryType, 'doctor_name': form.doctorController.text.trim(), 'midwives': form.midwivesController.text.trim(),
            'birth_fever': double.tryParse(form.feverController.text) ?? 36.5, 'has_disease': form.hasDisease ? 1 : 0,
            'diseases': form.selectedDiseases.join(', '), 'is_premature': form.isPremature ? 1 : 0,
            'in_incubator': form.inIncubator ? 1 : 0, 'incubator_days': int.tryParse(form.incubatorDaysController.text) ?? 0,
            'vaccines': form.selectedVaccines.join(', '),
          };
          await DatabaseHelper.instance.createChild(childRow);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt başarıyla tamamlandı!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Kayıt sırasında bir hata oluştu: $e');
    }
  }

  Widget _buildSelectionCard({required String title, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFCE4EC) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? const Color(0xFFD67B8E) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: const Color(0xFFD67B8E).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFD67B8E) : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildForm(ChildFormData form, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10), color: Colors.white, elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${index + 1}. Bebek Doğum Bilgileri', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            TextField(controller: form.nameController, decoration: const InputDecoration(labelText: 'Bebeğin Adı', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: form.birthDateController, keyboardType: TextInputType.number, inputFormatters: [DateFormatter()], decoration: const InputDecoration(labelText: 'Doğum Tarihi', hintText: '17/06/2026', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: form.birthTimeController, keyboardType: TextInputType.number, inputFormatters: [TimeFormatter()], decoration: const InputDecoration(labelText: 'Saati', hintText: '14:30', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 10),
            TextField(controller: form.birthPlaceController, decoration: const InputDecoration(labelText: 'Doğum Yeri (Hastane)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: form.gestationWeekController, keyboardType: TextInputType.number, inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Doğum Haftası', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(value: form.gender, decoration: const InputDecoration(labelText: 'Cinsiyet', border: OutlineInputBorder()), items: ['Kız', 'Erkek'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) => setState(() => form.gender = val!))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: form.weightController, keyboardType: TextInputType.number, inputFormatters: [LengthLimitingTextInputFormatter(4), FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Kilo (gr)', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: form.heightController, keyboardType: TextInputType.number, inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Boy (cm)', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: form.headCircumController, keyboardType: TextInputType.number, inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Baş Çev.', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(value: form.deliveryType, decoration: const InputDecoration(labelText: 'Doğum Şekli', border: OutlineInputBorder()), items: ['Normal Doğum', 'Sezaryen', 'Suda Doğum'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) => setState(() => form.deliveryType = val!)),
            const SizedBox(height: 10),
            TextField(controller: form.doctorController, decoration: const InputDecoration(labelText: 'Hekim Adı', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: form.midwivesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Yardımcı Ebeler', border: OutlineInputBorder())),

            const Divider(height: 30, thickness: 2),
            const Text('Kritik Tıbbi Durumlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 10),
            TextField(controller: form.feverController, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [LengthLimitingTextInputFormatter(4)], decoration: const InputDecoration(labelText: 'Doğum Anındaki Ateşi', suffixText: '°C', border: OutlineInputBorder())),
            SwitchListTile(title: const Text('Erken Doğum (Prematüre) mu?'), value: form.isPremature, onChanged: (val) => setState(() { form.isPremature = val; if (!val) form.inIncubator = false; })),
            if (form.isPremature) ...[
              SwitchListTile(title: const Text('Küvezde Kaldı mı?'), value: form.inIncubator, onChanged: (val) => setState(() => form.inIncubator = val)),
              if (form.inIncubator) TextField(controller: form.incubatorDaysController, keyboardType: TextInputType.number, inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Küvezde Kalma Süresi (Gün)', border: OutlineInputBorder())),
            ],
            SwitchListTile(title: const Text('Doğuştan Kalıcı Hastalık / Sendrom var mı?'), value: form.hasDisease, onChanged: (val) => setState(() { form.hasDisease = val; if (!val) form.selectedDiseases.clear(); })),
            if (form.hasDisease) ...[
              const Text('Lütfen Hastalıkları Seçiniz:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 8.0, children: _diseaseOptions.map((disease) => FilterChip(label: Text(disease, style: const TextStyle(fontSize: 12)), selected: form.selectedDiseases.contains(disease), selectedColor: Colors.red[100], onSelected: (bool selected) { setState(() { selected ? form.selectedDiseases.add(disease) : form.selectedDiseases.remove(disease); }); })).toList()),
            ],

            const Divider(height: 30, thickness: 2),
            const Text('Taburcu Öncesi Aşılar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            Wrap(spacing: 8.0, children: _vaccineOptions.map((vaccine) => FilterChip(label: Text(vaccine, style: const TextStyle(fontSize: 12)), selected: form.selectedVaccines.contains(vaccine), selectedColor: Colors.blue[100], onSelected: (bool selected) { setState(() { selected ? form.selectedVaccines.add(vaccine) : form.selectedVaccines.remove(vaccine); }); })).toList()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hastane Veri Girişi'), backgroundColor: const Color(0xFFD67B8E), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Anne Bilgileri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD67B8E))),
            const SizedBox(height: 15),

            TextField(
                controller: _tcController,
                focusNode: _tcFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [LengthLimitingTextInputFormatter(11), FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'TC Kimlik No',
                  border: const OutlineInputBorder(),
                  errorText: _tcErrorText,
                )
            ),

            const SizedBox(height: 10),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Anne Adı Soyadı', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _maidenNameController, decoration: const InputDecoration(labelText: 'Kızlık Soyadı', border: OutlineInputBorder())),
            const SizedBox(height: 30),

            const Text('Mevcut Durum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSelectionCard(
                    title: 'Hamile',
                    isSelected: _isPregnant,
                    onTap: () => setState(() => _isPregnant = true)
                ),
                const SizedBox(width: 15),
                _buildSelectionCard(
                    title: 'Doğum Yaptı',
                    isSelected: !_isPregnant,
                    onTap: () => setState(() => _isPregnant = false)
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isPregnant)
              TextField(
                  controller: _pregnancyWeekController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Kaçıncı Haftada?', border: OutlineInputBorder())
              ),

            if (!_isPregnant) ...[
              const Divider(height: 40, thickness: 2),
              const Text('Bebek Doğum Bilgileri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              SwitchListTile(
                title: const Text('Çoğul Gebelik mi?'),
                value: _isMultiplePregnancy,
                onChanged: (val) {
                  setState(() {
                    _isMultiplePregnancy = val;
                    if (val && _childrenForms.length == 1) _childrenForms.add(ChildFormData());
                    else if (!val) _childrenForms.removeRange(1, _childrenForms.length);
                  });
                },
              ),
              ...List.generate(_childrenForms.length, (index) => _buildChildForm(_childrenForms[index], index)),
              if (_isMultiplePregnancy && _childrenForms.length < 5)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _childrenForms.add(ChildFormData())),
                    icon: const Icon(Icons.add, color: Colors.teal),
                    label: const Text('Yeni Bebek Ekle', style: TextStyle(color: Colors.teal)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.teal)
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD67B8E), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Tüm Verileri Kaydet', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}