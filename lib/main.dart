import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AlKhatibPOSApp());
}

class AlKhatibPOSApp extends StatelessWidget {
  const AlKhatibPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كاشير - الخطيب للكهرباء',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const POSScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  // رابط الـ CSV المباشر والنهائي لجدول "بضائع المحل" الخاص بك
  final String sheetUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSzYRMUtZRPznTdbguLz8PLDOGurW3HSNg-Kp-VCnMm8zsjgug2xK8a6JEUSt16WpNWpA6WlZYPgvhE/pub?gid=1136409100&single=true&output=csv';

  Map<String, Map<String, dynamic>> productsDb = {};
  List<Map<String, dynamic>> cart = [];
  bool isLoading = true;
  double exchangeRate = 140.0;
  final TextEditingController barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGoogleSheetData();
  }

  // سحب البيانات من الأعمدة المطابقة لجدولك (A: رقم الباركود, B: اسم المادة, E: سعر المبيع بالليرة)
  Future<void> fetchGoogleSheetData() async {
    try {
      final response = await http.get(Uri.parse(sheetUrl));
      if (response.statusCode == 200) {
        List<String> rows = response.body.split('\n');
        Map<String, Map<String, dynamic>> loadedProducts = {};

        for (int i = 1; i < rows.length; i++) {
          if (rows[i].trim().isEmpty) continue;
          List<String> cols = rows[i].split(',');
          if (cols.length >= 5) {
            String barcode = cols[0].trim(); // العمود A: رقم الباركود
            String name = cols[1].trim();    // العمود B: اسم المادة
            double sellPrice = double.tryParse(cols[4].trim()) ?? 0.0; // العمود E: سعر المبيع بالليرة

            if (barcode.isNotEmpty) {
              loadedProducts[barcode] = {
                'name': name,
                'price': sellPrice,
              };
            }
          }
        }
        setState(() {
          productsDb = loadedProducts;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // معالجة الباركود الممسوح بالسكنر
  void handleBarcodeScanned(String barcode) {
    if (barcode.isEmpty) return;
    String cleanBarcode = barcode.trim();

    if (productsDb.containsKey(cleanBarcode)) {
      var product = productsDb[cleanBarcode]!;
      setState(() {
        int index = cart.indexWhere((item) => item['barcode'] == cleanBarcode);
        if (index >= 0) {
          cart[index]['qty'] += 1;
        } else {
          cart.add({
            'barcode': cleanBarcode,
            'name': product['name'],
            'price': product['price'],
            'qty': 1,
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الباركود غير موجود في جدول بضائع المحل!')),
      );
    }
    barcodeController.clear();
  }

  double calculateTotal() {
    double total = 0;
    for (var item in cart) {
      total += (item['price'] * item['qty']);
    }
    return total;
  }

  void printInvoice(bool withInvoice) {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('السلة فارغة!')),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(withInvoice ? 'تم إتمام البيع وطباعة الفاتورة بنجاح!' : 'تم إتمام البيع (بدون فاتورة)!')),
    );

    setState(() {
      cart.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كاشير - الخطيب للكهرباء'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'سعر الصرف: $exchangeRate',
                  style: const TextStyle(color: Colors.black85, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ترويسة المحل
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.blue.shade50,
                  child: Column(
                    children: const [
                      Text(
                        'الخطيب للكهرباء',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'دمشق - أسد الدين - جسر النحاس - مقابل جامع حموليلا | هاتف: 2762484',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                
                // خانة مسح الباركود
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: barcodeController,
                    autofocus: true,
                    onSubmitted: handleBarcodeScanned,
                    decoration: InputDecoration(
                      labelText: '...امسح الباركود هنا',
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),

                // جدول المشتريات
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          color: Colors.blue.shade100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Expanded(flex: 2, child: Text('الباركود', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 3, child: Text('اسم المادة', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('السعر الفردي', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: cart.isEmpty
                              ? const Center(
                                  child: Text(
                                    'لم يتم اختيار أي مادة بعد. امسح الباركود للبدء.',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: cart.length,
                                  itemBuilder: (context, index) {
                                    final item = cart[index];
                                    double itemTotal = item['price'] * item['qty'];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(flex: 2, child: Text(item['barcode'])),
                                          Expanded(flex: 3, child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Text('${item['price']} ل.س')),
                                          Expanded(flex: 1, child: Text('${item['qty']}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Text('$itemTotal ل.س', style: const TextStyle(fontWeight: FontWeight.bold))),
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

                // شريط المجموع العام
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.amber.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        ':المجموع العام',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${calculateTotal()} ل.س',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ),

                // الأزرار السفلية
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              cart.clear();
                            });
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('إلغاء', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => printInvoice(false),
                          icon: const Icon(Icons.flash_on),
                          label: const Text('بدون فاتورة', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => printInvoice(true),
                          icon: const Icon(Icons.print),
                          label: const Text('مع فاتورة', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
