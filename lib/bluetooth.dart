// import 'dart:io';

// import 'package:flutter/cupertino.dart';

// import 'main.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import 'package:rc/pages/device.dart';

BluetoothDevice device = BluetoothDevice as BluetoothDevice;
BluetoothService service = BluetoothService as BluetoothService;
BluetoothCharacteristic control =
    BluetoothCharacteristic as BluetoothCharacteristic;
BluetoothCharacteristic fire =
    BluetoothCharacteristic as BluetoothCharacteristic;

String currMAC = "";

class BtController extends GetxController {
  Future scanDevices() async {
    if (!FlutterBluePlus.isScanningNow) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } else {
      print("Scan already running, ignoring request");
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> connect(BluetoothDevice dev) async {
    await dev.connect();
    dev.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        print("Device disconnected");
      } else if (state == BluetoothConnectionState.connected) {
        print("Device connected");
        device = dev;
        currMAC = device.remoteId.toString();
      }
    });

    // Stream<BluetoothBondState> bondState = dev.bondState;
    // bondState.listen((value) {
    //   if (value == BluetoothBondState.bonded) {
    //     print("Device already bonded");
    //   } else {
    //     dev.createBond();
    //   }
    Get.to(() => const Device());
  }

  Future<void> disconnect() async {
    device.disconnect();
  }

  Future<void> discoverServices() async {
    int found = 0;
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((serviceF) {
      String scan = serviceF.uuid.toString();
      print("Service: " + scan);
      if (scan == "6e400001-b5a3-f393-e0a9-e50e24dcca9e") {
        found = 1;
        service = serviceF;
        var characteristics = serviceF.characteristics;
        int i = 0;
        for (BluetoothCharacteristic c in characteristics) {
          String target = c.characteristicUuid.toString();
          if (target == "6e400002-b5a3-f393-e0a9-e50e24dcca9e") {
            if (i == 0) {
              control = c;
              i = 1;
            } else if (i == 1) {
              fire = c;
              i = 2;
            }
          }
        }
      }

      print("\n");
    });
    if (found == 1) {
      print("Mi band compatible");
    } else {
      print("Mi band not compatible");
    }
  }

  Future<void> controlP(String text) async {
    List<int> bytes = text.codeUnits;
    control.write(bytes);
  }
}


// int initS = 0;

// Future<void> init() async {
//   if (await FlutterBluePlus.isAvailable == false) {
//     print("Bluetooth not supported by this device");
//     return;
//   }
//   if (Platform.isAndroid) {
//     await FlutterBluePlus.turnOn();
//   }
//   FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
//   initS += 1;
// }

// Future<void> startScan() async {
//   if (initS == 0) {
//     init();
//   }
//   print("scan start");

//   if (FlutterBluePlus.isScanningNow == false) {
//     FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 10), androidUsesFineLocation: false);
//     FlutterBluePlus.stopScan();
//   }

//   FlutterBluePlus.scanResults.listen((List<ScanResult> scanResults) {
//     for (ScanResult scanResult in scanResults) {
//       BluetoothDevice device = scanResult.device;
//     }
//   });
// }

// Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
