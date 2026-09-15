import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const MrNiaziApp()));

class AppState extends ChangeNotifier {
  final List<MenuItemModel> menu = [
    MenuItemModel('Zinger Burger', 'Burgers', 300),
    MenuItemModel('Zinger Burger With Cheese', 'Burgers', 350),
    MenuItemModel('Chicken Burger', 'Burgers', 300),
    MenuItemModel('Chicken Burger With Cheese', 'Burgers', 350),
    MenuItemModel('Chicken Grill Burger', 'Burgers', 350),
    MenuItemModel('Smash Chicken Burger', 'Burgers', 400),
    MenuItemModel('Zinger Broast Chest', 'Burgers', 450),
    MenuItemModel('Zinger Broast Leg', 'Burgers', 400),
    MenuItemModel('Club Sandwich', 'Sandwiches', 300),
    MenuItemModel('Chicken Sandwich', 'Sandwiches', 350),
    MenuItemModel('Chicken Continental Sandwich', 'Sandwiches', 400),
    MenuItemModel('Crispy Chicken Sandwich', 'Sandwiches', 350),
    MenuItemModel('Chicken Boti Roll', "Roll's Special", 200),
    MenuItemModel('Chicken Mayo Garlic Roll', "Roll's Special", 250),
    MenuItemModel('Chicken Malai Boti Roll', "Roll's Special", 270),
    MenuItemModel('Zinger Jumbo Roll', "Roll's Special", 300),
    MenuItemModel('Reshmi Kabab Roll', "Roll's Special", 250),
    MenuItemModel('Chicken Chilli Spicy Roll', "Roll's Special", 300),
    MenuItemModel('Chicken Tikka Chest', 'B.BQ Feast', 300),
    MenuItemModel('Chicken Tikka Leg', 'B.BQ Feast', 250),
    MenuItemModel('Chicken Boti Plate', 'B.BQ Feast', 500),
    MenuItemModel('Chicken Bihari Boti Plate', 'B.BQ Feast', 600),
    MenuItemModel('Chicken Reshmi Kabab Plate', 'B.BQ Feast', 450),
    MenuItemModel('Chicken Gola Kabab Plate', 'B.BQ Feast', 500),
    MenuItemModel('Chicken Malai Boti Plate', 'B.BQ Feast', 500),
    MenuItemModel('Chicken Balochi Boti Plate', 'B.BQ Feast', 600),
    MenuItemModel('Chicken Green Tikka Special', 'B.BQ Feast', 400),
    MenuItemModel('Small Water', 'Cold Drink', 60),
    MenuItemModel('Large Water', 'Cold Drink', 120),
    MenuItemModel('Coldrink Regular', 'Cold Drink', 70),
    MenuItemModel('Chapati', 'Extras', 20),
    MenuItemModel('Naan', 'Extras', 25),
    MenuItemModel('Pori Paratha', 'Extras', 60),
    MenuItemModel('Add Cheese', 'Extras', 60),
    MenuItemModel("Mayo Garlic Add On’s", 'Extras', 50),
  ];
  final Map<String,int> cart = {};
  final List<OrderModel> orders = [];
  String? selectedBranch;
  Position? position;

  List<MenuItemModel> getItems(String cat) => menu.where((e) => e.category == cat).toList();
  int get count => cart.values.fold(0,(a,b)=>a+b);
  int get subtotal => cart.entries.fold(0,(s,e) => s + menu.firstWhere((m)=>m.name==e.key).price*e.value);
  void add(MenuItemModel m){ cart[m.name]=(cart[m.name]??0)+1; notifyListeners(); }
  void remove(MenuItemModel m){ if(!cart.containsKey(m.name))return; if(cart[m.name]==1) cart.remove(m.name); else cart[m.name]=cart[m.name]!-1; notifyListeners(); }
  void setBranch(String b){selectedBranch=b; notifyListeners();}
  Future<void> locate() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var p = await Geolocator.checkPermission();
    if(p==LocationPermission.denied) p=await Geolocator.requestPermission();
    if(p==LocationPermission.denied || p==LocationPermission.deniedForever) return;
    position=await Geolocator.getCurrentPosition();
    selectedBranch=nearestBranch(position!.latitude,position!.longitude).name;
    notifyListeners();
  }
  Future<void> placeOrder(String name,String phone,String address,String payment) async {
    final branch = selectedBranch ?? branches.first.name;
    orders.insert(0, OrderModel(
      id:'MN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      name:name, phone:phone, address:address, branch:branch,
      items:Map.of(cart), total:subtotal, payment:payment, status:'New',
      time:DateTime.now(),
    ));
    cart.clear(); notifyListeners();
  }
}

class MenuItemModel { final String name, category; final int price; MenuItemModel(this.name,this.category,this.price); }
class OrderModel {
  final String id,name,phone,address,branch,payment,status; final Map<String,int> items; final int total; final DateTime time;
  OrderModel({required this.id,required this.name,required this.phone,required this.address,required this.branch,required this.items,required this.total,required this.payment,required this.status,required this.time});
}
class Branch { final String name, address; final double lat,lng; Branch(this.name,this.address,this.lat,this.lng); }
final branches = [
  Branch('Ajmer Nagri','Ajmer Nagri Rd, Sector 7-A North Karachi',24.9827,67.0660),
  Branch('New Karachi','New Karachi, Karachi',24.9930,67.0620),
  Branch('Baldia Town','Baldia Town, Karachi',24.9180,66.9990),
  Branch('Rashidabad','Rashidabad, Karachi',24.9490,67.0800),
  Branch('North Nazimabad','North Nazimabad, Karachi',24.9480,67.0430),
  Branch('Buffer Zone','Buffer Zone, Karachi',24.9800,67.0630),
  Branch('Surjani Town','Surjani Town, Karachi',25.0150,67.0640),
  Branch('Orangi Town','Orangi Town, Karachi',24.9500,66.9880),
  Branch('Federal B Area','FB Area, Karachi',24.9280,67.0670),
  Branch('Gulshan-e-Maymar','Gulshan-e-Maymar, Karachi',25.0400,67.1200),
];
Branch nearestBranch(double lat,double lng) => branches.reduce((a,b)=>_d(lat,lng,a)<_d(lat,lng,b)?a:b);
double _d(double lat,double lng,Branch b){const r=0.017453292519943295; final dlat=(b.lat-lat)*r,dlng=(b.lng-lng)*r; final x=sin(dlat/2)*sin(dlat/2)+cos(lat*r)*cos(b.lat*r)*sin(dlng/2)*sin(dlng/2); return 6371*2*atan2(sqrt(x),sqrt(1-x));}

class MrNiaziApp extends StatelessWidget {
  const MrNiaziApp({super.key});
  @override Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false, title:'Mr. Niazi',
    theme:ThemeData(useMaterial3:true, colorSchemeSeed:const Color(0xFFFF7A00), scaffoldBackgroundColor:const Color(0xFFF7F7F7), fontFamily:'Arial'),
    home:const HomePage(),
  );
}

class HomePage extends StatefulWidget{const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState();}
class _HomePageState extends State<HomePage>{
 int idx=0;
 @override Widget build(BuildContext c){ final pages=[const HomeTab(),const MenuTab(),const OrdersTab(),const MoreTab()]; return Scaffold(
  body:pages[idx], bottomNavigationBar:NavigationBar(selectedIndex:idx,onDestinationSelected:(i)=>setState(()=>idx=i), destinations:const[
   NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
   NavigationDestination(icon:Icon(Icons.restaurant_menu_outlined),label:'Menu'),
   NavigationDestination(icon:Icon(Icons.receipt_long_outlined),label:'Orders'),
   NavigationDestination(icon:Icon(Icons.more_horiz),label:'More'),
  ]),
 );}
}

class Header extends StatelessWidget { final String title; const Header({super.key,required this.title});
 @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.fromLTRB(20,50,20,14),child:Row(children:[
  ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.asset('assets/logo.jpg',width:52,height:52,fit:BoxFit.cover)),
  const SizedBox(width:12), Expanded(child:Text(title,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900))),
  Consumer<AppState>(builder:(_,s,__)=>Badge(label:Text('${s.count}'),isLabelVisible:s.count>0,child:IconButton(icon:const Icon(Icons.shopping_bag_outlined),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const CartPage())))))
 ]));}

class HomeTab extends StatelessWidget{const HomeTab({super.key});
 @override Widget build(BuildContext c){final s=c.watch<AppState>(); return SafeArea(child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  const Header(title:'Mr. Niazi'),
  Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:Text('Taste That Hits Different',style:TextStyle(fontSize:16,color:Colors.grey[700]))),
  const SizedBox(height:16),
  Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:ClipRRect(borderRadius:BorderRadius.circular(24),child:Stack(children:[
   Image.asset('assets/menu.jpg',height:245,width:double.infinity,fit:BoxFit.cover),
   Positioned(left:16,bottom:16,child:ElevatedButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const MenuTab())),icon:const Icon(Icons.restaurant),label:const Text('Order Now')))
  ]))),
  const SizedBox(height:22),
  const Padding(padding:EdgeInsets.symmetric(horizontal:20),child:Text('Choose your branch',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold))),
  const SizedBox(height:10),
  Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:Card(child:ListTile(
    leading:const CircleAvatar(child:Icon(Icons.storefront)),title:Text(s.selectedBranch??'Select nearest branch'),subtitle:const Text('We route your order to the closest branch'),
    trailing:IconButton(icon:const Icon(Icons.my_location),onPressed:() async {await s.locate(); if(c.mounted && s.selectedBranch!=null) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('Nearest branch: ${s.selectedBranch}')));}),
    onTap:()=>showModalBottomSheet(context:c,builder:(_)=>BranchPicker()),
  ))),
  const SizedBox(height:18),
  const Padding(padding:EdgeInsets.symmetric(horizontal:20),child:Text('Popular categories',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold))),
  const SizedBox(height:10),
  SizedBox(height:105,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:20),children:['Burgers','Sandwiches',"Roll's Special",'B.BQ Feast'].map((x)=>Padding(padding:const EdgeInsets.only(right:10),child:ActionChip(avatar:const Icon(Icons.fastfood),label:Text(x),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>MenuTab(initial:x)))))).toList())),
  const SizedBox(height:20),
 ]));}
}

class BranchPicker extends StatelessWidget{const BranchPicker({super.key});
 @override Widget build(BuildContext c)=>SafeArea(child:ListView(shrinkWrap:true,padding:const EdgeInsets.all(12),children:[
  const ListTile(title:Text('Select branch',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),subtitle:Text('You can also use your location for automatic routing')),
  ...branches.map((b)=>ListTile(leading:const Icon(Icons.location_on_outlined),title:Text(b.name),subtitle:Text(b.address),onTap:(){c.read<AppState>().setBranch(b.name);Navigator.pop(c);}))
 ]));}
}

class MenuTab extends StatelessWidget{final String? initial; const MenuTab({super.key,this.initial});
 @override Widget build(BuildContext c){final s=c.watch<AppState>(); final cats=['Burgers','Sandwiches',"Roll's Special",'B.BQ Feast','Cold Drink','Extras']; return DefaultTabController(length:cats.length,initialIndex:initial==null?0:cats.indexOf(initial!),child:Scaffold(
  appBar:AppBar(title:const Text('Menu',style:TextStyle(fontWeight:FontWeight.bold)),actions:[IconButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const CartPage())),icon:Badge(label:Text('${s.count}'),isLabelVisible:s.count>0,child:const Icon(Icons.shopping_bag_outlined)))]),
  body:Column(children:[TabBar(isScrollable:true,tabs:cats.map((x)=>Tab(text:x)).toList()),Expanded(child:TabBarView(children:cats.map((cat)=>ListView(padding:const EdgeInsets.all(12),children:s.getItems(cat).map((m)=>MenuCard(m)).toList()).toList())))]
 ));}
}
class MenuCard extends StatelessWidget{final MenuItemModel m; const MenuCard(this.m,{super.key});
 @override Widget build(BuildContext c){final n=c.watch<AppState>().cart[m.name]??0; return Card(child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:6),
  leading:CircleAvatar(backgroundColor:const Color(0xFFFFE4CF),child:Icon(Icons.fastfood,color:Colors.orange[800])),
  title:Text(m.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('Rs. ${m.price}/-'),
  trailing:n==0?FilledButton(onPressed:()=>c.read<AppState>().add(m),child:const Text('ADD')):Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>c.read<AppState>().remove(m),icon:const Icon(Icons.remove_circle_outline)),Text('$n',style:const TextStyle(fontWeight:FontWeight.bold)),IconButton(onPressed:()=>c.read<AppState>().add(m),icon:const Icon(Icons.add_circle_outline))])
 ));}
}

class CartPage extends StatelessWidget{const CartPage({super.key});
 @override Widget build(BuildContext c){final s=c.watch<AppState>(); return Scaffold(appBar:AppBar(title:const Text('Your Cart')),body:s.cart.isEmpty?const Center(child:Text('Your cart is empty')):Column(children:[
 Expanded(child:ListView(padding:const EdgeInsets.all(12),children:s.cart.entries.map((e){final m=s.menu.firstWhere((x)=>x.name==e.key);return ListTile(title:Text(e.key),subtitle:Text('${e.value} × Rs. ${m.price}'),trailing:Text('Rs. ${m.price*e.value}'));}).toList())),
 Container(padding:const EdgeInsets.all(18),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(24))),child:Column(children:[
  Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Subtotal',style:TextStyle(fontSize:18)),Text('Rs. ${s.subtotal}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))]),
  const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const CheckoutPage())),child:const Text('Proceed to Checkout')))
 ]))
 ]);}
}

class CheckoutPage extends StatefulWidget{const CheckoutPage({super.key}); @override State<CheckoutPage> createState()=>_CheckoutPageState();}
class _CheckoutPageState extends State<CheckoutPage>{
 final name=TextEditingController(),phone=TextEditingController(),address=TextEditingController(); String payment='Cash on Delivery';
 @override Widget build(BuildContext c){final s=c.watch<AppState>();return Scaffold(appBar:AppBar(title:const Text('Checkout')),body:ListView(padding:const EdgeInsets.all(18),children:[
 const Text('Delivery details',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:14),
 TextField(controller:name,decoration:const InputDecoration(labelText:'Full name',prefixIcon:Icon(Icons.person_outline),border:OutlineInputBorder())),
 const SizedBox(height:12),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Mobile number',prefixIcon:Icon(Icons.phone_outlined),border:OutlineInputBorder())),
 const SizedBox(height:12),TextField(controller:address,maxLines:3,decoration:const InputDecoration(labelText:'Complete delivery address',prefixIcon:Icon(Icons.location_on_outlined),border:OutlineInputBorder())),
 const SizedBox(height:18),const Text('Order from branch',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
 Card(child:ListTile(leading:const Icon(Icons.storefront),title:Text(s.selectedBranch??'Select branch'),subtitle:const Text('Tap to change'),onTap:()=>showModalBottomSheet(context:c,builder:(_)=>const BranchPicker()))),
 const SizedBox(height:18),const Text('Payment',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
 RadioListTile(value:'Cash on Delivery',groupValue:payment,onChanged:(v)=>setState(()=>payment=v!),title:const Text('Cash on Delivery')),
 RadioListTile(value:'Easypaisa / JazzCash',groupValue:payment,onChanged:(v)=>setState(()=>payment=v!),title:const Text('Easypaisa / JazzCash')),
 const SizedBox(height:14),FilledButton.icon(onPressed:()=>submit(c),icon:const Icon(Icons.check_circle_outline),label:Text('Place order • Rs. ${s.subtotal}'))
 ]);}
 void submit(BuildContext c) async {final s=c.read<AppState>(); if(name.text.trim().isEmpty||phone.text.trim().isEmpty||address.text.trim().isEmpty){ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('Please complete your delivery details')));return;} await s.placeOrder(name.text,phone.text,address.text,payment); if(c.mounted)Navigator.pushAndRemoveUntil(c,MaterialPageRoute(builder:(_)=>const OrderSuccessPage()),(r)=>r.isFirst);}
}
class OrderSuccessPage extends StatelessWidget{const OrderSuccessPage({super.key});
 @override Widget build(BuildContext c){final o=c.read<AppState>().orders.first;return Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(30),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
 const Icon(Icons.check_circle,size:90,color:Colors.green),const SizedBox(height:18),const Text('Order received!',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text('Order #${o.id}',style:const TextStyle(fontSize:18)),Text('Branch: ${o.branch}'),const SizedBox(height:20),FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('Back to home'))
 ])));}
}
class OrdersTab extends StatelessWidget{const OrdersTab({super.key});
 @override Widget build(BuildContext c){final s=c.watch<AppState>();return Scaffold(appBar:AppBar(title:const Text('My Orders',style:TextStyle(fontWeight:FontWeight.bold))),body:s.orders.isEmpty?const Center(child:Text('No orders yet')):ListView(padding:const EdgeInsets.all(12),children:s.orders.map((o)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.receipt_long)),title:Text('#${o.id} • ${o.status}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${o.branch}\\n${DateFormat('dd MMM, hh:mm a').format(o.time)}'),isThreeLine:true,trailing:Text('Rs. ${o.total}'))).toList()) );}
}
class MoreTab extends StatelessWidget{const MoreTab({super.key});
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('More')),body:ListView(padding:const EdgeInsets.all(12),children:[
  Card(child:ListTile(leading:const Icon(Icons.admin_panel_settings),title:const Text('Restaurant Admin'),subtitle:const Text('Demo dashboard for incoming orders'),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const AdminPage())))),
  Card(child:ListTile(leading:const Icon(Icons.phone),title:const Text('Call for help'),subtitle:const Text('0323-8285796'),onTap:()=>launchUrl(Uri.parse('tel:03238285796')))),
  const Card(child:ListTile(leading:Icon(Icons.info_outline),title:Text('Mr. Niazi Fast Food & B.BQ'),subtitle:Text('Ajmer Nagri Rd, Sector 7-A North Karachi\\nSadaf Medical ke Samne'))),
 ]));}
}
class AdminPage extends StatelessWidget{const AdminPage({super.key});
 @override Widget build(BuildContext c){final s=c.watch<AppState>();return Scaffold(appBar:AppBar(title:const Text('Admin • Incoming Orders')),body:s.orders.isEmpty?const Center(child:Text('No incoming orders yet')):ListView(padding:const EdgeInsets.all(12),children:s.orders.map((o)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('#${o.id}',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18)),Text('Rs. ${o.total}',style:const TextStyle(fontWeight:FontWeight.bold))]),
 Text('${o.name} • ${o.phone}'),Text(o.address),Text('Branch: ${o.branch}'),const Divider(),
 ...o.items.entries.map((e)=>Text('${e.value} × ${e.key}')),
 const SizedBox(height:10),Text('Payment: ${o.payment}'),const SizedBox(height:10),
 Wrap(spacing:8,children:['New','Preparing','Out for delivery','Delivered'].map((x)=>ChoiceChip(label:Text(x),selected:x==o.status,onSelected:(_){ }).toList())
 ]))).toList()) );}
}
