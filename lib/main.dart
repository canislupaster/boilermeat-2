import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synchronized/synchronized.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

enum WifiState {
  scanning,
  idle,
  doneScanning
}

class ScanResult {
  final String mac;
  final int rssi;
  final bool rtt;

  ScanResult(this.mac, this.rssi, this.rtt);
}

class _MainPageState extends State<MainPage> {
  static const platform = MethodChannel("scanWifi");

  WifiState state=WifiState.idle;
  List<ScanResult> results=[];
  Lock lock=Lock();
  
  Future<void> _updateList() async {
    await lock.synchronized(() async {
      setState(() => state=WifiState.scanning);
      var res = await platform.invokeListMethod<Map<dynamic, dynamic>>("");
      if (res==null) throw "error getting scan results";
      results.clear();
      for (var ap in res) {
        results.add(ScanResult(ap["mac"], ap["level"], ap["rtt"]));
      }

      setState(() => state=WifiState.doneScanning);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    switch (state) {
      case WifiState.idle:
        children.add(const Text("press button to scan"));
        break;
      case WifiState.scanning:
        children.add(const Text("scanning..."));
        break;
      case WifiState.doneScanning:
        List<Widget> listViewChild = [];
        results.sort((a, b) => b.rssi.compareTo(a.rssi));
        for (var res in results) {
          listViewChild.add(
            //simple layout to display data in scanresult in a neat box
            Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                border: Border.all(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text("mac: ${res.mac}"),
                  Text("rssi: ${res.rssi}"),
                  Text("rtt: ${res.rtt}"),
                ],
              ),
            )
          );
        }

        children.add(Expanded(child: ListView(children: listViewChild)));
    }
    
    if (state!=WifiState.scanning) {
      children.add(TextButton(
        onPressed: () {
          _updateList();
        },
        child: const Text('start scan')
      ));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children
      )
    );
  }
}
