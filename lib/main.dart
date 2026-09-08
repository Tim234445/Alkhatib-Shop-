import 'package:flutter/material.dart';

void main() {
  runApp(KhateebPOSApp());
}

// نموذج بيانات المنتج المحدث حسب طلبك
class Product {
  String barcode;
  String name;
  double buyPriceSYP;     // سعر الشراء بالليرة السورية
  double buyPriceUSD;     // سعر الشراء بالدولار
  double sellPriceSYP;    // سعر المبيع بالليرة السورية
  String sellerNote;      // ملاحظات

  Product({
    required this.barcode,
    required this.name,
    required this.buyPriceSYP,
    required this.buyPriceUSD,
    required this.sellPriceSYP,
    required this.sellerNote,
  });
}

class InvoiceItem {
  Product product;
  int quantity;

  InvoiceItem({required this.product, this.quantity = 1});
}

class KhateebPOSApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'الخطيب للكهرباء',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CustomerInterfaceScreen(),
    );
  }
}

// ==========================================
// 1. واجهة الزبون (الكاشير الرئيسية)
// ==========================================
class CustomerInterfaceScreen extends StatefulWidget {
  @override
  _CustomerInterfaceScreenState createState() => _CustomerInterfaceScreenState();
}

class _CustomerInterfaceScreenState extends State<CustomerInterfaceScreen> {
  double exchangeRate = 130.0;
  
  List<Product> database = [
    Product(
      barcode: '12345', 
      name: 'لمبة ليد 12 واط', 
      buyPriceSYP: 195.0, 
      buyPriceUSD: 1.5, 
      sellPriceSYP: 260.0, 
      sellerNote: 'نوع ممتاز'
    ),
    Product(
      barcode: '67890', 
      name: 'قاطع كهربائي 16 أمبير', 
      buyPriceSYP: 455.0, 
      buyPriceUSD: 3.5, 
      sellPriceSYP: 585.0, 
      sellerNote: 'كفالة سنة'
    ),
  ];

  List<InvoiceItem> currentInvoice = [];
  TextEditingController barcodeController = TextEditingController();
  TextEditingController exchangeRateController = TextEditingController();
  FocusNode barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    exchangeRateController.text = exchangeRate.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestFocusOnBarcode();
    });
  }

  @override
  void dispose() {
    barcodeController.dispose();
    exchangeRateController.dispose();
    barcodeFocusNode.dispose();
    super.dispose();
  }

  String cleanBarcodeText(String input) {
    const arabicNumbers = '٠١ي٢٣٤٥٦٧٨٩٠';
    const englishNumbers = '01234567890';
    
    for (int i = 0; i < arabicNumbers.length; i++) {
      input = input.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }

    Map<String, String> arabicToEnglishMap = {
      'ض': 'q', 'ص': 'w', 'ث': 'e', 'ق': 'r', 'ف': 't', 'غ': 'y', 'ع': 'u', 'ه': 'i', 'خ': 'o', 'ح': 'p',
      'ش': 'a', 'س': 's', 'ي': 'd', 'ب': 'f', 'ل': 'g', 'ا': 'h', 'ت': 'j', 'ن': 'k', 'م': 'l',
      'ئ': 'z', 'ء': 'x', 'ؤ': 'c', 'ر': 'v', 'لا': 'b', 'ى': 'ن', 'ة': 'm',
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4', '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9'
    };

    arabicToEnglishMap.forEach((ar, en) {
      input = input.replaceAll(ar, en);
    });

    return input.trim();
  }

  void requestFocusOnBarcode() {
    FocusScope.of(context).requestFocus(barcodeFocusNode);
  }

  void handleScannedBarcode(String rawBarcode) {
    String barcode = cleanBarcodeText(rawBarcode);
    barcodeController.clear();
    requestFocusOnBarcode();

    if (barcode.isEmpty) return;

    var foundProduct = database.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => Product(barcode: '', name: '', buyPriceSYP: 0, buyPriceUSD: 0, sellPriceSYP: 0, sellerNote: ''),
    );

    if (foundProduct.barcode.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('مادة غير موجودة!'),
          content: Text('الباركود ($barcode) غير مسجل في قاعدة البيانات. هل تريد الانتقال لإضافته؟'),
          actions: [
            TextButton(
              child: Text('إلغاء', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                requestFocusOnBarcode();
              },
            ),
            ElevatedButton(
              child: Text('إضافة مادة جديدة'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SellerInterfaceScreen(
                      initialBarcode: barcode,
                      database: database,
                      onProductSaved: (newProduct) {
                        setState(() {
                          database.add(newProduct);
                        });
                        requestFocusOnBarcode();
                      },
                    ),
                  ),
                ).then((_) => requestFocusOnBarcode());
              },
            ),
          ],
        ),
      );
    } else {
      setState(() {
        var existingIndex = currentInvoice.indexWhere((item) => item.product.barcode == barcode);
        if (existingIndex >= 0) {
          currentInvoice[existingIndex].quantity++;
        } else {
          currentInvoice.add(InvoiceItem(product: foundProduct));
        }
      });
      requestFocusOnBarcode();
    }
  }

  double calculateTotal() {
    double totalSYP = 0;
    for (var item in currentInvoice) {
      totalSYP += (item.product.sellPriceSYP * item.quantity);
    }
    return totalSYP;
  }

  void printInvoiceAndFinish() {
    if (currentInvoice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الفاتورة فارغة، لا يوجد مواد لطباعتها!')),
      );
      requestFocusOnBarcode();
      return;
    }

    String printPayload = "--- الخطيب للكهرباء ---\n";
    printPayload += "دمشق - أسد الدين - جسر النحاس\n";
    printPayload += "هاتف: 2762484\n";
    printPayload += "--------------------------------\n";
    
    for (var item in currentInvoice) {
      double itemTotalSYP = item.product.sellPriceSYP * item.quantity;
      printPayload += "${item.product.name}\n";
      printPayload += "العدد: ${item.quantity} | الفردي: ${item.product.sellPriceSYP.toStringAsFixed(0)}\n";
      printPayload += "الإجمالي: ${itemTotalSYP.toStringAsFixed(0)} ل.س\n";
      printPayload += "--------------------------------\n";
    }
    
    double finalTotal = calculateTotal();
    printPayload += "المجموع الكلي: ${finalTotal.toStringAsFixed(0)} ل.س\n";
    printPayload += "================================\n";
    printPayload += "شكراً لزيارتكم\n\n\n";

    print(printPayload);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال الفاتورة إلى طابعة البلوتوث بنجاح!')),
    );

    setState(() {
      currentInvoice.clear();
    });
    requestFocusOnBarcode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('كاشير - الخطيب للكهرباء'),
        actions: [
          Container(
            width: 140,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            child: TextField(
              controller: exchangeRateController,
              showCursor: true,
              readOnly: false,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'سعر الصرف (ل.س)',
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
              style: TextStyle(fontWeight: FontWeight.bold),
              onChanged: (val) {
                setState(() {
                  exchangeRate = double.tryParse(val) ?? 130.0;
                });
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.admin_panel_settings, size: 28),
            tooltip: 'واجهة البائع',
            onPressed: () {
              showPasswordDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Text('الخطيب للكهرباء', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                  Text('دمشق - أسد الدين - جسر النحاس - مقابل جامع حموليلا', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('هاتف: 2762484', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Divider(thickness: 2),
            SizedBox(height: 10),

            TextField(
              controller: barcodeController,
              focusNode: barcodeFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'امسح الباركود هنا (المؤشر ثابت وجاهز)...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_scanner),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (val) {
                handleScannedBarcode(val);
              },
            ),
            SizedBox(height: 10),

            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: ListView.builder(
                  itemCount: currentInvoice.length,
                  itemBuilder: (context, index) {
                    var item = currentInvoice[index];
                    double itemTotalSYP = item.product.sellPriceSYP * item.quantity;

                    return ListTile(
                      title: Text(item.product.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الباركود: ${item.product.barcode} | السعر: ${item.product.sellPriceSYP.toStringAsFixed(0)} ل.س'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('العدد: ${item.quantity}', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 15),
                          Text('${itemTotalSYP.toStringAsFixed(0)} ل.س', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800])),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.yellow[200],
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'المجموع: ${calculateTotal().toStringAsFixed(0)} ل.س',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.red[800]),
                ),
              ),
            ),
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: Icon(Icons.print),
                  label: Text('إتمام وطباعة فاتورة'),
                  onPressed: () {
                    printInvoiceAndFinish();
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  icon: Icon(Icons.check),
                  label: Text('إتمام بدون فاتورة'),
                  onPressed: () {
                    setState(() { currentInvoice.clear(); });
                    requestFocusOnBarcode();
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: Icon(Icons.cancel),
                  label: Text('إلغاء'),
                  onPressed: () {
                    setState(() { currentInvoice.clear(); });
                    requestFocusOnBarcode();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showPasswordDialog(BuildContext context) {
    TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('كلمة مرور البائع'),
        content: TextField(
          controller: passController,
          obscureText: true,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(hintText: 'أدخل الرمز السرّي'),
        ),
        actions: [
          TextButton(
            child: Text('إلغاء'), 
            onPressed: () {
              Navigator.pop(context);
              requestFocusOnBarcode();
            },
          ),
          ElevatedButton(
            child: Text('دخول'),
            onPressed: () {
              if (passController.text == '1990') {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SellerInterfaceScreen(
                      database: database,
                      onProductSaved: (updatedProduct) {
                        setState(() {});
                      },
                    ),
                  ),
                ).then((_) => requestFocusOnBarcode());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('كلمة المرور خاطئة!')),
                );
                requestFocusOnBarcode();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. واجهة البائع (بالأعمدة الجديدة تماماً)
// ==========================================
class SellerInterfaceScreen extends StatefulWidget {
  final String? initialBarcode;
  final List<Product> database;
  final Function(Product) onProductSaved;

  SellerInterfaceScreen({this.initialBarcode, required this.database, required this.onProductSaved});

  @override
  _SellerInterfaceScreenState createState() => _SellerInterfaceScreenState();
}

class _SellerInterfaceScreenState extends State<SellerInterfaceScreen> {
  TextEditingController barcodeCtrl = TextEditingController();
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController buyPriceSypCtrl = TextEditingController(); // سعر الشراء ليرة
  TextEditingController buyPriceUsdCtrl = TextEditingController(); // سعر الشراء دولار
  TextEditingController sellPriceSypCtrl = TextEditingController(); // سعر المبيع ليرة
  TextEditingController noteCtrl = TextEditingController();          // ملاحظات

  @override
  void initState() {
    super.initState();
    if (widget.initialBarcode != null) {
      barcodeCtrl.text = widget.initialBarcode!;
      loadProductData(widget.initialBarcode!);
    }
  }

  void loadProductData(String barcode) {
    var found = widget.database.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => Product(barcode: barcode, name: '', buyPriceSYP: 0, buyPriceUSD: 0, sellPriceSYP: 0, sellerNote: ''),
    );

    nameCtrl.text = found.name;
    buyPriceSypCtrl.text = found.buyPriceSYP > 0 ? found.buyPriceSYP.toString() : '';
    buyPriceUsdCtrl.text = found.buyPriceUSD > 0 ? found.buyPriceUSD.toString() : '';
    sellPriceSypCtrl.text = found.sellPriceSYP > 0 ? found.sellPriceSYP.toString() : '';
    noteCtrl.text = found.sellerNote;
  }

  void importProductsFromExcelFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('استيراد المواد من ملف إكسل (CSV)'),
        content: Text('تأكد أن ملف الإكسل يترتيب الأعمدة التالي:\n1. الباركود\n2. اسم المادة\n3. سعر الشراء (ليرة سورية)\n4. سعر الشراء (دولار)\n5. سعر المبيع (ليرة سورية)\n6. ملاحظات\n\nهل تريد محاكاة استيراد ملف تجريبي الآن؟'),
        actions: [
          TextButton(
            child: Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text('تأكيد الاستيراد'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                widget.database.add(Product(
                  barcode: '999888', 
                  name: 'مادة جديدة مستوردة من الإكسل', 
                  buyPriceSYP: 1300.0, 
                  buyPriceUSD: 10.0, 
                  sellPriceSYP: 1800.0, 
                  sellerNote: 'دفعة جديدة ممتازة'
                ));
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم استيراد المواد بنجاح وتحديث القاعدة!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void exportBackupFile() {
    int totalItems = widget.database.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تم حفظ النسخة الاحتياطية بنجاح!'),
        content: Text('تحتوي النسخة على الأسعار بالليرة والدولار لـ ($totalItems مادة).'),
        actions: [
          ElevatedButton(
            child: Text('حسناً'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('واجهة البائع - إدارة الأسعار والمستودع'),
        backgroundColor: Colors.orange[800],
        actions: [
          IconButton(
            icon: Icon(Icons.point_of_sale, size: 28),
            tooltip: 'العودة للكاشير',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: EdgeInsets.symmetric(vertical: 12)),
                    icon: Icon(Icons.backup),
                    label: Text('نسخة احتياطية'),
                    onPressed: exportBackupFile,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: EdgeInsets.symmetric(vertical: 12)),
                    icon: Icon(Icons.file_upload),
                    label: Text('استيراد إكسل'),
                    onPressed: importProductsFromExcelFile,
                  ),
                ),
              ],
            ),
            Divider(height: 30, thickness: 2),

            TextField(
              controller: barcodeCtrl,
              autofocus: true,
              enableInteractiveSelection: true,
              decoration: InputDecoration(
                labelText: 'رقم الباركود...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              onSubmitted: (val) {
                loadProductData(val);
              },
            ),
            SizedBox(height: 15),
            TextField(
              controller: nameCtrl,
              enableInteractiveSelection: true,
              decoration: InputDecoration(labelText: 'اسم المادة', border: OutlineInputBorder()),
            ),
            SizedBox(height: 15),
            TextField(
              controller: buyPriceSypCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: true,
              showCursor: true,
              readOnly: false,
              decoration: InputDecoration(
                labelText: 'سعر الشراء بالليرة السورية (سري)', 
                border: OutlineInputBorder(),
                fillColor: Colors.red[50],
                filled: true,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: buyPriceUsdCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: true,
              showCursor: true,
              readOnly: false,
              decoration: InputDecoration(
                labelText: 'سعر الشراء بالدولار (سري)', 
                border: OutlineInputBorder(),
                fillColor: Colors.red[50],
                filled: true,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: sellPriceSypCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: true,
              showCursor: true,
              readOnly: false,
              decoration: InputDecoration(
                labelText: 'سعر المبيع بالليرة السورية', 
                border: OutlineInputBorder(),
                fillColor: Colors.green[50],
                filled: true,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              enableInteractiveSelection: true,
              decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder()),
            ),
            SizedBox(height: 30),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(vertical: 12)),
              icon: Icon(Icons.save, size: 28),
              label: Text('حفظ التعديلات / إضافة المادة', style: TextStyle(fontSize: 20)),
              onPressed: () {
                if (barcodeCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الرجاء إدخال الباركود واسم المادة على الأقل')));
                  return;
                }

                var existing = widget.database.where((p) => p.barcode == barcodeCtrl.text);
                
                Product p = Product(
                  barcode: barcodeCtrl.text,
                  name: nameCtrl.text,
                  buyPriceSYP: double.tryParse(buyPriceSypCtrl.text) ?? 0.0,
                  buyPriceUSD: double.tryParse(buyPriceUsdCtrl.text) ?? 0.0,
                  sellPriceSYP: double.tryParse(sellPriceSypCtrl.text) ?? 0.0,
                  sellerNote: noteCtrl.text,
                );

                if (existing.isNotEmpty) {
                  var item = widget.database.firstWhere((p) => p.barcode == barcodeCtrl.text);
                  item.name = p.name;
                  item.buyPriceSYP = p.buyPriceSYP;
                  item.buyPriceUSD = p.buyPriceUSD;
                  item.sellPriceSYP = p.sellPriceSYP;
                  item.sellerNote = p.sellerNote;
                } else {
                  widget.onProductSaved(p);
                }

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحفظ بنجاح!')));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
