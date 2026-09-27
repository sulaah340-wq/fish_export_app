import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(FishAccountsApp(store: store));
}

class AppStore extends ChangeNotifier {
  static const _shipmentsKey = 'shipments';
  static const _collectionsKey = 'collections';
  static const _expensesKey = 'expenses';
  static const _ratesKey = 'rates';

  List<Map<String, dynamic>> shipments = [];
  List<Map<String, dynamic>> collections = [];
  List<Map<String, dynamic>> expenses = [];
  Map<String, double> rates = {'YER': 530.0, 'SAR': 3.75, 'USD': 1.0};

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    shipments = _decodeList(p.getString(_shipmentsKey));
    collections = _decodeList(p.getString(_collectionsKey));
    expenses = _decodeList(p.getString(_expensesKey));
    final r = p.getString(_ratesKey);
    if (r != null) {
      rates = Map<String, dynamic>.from(jsonDecode(r))
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
  }

  List<Map<String, dynamic>> _decodeList(String? value) {
    if (value == null) return [];
    final decoded = jsonDecode(value) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_shipmentsKey, jsonEncode(shipments));
    await p.setString(_collectionsKey, jsonEncode(collections));
    await p.setString(_expensesKey, jsonEncode(expenses));
    await p.setString(_ratesKey, jsonEncode(rates));
    notifyListeners();
  }

  Future<void> addShipment(Map<String, dynamic> x) async {
    shipments.insert(0, x);
    await _save();
  }
  Future<void> addCollection(Map<String, dynamic> x) async {
    collections.insert(0, x);
    await _save();
  }
  Future<void> addExpense(Map<String, dynamic> x) async {
    expenses.insert(0, x);
    await _save();
  }
  Future<void> setRates(Map<String, double> x) async {
    rates = x;
    await _save();
  }

  double total(String key, String currency, List<Map<String, dynamic>> list) =>
      list.where((x) => x['currency'] == currency)
          .fold(0.0, (s, x) => s + ((x[key] as num?)?.toDouble() ?? 0));

  double shipmentValue(String currency) =>
      shipments.where((x) => x['currency'] == currency).fold(
          0.0, (s, x) => s + ((x['value'] as num?)?.toDouble() ?? 0));

  double convertedToYER(double amount, String currency) {
    if (currency == 'YER') return amount;
    if (currency == 'SAR') return amount * rates['SAR']!;
    return amount * rates['YER']!;
  }
}

class FishAccountsApp extends StatelessWidget {
  final AppStore store;
  const FishAccountsApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'حسابات الأسماك',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'sans',
          colorSchemeSeed: Colors.teal,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
          ),
        ),
        locale: const Locale('ar'),
        home: HomePage(store: store),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final AppStore store;
  const HomePage({super.key, required this.store});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(store: widget.store),
      ShipmentsPage(store: widget.store),
      CollectionsPage(store: widget.store),
      ExpensesPage(store: widget.store),
      StockPage(store: widget.store),
      SettingsPage(store: widget.store),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حسابات الأسماك'),
          centerTitle: true,
        ),
        body: pages[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.local_shipping), label: 'الشحنات'),
            NavigationDestination(icon: Icon(Icons.payments), label: 'التحصيل'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'المصروفات'),
            NavigationDestination(icon: Icon(Icons.inventory_2), label: 'المخزون'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  final AppStore store;
  const Dashboard({super.key, required this.store});

  Widget money(String c, double v) =>
      Card(child: ListTile(title: Text('إجمالي $c'), trailing: Text('${v.toStringAsFixed(2)} $c',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))));

  @override
  Widget build(BuildContext context) {
    final shippedY = store.shipmentValue('YER');
    final shippedS = store.shipmentValue('SAR');
    final shippedU = store.shipmentValue('USD');
    final collectedY = store.total('amount', 'YER', store.collections);
    final collectedS = store.total('amount', 'SAR', store.collections);
    final collectedU = store.total('amount', 'USD', store.collections);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('ملخص النشاط', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _stat('الشحنات', store.shipments.length.toString(), Icons.local_shipping)),
          const SizedBox(width: 8),
          Expanded(child: _stat('التحصيلات', store.collections.length.toString(), Icons.payments)),
          const SizedBox(width: 8),
          Expanded(child: _stat('المصروفات', store.expenses.length.toString(), Icons.receipt_long)),
        ]),
        const SizedBox(height: 16),
        const Text('قيمة الصادرات حسب العملة', style: TextStyle(fontWeight: FontWeight.bold)),
        money('USD', shippedU),
        money('SAR', shippedS),
        money('YER', shippedY),
        const SizedBox(height: 8),
        const Text('التحصيلات حسب العملة', style: TextStyle(fontWeight: FontWeight.bold)),
        money('USD', collectedU),
        money('SAR', collectedS),
        money('YER', collectedY),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('مهم'),
            subtitle: Text('لا يتم جمع العملات المختلفة مباشرة. التحويل إلى الريال اليمني يستخدم سعر الصرف المحفوظ: ${store.rates['YER']} YER/USD و ${store.rates['SAR']} SAR/USD.'),
          ),
        ),
      ],
    );
  }

  Widget _stat(String title, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [Icon(icon, size: 30), const SizedBox(height: 5), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(title)]),
    ),
  );
}

class ShipmentsPage extends StatelessWidget {
  final AppStore store;
  const ShipmentsPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      FilledButton.icon(
        onPressed: () => showDialog(context: context, builder: (_) => ShipmentDialog(store: store)),
        icon: const Icon(Icons.add),
        label: const Text('إضافة شحنة'),
      ),
      const SizedBox(height: 8),
      ...store.shipments.map((x) => Card(
        child: ListTile(
          leading: const Icon(Icons.local_shipping),
          title: Text('${x['fish']} — ${x['country']}'),
          subtitle: Text('${x['kg']} كجم | العميل: ${x['customer']} | ${x['date']}'),
          trailing: Text('${(x['value'] as num).toStringAsFixed(2)} ${x['currency']}'),
        ),
      )),
    ],
  );
}

class ShipmentDialog extends StatefulWidget {
  final AppStore store;
  const ShipmentDialog({super.key, required this.store});
  @override State<ShipmentDialog> createState() => _ShipmentDialogState();
}
class _ShipmentDialogState extends State<ShipmentDialog> {
  final fish = TextEditingController();
  final kg = TextEditingController();
  final price = TextEditingController();
  final country = TextEditingController();
  final customer = TextEditingController();
  final invoice = TextEditingController();
  String currency = 'USD';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('شحنة جديدة'),
    content: SingleChildScrollView(child: Column(children: [
      _f('الصنف', fish), _f('الكمية كجم', kg, type: TextInputType.number),
      _f('السعر لكل كجم', price, type: TextInputType.number),
      _f('الدولة', country), _f('العميل / المستورد', customer), _f('رقم الفاتورة', invoice),
      DropdownButtonFormField<String>(
        value: currency, decoration: const InputDecoration(labelText: 'العملة'),
        items: const ['USD','SAR','YER'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => currency = v!),
      ),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton(onPressed: () async {
        final q = double.tryParse(kg.text) ?? 0;
        final p = double.tryParse(price.text) ?? 0;
        await widget.store.addShipment({
          'date': DateTime.now().toIso8601String().substring(0,10),
          'fish': fish.text, 'kg': q, 'price': p, 'value': q*p,
          'country': country.text, 'customer': customer.text,
          'invoice': invoice.text, 'currency': currency,
        });
        if (context.mounted) Navigator.pop(context);
      }, child: const Text('حفظ')),
    ],
  );

  Widget _f(String label, TextEditingController c, {TextInputType? type}) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, keyboardType: type, decoration: InputDecoration(labelText: label)));
}

class CollectionsPage extends StatelessWidget {
  final AppStore store;
  const CollectionsPage({super.key, required this.store});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      FilledButton.icon(
        onPressed: () => showDialog(context: context, builder: (_) => CollectionDialog(store: store)),
        icon: const Icon(Icons.add),
        label: const Text('إضافة تحصيل'),
      ),
      ...store.collections.map((x) => Card(child: ListTile(
        title: Text('${x['customer']} — ${x['invoice']}'),
        subtitle: Text('${x['date']}'),
        trailing: Text('${(x['amount'] as num).toStringAsFixed(2)} ${x['currency']}'),
      ))),
    ],
  );
}

class CollectionDialog extends StatefulWidget {
  final AppStore store;
  const CollectionDialog({super.key, required this.store});
  @override State<CollectionDialog> createState() => _CollectionDialogState();
}
class _CollectionDialogState extends State<CollectionDialog> {
  final customer = TextEditingController();
  final invoice = TextEditingController();
  final amount = TextEditingController();
  String currency = 'USD';
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('تحصيل جديد'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      _f('العميل', customer), _f('الفاتورة', invoice), _f('المبلغ', amount, type: TextInputType.number),
      DropdownButtonFormField<String>(value: currency, decoration: const InputDecoration(labelText: 'العملة'),
        items: const ['USD','SAR','YER'].map((c)=>DropdownMenuItem(value:c,child:Text(c))).toList(),
        onChanged:(v)=>setState(()=>currency=v!)),
    ]),
    actions: [
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),
      FilledButton(onPressed:() async {
        await widget.store.addCollection({'date':DateTime.now().toIso8601String().substring(0,10),'customer':customer.text,'invoice':invoice.text,'amount':double.tryParse(amount.text)??0,'currency':currency});
        if(context.mounted) Navigator.pop(context);
      },child:const Text('حفظ')),
    ],
  );
  Widget _f(String l, TextEditingController c,{TextInputType? type})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,keyboardType:type,decoration:InputDecoration(labelText:l)));
}

class ExpensesPage extends StatelessWidget {
  final AppStore store;
  const ExpensesPage({super.key, required this.store});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(12),children:[
    FilledButton.icon(onPressed:()=>showDialog(context:context,builder:(_)=>ExpenseDialog(store:store)),icon:const Icon(Icons.add),label:const Text('إضافة مصروف')),
    ...store.expenses.map((x)=>Card(child:ListTile(title:Text('${x['category']}'),subtitle:Text('${x['date']} | ${x['note']}'),trailing:Text('${(x['amount'] as num).toStringAsFixed(2)} ${x['currency']}')))),
  ]);
}

class ExpenseDialog extends StatefulWidget {
  final AppStore store;
  const ExpenseDialog({super.key,required this.store});
  @override State<ExpenseDialog> createState()=>_ExpenseDialogState();
}
class _ExpenseDialogState extends State<ExpenseDialog>{
  final category=TextEditingController(); final amount=TextEditingController(); final note=TextEditingController(); String currency='YER';
  @override Widget build(BuildContext context)=>AlertDialog(title:const Text('مصروف جديد'),content:Column(mainAxisSize:MainAxisSize.min,children:[
    _f('البند',category),_f('المبلغ',amount,type:TextInputType.number),_f('ملاحظات',note),
    DropdownButtonFormField<String>(value:currency,decoration:const InputDecoration(labelText:'العملة'),items:const ['USD','SAR','YER'].map((c)=>DropdownMenuItem(value:c,child:Text(c))).toList(),onChanged:(v)=>setState(()=>currency=v!))
  ]),actions:[
    TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),
    FilledButton(onPressed:()async{await widget.store.addExpense({'date':DateTime.now().toIso8601String().substring(0,10),'category':category.text,'amount':double.tryParse(amount.text)??0,'note':note.text,'currency':currency});if(context.mounted)Navigator.pop(context);},child:const Text('حفظ'))
  ]);
  Widget _f(String l,TextEditingController c,{TextInputType? type})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,keyboardType:type,decoration:InputDecoration(labelText:l)));
}

class StockPage extends StatelessWidget {
  final AppStore store;
  const StockPage({super.key,required this.store});
  @override Widget build(BuildContext context){
    final Map<String,double> m={};
    for(final x in store.shipments){final k=x['fish'].toString();m[k]=(m[k]??0)+(x['kg'] as num).toDouble();}
    return ListView(padding:const EdgeInsets.all(12),children:[
      const Card(child:ListTile(title:Text('المخزون الحالي'),subtitle:Text('هذه النسخة تعرض كمية الصادرات المسجلة لكل صنف. سيتم تحويلها إلى دفتر مخزون فعلي في النسخة التالية.'))),
      ...m.entries.map((e)=>Card(child:ListTile(title:Text(e.key.isEmpty?'غير محدد':e.key),trailing:Text('${e.value.toStringAsFixed(2)} كجم'))))
    ]);
  }
}

class SettingsPage extends StatefulWidget {
  final AppStore store;
  const SettingsPage({super.key,required this.store});
  @override State<SettingsPage> createState()=>_SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage>{
  late final TextEditingController yer; late final TextEditingController sar;
  @override void initState(){super.initState();yer=TextEditingController(text:widget.store.rates['YER']!.toString());sar=TextEditingController(text:widget.store.rates['SAR']!.toString());}
  @override void dispose(){yer.dispose();sar.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('العملات وأسعار الصرف',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:12),
    TextField(controller:yer,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'1 USD = كم ريال يمني؟')),
    const SizedBox(height:10),
    TextField(controller:sar,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'1 USD = كم ريال سعودي؟')),
    const SizedBox(height:10),
    const Card(child:ListTile(title:Text('العملة الأساسية'),subtitle:Text('يمكن استخدام YER كأساس للتقارير بعد تطبيق التحويل حسب سعر الصرف المحفوظ.'))),
    FilledButton.icon(onPressed:()async{await widget.store.setRates({'YER':double.tryParse(yer.text)??530,'SAR':double.tryParse(sar.text)??3.75,'USD':1});if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ أسعار الصرف')));},icon:const Icon(Icons.save),label:const Text('حفظ أسعار الصرف')),
  ]);
}
