import 'package:flutter/material.dart';

void main() {
  runApp(const KhatibPosApp());
}

class KhatibPosApp extends StatelessWidget {
  const KhatibPosApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'كاشير الخطيب للكهرباء',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFE3F2FD),
      ),
      home: const PosHomePage(),
    );
  }
}

class CartItem {
  final String barcode;
  final String name;
  double price;
  int quantity;

  CartItem({
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}

class PosHomePage extends StatefulWidget {
  const PosHomePage({Key? key}) : super(key: key);

  @override
  State<PosHomePage> createState() => _PosHomePageState();
}

class _PosHomePageState extends State<PosHomePage> {
  // قاعدة بيانات تجريبية تحاكي ملف Google Sheets الخاص بك
  final Map<String, Map<String, dynamic>> _mockDatabase = {
    '123451': {'name': 'لمبة نيون', 'price': 35.0},
    '123452': {'name': 'ستارتر', 'price': 50.0},
    '123453': {'name': 'ترنس نيون', 'price': 35.0},
    '1234560': {'name': 'بريز ظاهر', 'price': 35.0},
    '123454': {'name': 'شاسيه مجوز', 'price': 23.0},
  };

  final List<CartItem> _cartItems = [];
  double _exchangeRate = 150.0; // سعر الصرف القابل للتعديل
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _exchangeRateController.text = _exchangeRate.toString();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _exchangeRateController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _addItemByBarcode(String barcode) {
    if (_mockDatabase.containsKey(barcode)) {
      final itemData = _mockDatabase[barcode]!;
      setState(() {
        final existingIndex = _cartItems.indexWhere((element) => element.barcode == barcode);
        if (existingIndex >= 0) {
          _cartItems[existingIndex].quantity += 1;
        } else {
          _cartItems.add(CartItem(
            barcode: barcode,
            name: itemData['name'],
            price: itemData['price'],
            quantity: 1,
          ));
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('البار كود غير موجود في قاعدة البيانات!'), backgroundColor: Colors.red),
      );
    }
    _barcodeController.clear();
    FocusScope.of(context).requestFocus(_barcodeFocusNode);
  }

  double get _grandTotal {
    return _cartItems.fold(0, (sum, item) => sum + item.total);
  }

  void _printReceipt() {
    // معاينة الفاتورة قبل الطباعة أو إرسالها للطابعة
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فاتورة مبيعات', textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('الخطيب للكهرباء', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('دمشق - أسد الدين - جسر النحاس\nمقابل جامع حموليلا\nهاتف: 2762484', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
              const Divider(),
              ..._cartItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 3, child: Text(item.name, textAlign: TextAlign.right)),
                    Expanded(flex: 1, child: Text('${item.quantity}x', textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('${item.total} ل.س', textAlign: TextAlign.left)),
                  ],
                ),
              )),
              const Divider(),
              Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المجموع الكلي:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('$_grandTotal ل.س', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 10),
              const Text('شكراً لزيارتكم', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _cartItems.clear(); // تفريغ السلة بعد إتمام الفاتورة
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت طباعة الفاتورة بنجاح')),
              );
            },
            child: const Text('تأكيد وطباعة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text('كاشير - الخطيب للكهرباء', style: TextStyle(color: Colors.white)),
        actions: [
          // حقل تعديل سعر الصرف
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: 130,
                child: TextField(
                  controller: _exchangeRateController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'سعر الصرف',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white70)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white)),
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    setState(() {
                      _exchangeRate = double.tryParse(val) ?? _exchangeRate;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات المحل
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5)],
              ),
              child: const Column(
                children: [
                  Text('الخطيب للكهرباء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  SizedBox(height: 2),
                  Text('دمشق - أسد الدين - جسر النحاس - مقابل جامع حموليلا | هاتف: 2762484', style: TextStyle(fontSize: 12, color: Colors.black87), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // حقل إدخال الباركود عبر السكانر
            TextField(
              controller: _barcodeController,
              focusNode: _barcodeFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'امسح الباركود هنا...',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addItemByBarcode(value.trim());
                }
              },
            ),
            const SizedBox(height: 10),

            // جدول المواد (الباركود - اسم المادة - السعر الفردي - الكمية - المجموع)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      color: Colors.blue.shade100,
                      child: const Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(flex: 2, child: Text('الباركود', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          Expanded(flex: 3, child: Text('اسم المادة', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          Expanded(flex: 2, child: Text('السعر الفردي', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 1, child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.left)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _cartItems.isEmpty
                          ? const Center(child: Text('لم يتم اختيار أي مادة بعد. امسح الباركود للبدء.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: _cartItems.length,
                              itemBuilder: (context, index) {
                                final item = _cartItems[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                  child: Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      Expanded(flex: 2, child: Text(item.barcode, textAlign: TextAlign.right)),
                                      Expanded(flex: 3, child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                      Expanded(flex: 2, child: Text('${item.price}', textAlign: TextAlign.center)),
                                      Expanded(flex: 1, child: Text(item.quantity.toString(), textAlign: TextAlign.center)),
                                      Expanded(flex: 2, child: Text('${item.total}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), textAlign: TextAlign.left)),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // مربع المجموع العام الكبير والواضح
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.amber.shade600, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: TextDirection.rtl,
                children: [
                  const Text(
                    'المجموع العام:',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                  Text(
                    '$_grandTotal ل.س',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // الأزرار السفلية
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 20),
        color: const Color(0xFFE3F2FD),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
                onPressed: () {
                  setState(() {
                    _cartItems.clear();
                  });
                },
                icon: const Icon(Icons.cancel),
                label: const Text('إلغاء العملية'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
                onPressed: _cartItems.isEmpty ? null : _printReceipt,
                icon: const Icon(Icons.print),
                label: const Text('حساب مع فاتورة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
