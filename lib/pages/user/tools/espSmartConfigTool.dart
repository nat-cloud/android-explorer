import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity/connectivity.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartconfig/smartconfig.dart';

class EspSmartConfigTool extends StatefulWidget {
  EspSmartConfigTool({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _EspSmartConfigToolState createState() => _EspSmartConfigToolState();
}

class _EspSmartConfigToolState extends State<EspSmartConfigTool> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

//  New
  final TextEditingController _bssidFilter = TextEditingController();
  final TextEditingController _ssidFilter = TextEditingController();
  final TextEditingController _passwordFilter = TextEditingController();

  bool _isLoading = false;

  String _ssid = "";
  String _bssid = "";
  String _password = "";
  String _msg = "";

  _EspSmartConfigToolState() {
    _ssidFilter.addListener(_ssidListen);
    _passwordFilter.addListener(_passwordListen);
    _bssidFilter.addListener(_bssidListen);
  }

  void _ssidListen() {
    if (_ssidFilter.text.isEmpty) {
      _ssid = "";
    } else {
      _ssid = _ssidFilter.text;
    }
  }

  void _bssidListen() {
    if (_bssidFilter.text.isEmpty) {
      _bssid = "";
    } else {
      _bssid = _bssidFilter.text;
    }
  }

  void _passwordListen() {
    if (_passwordFilter.text.isEmpty) {
      _password = "";
    } else {
      _password = _passwordFilter.text;
    }
  }

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    await requestPermission();
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return;
    }

    _updateConnectionStatus(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP SmartConfig'),
      ),
      body: Center(
          child: _isLoading ? Container(
            child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
              ),
                    Text(_ssid),
                    Text(_bssid),
                    Text(_password),
                  ]),
            ),
            color: Colors.white.withOpacity(0.8),
          ) :

          Container(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[

                  Container(height: 10),

                  Container(
                      child:  Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Text("ESP Touch v0.3.7.0"),
                            TextField(
                              controller: _ssidFilter,
                              decoration: InputDecoration(
                                  labelText: 'ssid'
                              ),
                            ),
                            TextField(
                              controller: _bssidFilter,
                              decoration: InputDecoration(
                                  labelText: 'bssid'
                              ),
                            ),
                          ])),

                  Container(
                    child: TextField(
                      controller: _passwordFilter,
                      decoration: InputDecoration(
                          labelText: 'Password'
                      ),
                    ),
                  ),

                  RaisedButton(
                    child: Text('Configure ESP'),
                    onPressed: _configureEsp,
                  ),

                  Container(height: 10),

                  Text(_msg),

                ],
              )

          )


      )
    );
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        String wifiName, wifiBSSID, wifiIP;

        try {
          wifiName = await _connectivity.getWifiName();
        } on PlatformException catch (e) {
          print(e.toString());
          wifiName = "Failed to get Wifi Name";
        }

        try {
          wifiBSSID = await _connectivity.getWifiBSSID();
        } on PlatformException catch (e) {
          print(e.toString());
          wifiBSSID = "Failed to get Wifi BSSID";
        }

        try {
          wifiIP = await _connectivity.getWifiIP();
        } on PlatformException catch (e) {
          print(e.toString());
          wifiIP = "Failed to get Wifi IP";
        }

        setState(() {
          _ssidFilter.text =  wifiName;
          _bssidFilter.text =  wifiBSSID;

          _msg = "OK";
        });
        break;
      case ConnectivityResult.mobile:
      case ConnectivityResult.none:
        break;
      default:
        break;
    }
  }

  Future<bool> requestPermission() async {
    // 申请权限
    Map<PermissionGroup, PermissionStatus> permissions =
    await PermissionHandler().requestPermissions([PermissionGroup.location,]);
    // 申请结果
    PermissionStatus permission =
    await PermissionHandler().checkPermissionStatus(PermissionGroup.location);
    if (permission == PermissionStatus.granted) {
      return true;
    } else {
//      提示失败！
      return false;
    }
  }

  Future<void> _configureEsp() async {
    String output = "Unknown";
    setState(() {
      _isLoading = true;
    });

    try {
      Smartconfig.start(_ssid, _bssid, _password).then( (v)=>
          setState(() {
            _isLoading = false;
            _msg = "配好了！";
          })
      );

    } on PlatformException catch (e) {
      output = "Failed to configure: '${e.message}'.";
      setState(() {
        _isLoading = false;
        _msg = output;
      });
    }
  }
}
