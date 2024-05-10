import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import '../bluetooth.dart';
import 'device.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
//import 'package:flutter_blue_plus/flutter_blue_plus.dart';

//import 'package:miband/main.dart';

String predefinedMAC = "34:85:18:7B:88:D6";

class Files {
  Future<String> get localPath async {
    final directory = await getApplicationCacheDirectory();

    return directory.path;
  }

  Future<File> get localFile async {
    final path = await localPath;
    return File('$path/mac.txt');
  }

  Future<String> readMAC() async {
    try {
      final file = await localFile;

      final contents = await file.readAsString();
      predefinedMAC = contents;
      return contents;
    } catch (e) {
      predefinedMAC = "34:85:18:7B:88:D6";
      return "34:85:18:7B:88:D6";
    }
  }

  Future<File> writeMAC(String mac) async {
    final file = await localFile;

    return file.writeAsString(mac);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    Files().readMAC();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<BtController>(
        init: BtController(),
        builder: (controller) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  color: const Color.fromRGBO(0, 100, 0, 1),
                  child: const Center(
                    child: Text(
                      "Connect to RC",
                      style: TextStyle(color: Colors.white, fontSize: 35),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => BtController().scanDevices(),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromRGBO(0, 100, 0, 1),
                      minimumSize: const Size(350, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    child: const Text(
                      "Scan",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                Center(
                    child: Row(
                  children: [
                    const Spacer(),
                    ElevatedButton(
                        onPressed: () {
                          Get.to(() => const Device());
                        },
                        child: const Text("Dev")),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () {
                          print(predefinedMAC);
                          BtController().connect(BluetoothDevice(
                              remoteId: DeviceIdentifier(predefinedMAC),
                              localName: "Auticko :D",
                              type: BluetoothDeviceType.le));
                        },
                        child: const Text("Connect to predefined MAC")),
                    const Spacer(),
                  ],
                )),
                StreamBuilder<List<ScanResult>>(
                  stream: controller.scanResults,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SingleChildScrollView(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 320,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final data = snapshot.data![index];
                              return Card(
                                  child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(data.device.localName)));
                                  BtController().connect(data.device);
                                },
                                child: ListTile(
                                  title: Text(data.device.localName),
                                  subtitle:
                                      Text(data.device.remoteId.toString()),
                                  trailing: Text(data.rssi.toString()),
                                ),
                              ));
                            },
                          ),
                        ),
                      );
                    } else {
                      return const Center(child: Text("No devices found"));
                    }
                  },
                ),
                const SizedBox(
                  width: 50,
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
