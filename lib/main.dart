import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// استيراد مكتبة طباعة البلوتوث ESC/POS
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(const AlKhatibShopApp());
}

class AlKhatibShopApp extends StatelessWidget {
  const AlKhatibShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كاشير الخطيب للكهرباء',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const POSHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  State<POSHomePage> createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  // رابط جدول Google Sheets (CSV)
  final String sheetUrl = 'رابط_الـ_CSV_الخاص_بك_هنا';
  
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> cart = [];
  bool isLoading = true;

  // متغيرات البلوتوث للطابعة
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    getBluetoothDevices();
  }

  // 1. جلب المنتجات من Google Sheets
  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(sheetUrl));
      if (response.statusCode == 200) {
        // تحليل البيانات الواردة من الجدول
        // (يمكنك تعديل طريقة التقسيم حسب تصميم جدولك)
        List<String> rows = response.body.split('\n');
        List<Map<String, dynamic>> loadedProducts = [];
        
        for (int i = 1; i < rows.length; i++) {
          if (rows[i].trim().isEmpty) continue;
          List<String> cols = rows[i].split(',');
          if (cols.length >= 3) {
            loadedProducts.add({
              'name': cols[0].trim(),
              'price': double.tryParse(cols[1].trim()) ?? 0.0,
              'stock': int.tryParse(cols[2].trim()) ?? 0,
            });
          }
        }
        setState(() {
          products = loadedProducts;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 2. البحث عن الأجهزة المقترنة (البلوتوث)
  Future<void> getBluetoothDevices() async {
    try {
      List<BluetoothDevice> r = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        devices = r;
      });
    } catch (e) {
      // التعامل مع حالة عدم توفر البلوتوث أو الأذونات
    }
  }

  // 3. طباعة الفاتورة عبر الطابعة الحرارية
  Future<void> printReceipt() async {
    if (selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        constSnackBar(content: Text('الرجاء اختيار الطابعة الحرارية أولاً!')),
      );
      return;
    }

    try {
      // الاتصال بالطابعة
      BluetoothConnection connection = await BluetoothConnection.toAddress(selectedDevice!.address);
      
      // تجهيز نص الفاتورة بتنسيق ESC/POS مبسط
      String receiptText = "\n   مؤسسة الخطيب للكهرباء\n";
      receiptText += "--------------------------------\n";
      for (var item in cart) {
        receiptText += "${item['name']} x${item['qty']} - ${item['price'] * item['qty']} ل.س\n";
      }
      receiptText += "--------------------------------\n";
      receiptText += "الإجمالي الكلي: ${calculateTotal()} ل.س\n";
      receiptText += "شكراً لزيارتكم!\n\n\n";

      // إرسال البيانات للطابعة
      connection.output.add(utf8.encode(receiptText));
      await connection.output.allSent;
      
      connection.close();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الطباعة بنجاح!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاتصال بالطابعة: $e')),
      );
    }
  }

  double calculateTotal() {
    double total = 0;
    for (var item in cart) {
      total += (item['price'] * item['qty']);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كاشير الخطيب للكهرباء'),
        actions: [
          // قائمة منسدلة لاختيار الطابعة الحرارية
          DropdownButton<BluetoothDevice>(
            hint: const Text('اختر الطابعة', style: TextStyle(color: Colors.white)),
            value: selectedDevice,
            items: devices.map((device) {
              return DropdownMenuItem(
                value: device,
                child: Text(device.name ?? "طابعة مجهولة"),
              );
            }).toList(),
            onChanged: (device) {
              setState(() {
                selectedDevice = device;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchProducts,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // قسم المنتجات
                Expanded(
                  flex: 2,
                  content: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final prod = products[index];
                      return Card(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              cart.add({
                                'name': prod['name'],
                                'price': prod['price'],
                                'qty': 1,
                              });
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${prod['price']} ل.س'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // قسم السلة والفاتورة والطباعة
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.grey[200],
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('سلة المشتريات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: cart.length,
                            itemBuilder: (context, index) {
                              final item = cart[index];
                              return ListTile(
                                title: Text(item['name']),
                                subtitle: Text('${item['price']} ل.س'),
                                trailing: Text('x${item['qty']}'),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('الإجمالي: ${calculateTotal()} ل.س', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                                onPressed: printReceipt,
                                icon: const Icon(Icons.print),
                                label: const Text('طباعة الفاتورة'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
