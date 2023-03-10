// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:enough_convert/enough_convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue_example/widgets.dart';

void main() {
  runApp(FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return FindDevicesScreen();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((d) => ListTile(
                            title: Text(d.name),
                            subtitle: Text(d.id.toString()),
                            trailing: StreamBuilder<BluetoothDeviceState>(
                              stream: d.state,
                              initialData: BluetoothDeviceState.disconnected,
                              builder: (c, snapshot) {
                                if (snapshot.data ==
                                    BluetoothDeviceState.connected) {
                                  return ElevatedButton(
                                    child: Text('OPEN'),
                                    onPressed: () {},
                                    // onPressed: () => Navigator.of(context).push(
                                    //     // MaterialPageRoute(
                                    //     //     builder: (context) =>
                                    //     //         DeviceScreen(device: d)),
                                    //     ),
                                  );
                                }
                                return Text(snapshot.data.toString());
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map(
                        (r) => ScanResultTile(
                          result: r,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            r.device.connect();
                            return DeviceScreen(
                              scanResult: r,
                            );
                          })),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({
    Key? key,
    required this.scanResult,
    // required this.device,
  }) : super(key: key);

  // final BluetoothDevice device;
  final ScanResult scanResult;

  List<int> _getRandomBytes() {
    final math = Random();
    String text =
        "SIZE 75 mm,129 mm\n GAP 2 mm,0 mm\n DIRECTION 1\n CLS\n TEXT 480,100,\"TSS16.BF2\",0,1,1,1,\"自取\"\n BOX 12,304,572,1032,2\n BAR 12,384,560,2\n BAR 12,464,560,2\n BAR 364,464,2,208\n CIRCLE 20,488,60,4\n BAR 12,672,560,2\n BAR 12,840,560,2\n TEXT 384,24,\"TSS24.BF2\",0,2,2,3,\"顺丰特快\"\n TEXT 52,100,\"TSS16.BF2\",0,1,1,1,\"已验视 2023-02-13 16:14:08\"\n BARCODE 52,124,\"128\",108,0,0,3,3,2,\"SF1342689927326\"\n TEXT 164,248,\"0\",0,1,1,\"SF1 342 689 927 326\"\n TEXT 16,312,\"0\",0,3,3,\"010SY-010\"\n TEXT 48,388,\"0\",0,3,3,\"WU\"\n BLOCK 24,680,500,80,\"TSS24.BF2\",0,1,1,\"寄 沙*宁 1******9023\"\n BLOCK 24,720,520,100,\"TSS24.BF2\",0,1,1,\"北京市北京市丰台区库存***提库\"\n TEXT 28,496,\"TSS24.BF2\",0,2,2,\"收\"\n TEXT 100,504,\"TSS16.BF2\",0,2,2,\"汉光百货\"\n TEXT 224,504,\"TSS16.BF2\",0,2,2,\"0******8999\"\n BLOCK 24,568,328,50,\"TSS24.BF2\",0,1,1,\"北京北京西城区西单北大街176号\"\n QRCODE 371,471,Q,4,A,0,M2,S7,\"MMM={'k1':'010SY','k2':'010','k3':'','k4':'T4','k5':'SF1342689927326','k6':'','k7':'989738e8'}\"\n TEXT -4,400,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n TEXT 574,400,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n TEXT -4,670,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n TEXT 574,670,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n TEXT -4,960,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n TEXT 574,960,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n PRINT 1,1\n ";
    final uint8List = Uint8List.fromList(utf8.encode(text + "\r\n"));

    print("uint8List=${uint8List.toString()}");
    // return [

    //   math.nextInt(255),
    //   math.nextInt(255),
    //   math.nextInt(255),
    //   math.nextInt(255)
    // ];

    return uint8List.toList();
  }

  Future doPrint() async {
    print("doPrint...");
    const String crlf = '\r\n';
    Uint8List defNewlineBinary = Uint8List.fromList(utf8.encode(crlf));
    const gbkCodec = GbkCodec(allowInvalid: false);
    String text =
        "SIZE 75 mm,129 mm\n GAP 2 mm,0 mm\n DIRECTION 1\n CLS\n TEXT 480,100,\"TSS16.BF2\",0,1,1,1,\"自取\"\n BOX 12,304,572,1032,2\n BAR 12,384,560,2\n BAR 12,464,560,2\n BAR 364,464,2,208\n CIRCLE 20,488,60,4\n BAR 12,672,560,2\n BAR 12,840,560,2\n TEXT 384,24,\"TSS24.BF2\",0,2,2,3,\"顺丰特快\"\n TEXT 52,100,\"TSS16.BF2\",0,1,1,1,\"已验视 2023-02-13 16:14:08\"\n BARCODE 52,124,\"128\",108,0,0,3,3,2,\"SF1342689927326\"\n TEXT 164,248,\"0\",0,1,1,\"SF1 342 689 927 326\"\n TEXT 16,312,\"0\",0,3,3,\"010SY-010\"\n TEXT 48,388,\"0\",0,3,3,\"WU\"\n BLOCK 24,680,500,80,\"TSS24.BF2\",0,1,1,\"寄 沙*宁 1******9023\"\n BLOCK 24,720,520,100,\"TSS24.BF2\",0,1,1,\"北京市北京市丰台区库存***提库\"\n TEXT 28,496,\"TSS24.BF2\",0,2,2,\"收\"\n TEXT 100,504,\"TSS16.BF2\",0,2,2,\"汉光百货\"\n TEXT 224,504,\"TSS16.BF2\",0,2,2,\"0******8999\"\n BLOCK 24,568,328,50,\"TSS24.BF2\",0,1,1,\"北京北京西城区西单北大街176号\"\n QRCODE 371,471,Q,4,A,0,M2,S7,\"MMM={'k1':'010SY','k2':'010','k3':'','k4':'T4','k5':'SF1342689927326','k6':'','k7':'989738e8'}\"\n TEXT -4,400,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n TEXT 574,400,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n TEXT -4,670,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n TEXT 574,670,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n TEXT -4,960,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n TEXT 574,960,\"A.FNT\",270,2,2,E8,\"SF1342689927326\"\n PRINT 1,1\n ";

    final uint8List = Uint8List.fromList(gbkCodec.encode(text));
    // BluetoothCharacteristic bluetoothCharacteristic;
    // List<BluetoothService> blueServices =
    //     await scanResult.device.services.first;
    // BluetoothService bleService = blueServices.first;
    // print("bleService-uuid=${bleService.uuid.toString()}");
    // List<BluetoothCharacteristic> characteristics = bleService.characteristics;
    // BluetoothCharacteristic characteristic = characteristics.first;
    // print("characteristic-uuid=${characteristic.uuid.toString()}");
    // await characteristic.write(uint8List);

    // ///
    // print("${characteristics.length}");
    // characteristics.forEach((characteristic) {
    //   print("characteristic-1-uuid=${characteristic.uuid}");
    // });

    List<BluetoothService> blueServices =
        await scanResult.device.discoverServices();
    BluetoothService bleService = blueServices.first;
    print("bleService-uuid=${bleService.uuid.toString()}");
    List<BluetoothCharacteristic> characteristics = bleService.characteristics;
    BluetoothCharacteristic characteristic = characteristics.first;
    print("characteristic-uuid=${characteristic.uuid.toString()}");
    await characteristic.write(uint8List);
    // return scanResult.device.services.listen((service) async {
    //   print("listen");

    //   service.forEach((s) {
    //     print("uuid=${s.uuid.toString()}");
    //     scanResult.advertisementData.serviceUuids.forEach((serviceUuid) {
    //       if (s.uuid.toString() == serviceUuid) {
    //         print("serviceUuid=$serviceUuid");

    //         s.characteristics.forEach((c) {
    //           print("s.uuid.toString()=${s.uuid.toString()}");
    //           print("c.uuid.toString()=${c.uuid.toString()}");
    //           bluetoothCharacteristic = c;
    //           if (s.uuid.toString() == c.uuid.toString()) {
    //             print(
    //                 "s.uuid.toString() == c.uuid.toString()=${c.uuid.toString()}");
    //             print(
    //                 "s.uuid.toString() == c.uuid.toString()=${c.uuid.toMac()}");
    //           }
    //         });
    //       }
    //     });
    //   });
    // });
    // scanResult.
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () => c.read(),
                    onWritePressed: () async {
                      await doPrint();
                      await c.write(_getRandomBytes(), withoutResponse: true);
                      // await c.read();
                    },
                    onNotificationPressed: () async {
                      await c.setNotifyValue(!c.isNotifying);
                      await c.read();
                    },
                    descriptorTiles: c.descriptors
                        .map(
                          (d) => DescriptorTile(
                            descriptor: d,
                            onReadPressed: () => d.read(),
                            onWritePressed: () => d.write(_getRandomBytes()),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(scanResult.device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: scanResult.device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => scanResult.device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => scanResult.device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return ElevatedButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        ?.copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: scanResult.device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothDeviceState.connected)
                    ? Icon(Icons.bluetooth_connected)
                    : Icon(Icons.bluetooth_disabled),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${scanResult.device.id}'),
                trailing: StreamBuilder<bool>(
                  stream: scanResult.device.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data! ? 1 : 0,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () => scanResult.device.discoverServices(),
                      ),
                      IconButton(
                        icon: SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                          width: 18.0,
                          height: 18.0,
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<int>(
              stream: scanResult.device.mtu,
              initialData: 0,
              builder: (c, snapshot) => ListTile(
                title: Text('MTU Size'),
                subtitle: Text('${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => scanResult.device.requestMtu(223),
                ),
              ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: scanResult.device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
