import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http' as http;

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

class Product {
  final String barcode;
  final String name;
  final double price;
  final int quantity;

  Product({
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
  });
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
  // روابط الربط المباشر مع Google Sheets و Apps Script
  final String csvUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSzYRMUtZRPznTdbguLz8PLDOGurW3HSNg-Kp-VCnMm8zsjgug2xK8a6JEUSt16WpNWpA6WlZYPgvhE/pub?gid=1136409100&single=true&output=csv';
  final String scriptUrl = 'https://script.google.com/macros/s/AKfycby-HZD-PkGFvI7FpvMRg0SLNGrhEN0YOUYV78uBXNkuc04JQ6t6TcAN2k0ZBzmr9D1mkA/exec';

  Map<String, Product> _productsDatabase = {};
  final List<CartItem> _cartItems = [];
  bool _isLoadingProducts = true;
  double _exchangeRate = 140.0;
  
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _exchangeRateController.text = _exchangeRate.toString();
    _fetchProducts();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _exchangeRateController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  // دالة جلب البيانات آلياً من رابط Google Sheets Mapped CSV
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final response = await http.get(Uri.parse(csvUrl));
      if (response.statusCode == 200) {
        List<String> lines = response.body.split('\n');
        Map<String, Product> tempDb = {};

        for (int i = 1; i < lines.length; i++) {
          if (lines[i].trim().isEmpty) continue;
          List<String> row = lines[i].split(',');

          if (row.length >= 6) {
            String barcode = row[0].trim();
            String name = row[1].trim();
            double price = double.tryParse(row[3].replaceAll('€', '').trim()) ?? 0.0;
            int qty = int.tryParse(row[5].trim()) ?? 0;

            tempDb[barcode] = Product(
              barcode: barcode,
              name: name,
              price: price,
              quantity: qty,
            );
          }
        }

        setState(() {
          _productsDatabase = tempDb;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في جلب بيانات الجدول: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // دالة إرسال التحديث لإنقاص المخزون تلقائياً عبر Apps Script
  Future<void> _sendSaleToGoogleSheets(List<CartItem> soldItems) async {
    try {
      final Map<String, dynamic> payload = {
        "items": soldItems.map((item) => {
          "barcode": item.barcode,
          "quantity": item.quantity,
        }).toList(),
      };

      await http.post(
        Uri.parse(scriptUrl),
        body: jsonEncode(payload),
        headers: {"Content-Type": "application/json"},
      );
    } catch (e) {
      print("خطأ في مزامنة المخزون: $e");
    }
  }

  void _addItemByBarcode(String barcode) {
    if (_productsDatabase.containsKey(barcode)) {
      final product = _productsDatabase[barcode]!;
      setState(() {
        final existingIndex = _cartItems.indexWhere((element) => element.barcode == barcode);
        if (existingIndex >= 0) {
          _cartItems[existingIndex].quantity += 1;
        } else {
          _cartItems.add(CartItem(
            barcode: barcode,
            name: product.name,
            price: product.price,
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

  void _printReceipt({bool withReceipt = true}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(withReceipt ? 'فاتورة مبيعات' : 'إتمام البيع السريع', textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (withReceipt) ...[
                const Text('الخطيب للكهرباء', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('دمشق - أسد الدين - جسر النحاس\nمقابل جامع حموليلا\nهاتف: 2762484', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                const Divider(),
              ],
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
              if (withReceipt) ...[
                const SizedBox(height: 10),
                const Text('شكراً لزيارتكم', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // إرسال الخصم لـ Google Sheets بدون إيقاف أو تعطيل العملية
              _sendSaleToGoogleSheets(List.from(_cartItems));

              setState(() {
                _cartItems.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(withReceipt ? 'تمت عملية البيع بنجاح وتحديث الجدول' : 'تم إتمام البيع بنجاح')),
              );
            },
            child: Text(withReceipt ? 'تأكيد وطباعة' : 'تأكيد البيع'),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchProducts,
            tooltip: 'تحديث المنتجات',
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: 130,
                child: TextField(
                  controller: _exchangeRateController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'سعر الصرف',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
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
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  Expanded(
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12.0),
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
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                        Text(
                          '$_grandTotal ل.س',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  label: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                  onPressed: _cartItems.isEmpty ? null : () => _printReceipt(withReceipt: false),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('بدون فاتورة'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
                  onPressed: _cartItems.isEmpty ? null : () => _printReceipt(withReceipt: true),
                  icon: const Icon(Icons.print),
                  label: const Text('مع فاتورة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
