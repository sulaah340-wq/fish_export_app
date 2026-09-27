import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FishExportApp());
}

class FishExportApp extends StatelessWidget {
  const FishExportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أسماك فريش - Fish Export',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class ExportRecord {
  final int? id;
  final String fishType;
  final double quantity;
  final String destinationCountry;
  final String receiverName;
  final double totalPrice;
  final double receivedAmount;
  final double remainingAmount;
  final String currency;
  final String date;
  final String notes;

  ExportRecord({
    this.id,
    required this.fishType,
    required this.quantity,
    required this.destinationCountry,
    required this.receiverName,
    required this.totalPrice,
    required this.receivedAmount,
    required this.remainingAmount,
    required this.currency,
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fishType': fishType,
      'quantity': quantity,
      'destinationCountry': destinationCountry,
      'receiverName': receiverName,
      'totalPrice': totalPrice,
      'receivedAmount': receivedAmount,
      'remainingAmount': remainingAmount,
      'currency': currency,
      'date': date,
      'notes': notes,
    };
  }

  factory ExportRecord.fromMap(Map<String, dynamic> map) {
    return ExportRecord(
      id: map['id'],
      fishType: map['fishType'],
      quantity: map['quantity'],
      destinationCountry: map['destinationCountry'],
      receiverName: map['receiverName'],
      totalPrice: map['totalPrice'],
      receivedAmount: map['receivedAmount'],
      remainingAmount: map['remainingAmount'],
      currency: map['currency'],
      date: map['date'],
      notes: map['notes'] ?? '',
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fish_export_fresh.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fishType TEXT NOT NULL,
        quantity REAL NOT NULL,
        destinationCountry TEXT NOT NULL,
        receiverName TEXT NOT NULL,
        totalPrice REAL NOT NULL,
        receivedAmount REAL NOT NULL,
        remainingAmount REAL NOT NULL,
        currency TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<int> insertRecord(ExportRecord record) async {
    final db = await instance.database;
    return await db.insert('exports', record.toMap());
  }

  Future<List<ExportRecord>> getAllRecords() async {
    final db = await instance.database;
    final result = await db.query('exports', orderBy: 'id DESC');
    return result.map((json) => ExportRecord.fromMap(json)).toList();
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete('exports', where: 'id = ?', whereArgs: [id]);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ExportRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  Future<void> _refreshRecords() async {
    setState(() => _isLoading = true);
    _records = await DatabaseHelper.instance.getAllRecords();
    setState(() => _isLoading = false);
  }

  Map<String, Map<String, double>> _calculateTotals() {
    Map<String, Map<String, double>> totals = {};
    for (var r in _records) {
      if (!totals.containsKey(r.currency)) {
        totals[r.currency] = {'total': 0.0, 'received': 0.0, 'remaining': 0.0};
      }
      totals[r.currency]!['total'] = totals[r.currency]!['total']! + r.totalPrice;
      totals[r.currency]!['received'] = totals[r.currency]!['received']! + r.receivedAmount;
      totals[r.currency]!['remaining'] = totals[r.currency]!['remaining']! + r.remainingAmount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('أسماك فريش - المحاسبة'),
          centerTitle: true,
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (totals.isNotEmpty)
                    Container(
                      height: 110,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: totals.entries.map((entry) {
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'العملة: ${entry.key}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                                Text('الإجمالي: ${entry.value['total']!.toStringAsFixed(2)}'),
                                Text('المستلم: ${entry.value['received']!.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.green)),
                                Text('المتبقي: ${entry.value['remaining']!.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const Divider(height: 1),
                  Expanded(
                    child: _records.isEmpty
                        ? const Center(child: Text('لا توجد شحنات مسجلة حتى الآن'))
                        : ListView.builder(
                            itemCount: _records.length,
                            itemBuilder: (context, index) {
                              final item = _records[index];
                              return Card(
                                margin: const EdgeInsets.all(8),
                                elevation: 2,
                                child: ListTile(
                                  title: Text(
                                    '${item.fishType} (${item.quantity} كجم/صندوق)',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('إلى: ${item.destinationCountry} | المستلم: ${item.receiverName}'),
                                        Text(
                                            'الإجمالي: ${item.totalPrice} ${item.currency} | المستلم: ${item.receivedAmount} ${item.currency}'),
                                        Text(
                                          'المتبقي: ${item.remainingAmount} ${item.currency}',
                                          style: TextStyle(
                                            color: item.remainingAmount > 0 ? Colors.red : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text('التاريخ: ${item.date}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await DatabaseHelper.instance.deleteRecord(item.id!);
                                      _refreshRecords();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddExportScreen()),
            );
            _refreshRecords();
          },
          label: const Text('إضافة شحنة جديدة'),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.teal.shade700,
        ),
      ),
    );
  }
}

class AddExportScreen extends StatefulWidget {
  const AddExportScreen({super.key});

  @override
  State<AddExportScreen> createState() => _AddExportScreenState();
}

class _AddExportScreenState extends State<AddExportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fishTypeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _destinationController = TextEditingController();
  final _receiverController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _receivedAmountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCurrency = 'ر.س (سعودي)';
  final List<String> _currencies = [
    'ر.س (سعودي)',
    '\$ (دولار)',
    'ر.ي (يمني)',
    'د.إ (إماراتي)',
    'ر.ع (عماني)'
  ];

  double _calculatedRemaining = 0.0;

  void _updateRemaining() {
    double total = double.tryParse(_totalPriceController.text) ?? 0.0;
    double received = double.tryParse(_receivedAmountController.text) ?? 0.0;
    setState(() {
      _calculatedRemaining = total - received;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة شحنة أسماك جديدة'),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _fishTypeController,
                  decoration: const InputDecoration(labelText: 'نوع السمك (مثال: هامور / ديراك / باغة)', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'يرجى إدخال نوع السمك' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية (بالكيلو / الصناديق)', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'يرجى إدخال الكمية' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(labelText: 'البلد المصدر إليه (مثال: السعودية / الإمارات)', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'يرجى إدخال بلد المقصد' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _receiverController,
                  decoration: const InputDecoration(labelText: 'اسم الشخص / التاجر المستلم هناك', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'يرجى إدخال اسم المستلم' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: const InputDecoration(labelText: 'العملة', border: OutlineInputBorder()),
                  items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCurrency = val!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _totalPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ الإجمالي للشحنة', border: OutlineInputBorder()),
                  onChanged: (_) => _updateRemaining(),
                  validator: (v) => v!.isEmpty ? 'يرجى إدخال المبلغ الإجمالي' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _receivedAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ المستلم (الواصل)', border: OutlineInputBorder()),
                  onChanged: (_) => _updateRemaining(),
                  validator: (v) => v!.isEmpty ? 'يرجى إدخال المبلغ المستلم' : null,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'المبلغ المتبقي: ${_calculatedRemaining.toStringAsFixed(2)} $_selectedCurrency',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات إضافية (اختياري)', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final record = ExportRecord(
                        fishType: _fishTypeController.text,
                        quantity: double.parse(_quantityController.text),
                        destinationCountry: _destinationController.text,
                        receiverName: _receiverController.text,
                        totalPrice: double.parse(_totalPriceController.text),
                        receivedAmount: double.parse(_receivedAmountController.text),
                        remainingAmount: _calculatedRemaining,
                        currency: _selectedCurrency,
                        date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                        notes: _notesController.text,
                      );

                      await DatabaseHelper.instance.insertRecord(record);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('حفظ الشحنة', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
