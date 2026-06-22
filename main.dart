import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(RestaurantApp());

class RestaurantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Cairo',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
        ),
      ),
      home: HomeScreen(),
    );
  }
}

// ===== عدل بيانات المطعم هنا =====
const String restaurantName = 'مطعم الشيف عبده';
const String whatsappNumber = '967759470643';
const String deliveryFee = '10';
// ================================

class Product {
  final String name, category, img;
  final int price;
  int qty;
  Product({required this.name, required this.price, required this.category, required this.img, this.qty = 0});
}

class CartModel extends ChangeNotifier {
  final List<Product> _items = [];
  String note = '';
  bool isDelivery = true;

  List<Product> get items => _items;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.qty);
  int get subtotal => _items.fold(0, (sum, item) => sum + (item.price * item.qty));
  int get total => subtotal + (isDelivery? int.parse(deliveryFee) : 0);

  void add(Product p) {
    var index = _items.indexWhere((e) => e.name == p.name);
    if (index!= -1) {
      _items[index].qty++;
    } else {
      p.qty = 1;
      _items.add(p);
    }
    notifyListeners();
  }

  void remove(Product p) {
    var index = _items.indexWhere((e) => e.name == p.name);
    if (index!= -1) {
      if (_items[index].qty > 1) {
        _items[index].qty--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    note = '';
    notifyListeners();
  }

  String get orderText {
    String order = '*طلب جديد من $restaurantName*\n\n';
    for (var item in _items) {
      order += '${item.img} ${item.name} x${item.qty} = ${item.price * item.qty} ريال\n';
    }
    order += '\n------------------------\n';
    order += 'المجموع: $subtotal ريال\n';
    order += isDelivery? 'التوصيل: $deliveryFee ريال\n' : 'استلام من الفرع\n';
    order += '*الإجمالي: $total ريال*\n\n';
    if (note.isNotEmpty) order += 'ملاحظة: $note\n\n';
    order += isDelivery? '📍 أرسل موقعك' : '📍 بجي أستلم';
    return order;
  }
}

final cart = CartModel();

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCat = 'الكل';
  String search = '';

  // ===== منيو المطعم - غير الصور والأسعار براحتك =====
  final List<Product> allProducts = [
    Product(name: 'برجر لحم سبيشل', price: 22, category: 'برجر', img: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400'),
    Product(name: 'برجر دجاج كرسبي', price: 18, category: 'برجر', img: 'https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=400'),
    Product(name: 'بيتزا ببروني', price: 32, category: 'بيتزا', img: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400'),
    Product(name: 'بيتزا خضار', price: 28, category: 'بيتزا', img: 'https://images.unsplash.com/photo-1571407970349-bc81e7e96d47?w=400'),
    Product(name: 'شاورما لحم', price: 14, category: 'شاورما', img: 'https://images.unsplash.com/photo-1633321702518-7feccafb94d5?w=400'),
    Product(name: 'شاورما دجاج', price: 12, category: 'شاورما', img: 'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=400'),
    Product(name: 'مندي لحم', price: 45, category: 'مندي', img: 'https://images.unsplash.com/photo-1631515242808-497c3fbd4c8a?w=400'),
    Product(name: 'مندي دجاج نص', price: 22, category: 'مندي', img: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'),
    Product(name: 'كبسة دجاج', price: 25, category: 'كبسة', img: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400'),
    Product(name: 'بطاطس بالجبن', price: 13, category: 'مقبلات', img: 'https://images.unsplash.com/photo-1585103608640-566f27d0d7b3?w=400'),
    Product(name: 'عصير مانجو', price: 9, category: 'عصيرات', img: 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=400'),
    Product(name: 'كولا', price: 4, category: 'عصيرات', img: 'https://images.unsplash.com/photo-1581636625402-29b2a704ef13?w=400'),
  ];
  // =================================================

  List<String> get categories => ['الكل',...{...allProducts.map((e) => e.category)}];

  List<Product> get filteredProducts {
    return allProducts.where((p) {
      final matchCat = selectedCat == 'الكل' || p.category == selectedCat;
      final matchSearch = p.name.contains(search);
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(restaurantName),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen())),
                ),
                if (cart.totalItems > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: CircleAvatar(radius: 10, backgroundColor: Colors.yellow,
                      child: Text('${cart.totalItems}', style: TextStyle(fontSize: 12, color: Colors.black))),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // البحث
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن وجبتك...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
            ),
            // الأقسام
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.map((cat) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selectedCat == cat,
                    onSelected: (_) => setState(() => selectedCat = cat),
                  ),
                )).toList(),
              ),
            ),
            // المنتجات
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: filteredProducts.length,
                itemBuilder: (c, i) {
                  final p = filteredProducts[i];
                  return Card(
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(p.img, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Icon(Icons.fastfood, size: 50)),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                              Text('${p.price} ريال', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                              Sized