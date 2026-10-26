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
      title: 'كاشير الخطيب',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFE3F2FD), // لون أزرق فاتح
      ),
      home: const PosHomePage(),
    );
  }
}

class PosHomePage extends StatefulWidget {
  const PosHomePage({Key? key}) : super(key: key);

  @override
  State<PosHomePage> createState() => _PosHomePageState();
}

class _PosHomePageState extends State<PosHomePage> {
  // سعر الصرف الافتراضي 140 ل.س
  double exchangeRate = 140.0;
  double totalAmount = 0.0;
  
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade300,
        title: const Text('كاشير - الخطيب للكهرباء'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Center(
              child: Text(
                'سعر الصرف: $exchangeRate ل.س',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    'الخطيب للكهرباء',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'دمشق - أسد الدين - جسر النحاس - مقابل جامع حموليلا',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'هاتف: 2762484',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // حقل الباركود مع التركيز التلقائي المستمر
            TextField(
              controller: _barcodeController,
              focusNode: _barcodeFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'امسح الباركود هنا (المؤشر ثابت وجاهز)',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (value) {
                // منطق معالجة الباركود الممسوح
                if (value.isNotEmpty) {
                  setState(() {
                    totalAmount += 1000; // مثال تجريبي لزيادة المجموع عند مسح قطعة
                  });
                  _barcodeController.clear();
                  // إعادة التركيز تلقائياً للمسح التالي
                  FocusScope.of(context).requestFocus(_barcodeFocusNode);
                }
              },
            ),
            const SizedBox(height: 12),

            // منطقة عرض المجموع بشكل كبير
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.amber.shade400, width: 2),
                ),
                child: Center(
                  child: Text(
                    'المجموع: $totalAmount ل.س',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      // رفع الأزرار السفلية عبر استخدام bottomNavigationBar مع حشوة أمان للأندرويد والتابلت
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 24),
        color: const Color(0xFFE3F2FD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        totalAmount = 0.0;
                      });
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('إلغاء العملية'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // الحساب مع طباعة فاتورة
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('حساب مع فاتورة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // الحساب بدون فاتورة
                },
                icon: const Icon(Icons.money),
                label: const Text('حساب بدون فاتورة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
