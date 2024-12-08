import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void checkBluetoothPerms() async {
  if (await FlutterBluePlus.isSupported == false) {
    print("Bluetooth is not supported on this device");
  } else if (await FlutterBluePlus.adapterState.first ==
      BluetoothAdapterState.on) {
    print("Bluetooth is enabled");
  } else {
    print("Bluetooth is not enabled");
  }
}

Future<List<ScanResult>> startScan() async {
  print("Starting Bluetooth scan...");

  // Variabilă pentru rezultate
  List<ScanResult> results = [];

  // Ascultă fluxul și adaugă rezultatele în listă
  final subscription = FlutterBluePlus.scanResults.listen((scanResults) {
    results = scanResults;
    print("Found ${results.length} devices so far");
  });

  // Pornește scanarea pentru un timp definit
  await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

  // Așteaptă să se termine scanarea
  await Future.delayed(const Duration(seconds: 4));

  // Anulează ascultarea fluxului
  await subscription.cancel();

  // Oprește scanarea
  await FlutterBluePlus.stopScan();
  print("Scan finished");

  return results;
}

void sendMessage(BluetoothDevice device, String message) async {
  List<BluetoothService> services = await device.discoverServices();
  BluetoothCharacteristic? writeableChar;
  for (BluetoothService service in services) {
    for (BluetoothCharacteristic characteristic in service.characteristics) {
      if (characteristic.properties.write) {
        writeableChar = characteristic;
        break;
      }
    }
  }
  if (writeableChar != null) {
    await writeableChar.write(message.codeUnits);
  }
}
