import 'dart:convert';
import 'dart:io';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'd_web_socket/my_web_socket_server.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void dispose() {
    _printer.disconnect();
    super.dispose();
  }

  final List<String> _connectedDevices = [];
  late MyWebSocketServer _myWebSocketServer;

  String _responseMessage = 'Message';
  String _messageToSend = 'Hello From Server';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();


    _initialWebSocket();
  }

  late String _currentIP = 'Unknown';

  void _initialWebSocket() async{
    _currentIP = await _getCurrentIp();
    setState(() {

    });

    _myWebSocketServer = MyWebSocketServer(
        currentIP: _currentIP,
        onConnectedDevice: (data){
          setState(() {
            _connectedDevices.add(data);
          });
        },
        onDisconnected: (ip){
          _connectedDevices.removeWhere((element) => element == ip);
          setState(() {

          });
        },
        onListener: (data){
          final Map<String, dynamic> json = jsonDecode(data as String);
          final int code = (json['code'] as num).toInt();
          final String jsonData = json['data'] as String;
          switch(code){
            case 1:
              print('Connected Success');
              break;
            case 2:
              print('Print to Printer');
              testReceipt(_printer);
              //_printer.disconnect();
              break;
            case 3:
              setState(() {
                _responseMessage = jsonData;
              });
              break;
          }
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('IP : $_currentIP', style: Theme.of(context).textTheme.headline6,),
                      const Divider(),
                      Text('Connected Devices', style: Theme.of(context).textTheme.headline6,),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _connectedDevices.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(_connectedDevices[index]),
                              subtitle: Text(_connectedDevices[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  child: Column(
                    children: [
                      Text('Message', style: Theme.of(context).textTheme.headline6,),
                      const Divider(),
                      SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: Form(
                                key: _formKey,
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    label: Text('Message')
                                  ),
                                  initialValue: _messageToSend,
                                  onSaved: (value){
                                    if(value == null){
                                      return;
                                    }
                                    _messageToSend = value;
                                  },
                                ),
                              ),
                            ),
                            const VerticalDivider(color: Colors.transparent,),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.0),
                              child: SizedBox(
                                height: double.infinity,
                                width: 100,
                                child: ElevatedButton(
                                  onPressed: (){
                                    final FormState? form = _formKey.currentState;
                                    if(form == null){
                                      return;
                                    }
                                    if(form.validate()){
                                      form.save();
                                      _myWebSocketServer.sendData(data: _messageToSend);
                                    }
                                  },
                                  child: const Text('Send'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.transparent,),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(_responseMessage),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Connected Printer', style: Theme.of(context).textTheme.headline6,),
                            SizedBox(
                              height: double.infinity,
                                child: ElevatedButton(onPressed: (){
                                  _showMyDialog();
                                }, child: const Text('Connect'),)),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.transparent,),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(border: Border.all(),),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(_printerStatus),
                          ),
                        ),
                      ),
                      const Divider(color: Colors.transparent,),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(onPressed: (){
                          testReceipt(_printer);
                          _printer.disconnect();
                        }, child: const Text('Print Test'),),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _getCurrentIp() async {
    final List<NetworkInterface> connectedIps = await NetworkInterface.list();
    return connectedIps.first.addresses.first.address;
  }

  String _printerIP = '192.168.0.12';
  int _printerPort = 9100;
  final GlobalKey<FormState> _formKey2 = GlobalKey<FormState>();
  String _printerStatus = 'No Printer Connected';

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Form(
              key: _formKey2,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Printer IP'),
                    ),
                    initialValue: '192.168.0.12',
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Please Input Printer IP';
                      }
                      return null;
                    },
                    onSaved: (value){
                      if(value == null){
                        return;
                      }
                      _printerIP = value;
                    },
                  ),
                  const Divider(color: Colors.transparent,),
                  TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Printer Port'),
                    ),
                    initialValue: '9100',
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Please Input Printer Port';
                      }
                      return null;
                    },
                    onSaved: (value){
                      if(value == null){
                        return;
                      }
                      _printerPort = int.parse(value);
                    },
                  ),
                  const Divider(color: Colors.transparent,),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async{
                        final FormState? form = _formKey2.currentState;
                        if(form == null){
                          return;
                        }
                        if(form.validate()){
                          form.save();
                          await _connectToPrinter();
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Connect'),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  late NetworkPrinter _printer;

  Future<void> _connectToPrinter() async{
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    _printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await _printer.connect(_printerIP, port: _printerPort);

    if (res == PosPrintResult.success) {
      setState(() {
        _printerStatus = 'Printer $_printerIP Connected';
      });
    }

    print('Print result: ${res.msg}');
  }

  void testReceipt(NetworkPrinter printer) {
    printer.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    printer.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
        styles: const PosStyles(codeTable: 'CP1252'));
    printer.text('Special 2: blåbærgrød',
        styles: const PosStyles(codeTable: 'CP1252'));

    printer.text('Bold text', styles: const PosStyles(bold: true));
    printer.text('Reverse text', styles: const PosStyles(reverse: true));
    printer.text('Underlined text',
        styles: const PosStyles(underline: true), linesAfter: 1);
    printer.text('Align left', styles: const PosStyles(align: PosAlign.left));
    printer.text('Align center', styles: const PosStyles(align: PosAlign.center));
    printer.text('Align right',
        styles: const PosStyles(align: PosAlign.right), linesAfter: 1);

    printer.text('Text size 200%',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));

    printer.feed(2);
    printer.cut();
  }
}
