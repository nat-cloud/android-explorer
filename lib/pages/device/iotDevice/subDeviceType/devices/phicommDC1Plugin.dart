//PhicommDC1Plugin:https://github.com/iotdevice/phicomm_dc1
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nat_explorer/constants/Config.dart';
import 'package:nat_explorer/pages/device/iotDevice/iotDeviceModel.dart';
import 'package:nat_explorer/pages/device/iotDevice/subDeviceType/commWidgets/info.dart';

class PhicommDC1PluginPage extends StatefulWidget {
  PhicommDC1PluginPage({Key key, this.device}) : super(key: key);

  final IoTDevice device;

  @override
  _PhicommDC1PluginPageState createState() => _PhicommDC1PluginPageState();
}

class _PhicommDC1PluginPageState extends State<PhicommDC1PluginPage> {
  static const Color onColor = Colors.green;
  static const Color offColor = Colors.red;

  static const String logLed = "logLed";
  static const String wifiLed = "wifiLed";

  static const String plugin4 = "plugin4";
  static const String plugin5 = "plugin5";
  static const String plugin6 = "plugin6";

//  总开关
  static const String plugin7 = "plugin7";

//  bool _logLedStatus = true;
//  bool _wifiLedStatus = true;
//  bool _primarySwitchStatus = true;
  Map<String, bool> _status = Map.from({
    logLed: true,
    wifiLed: true,

    plugin4: true,
    plugin5: true,
    plugin6: true,
    plugin7: true,
  });

  Map<String, String> _realName = Map.from({
    logLed: "Logo灯",
    wifiLed: "WIFI灯",

    plugin7: "总开关",
    plugin6: "第一个插口",
    plugin5: "第二个插口",
    plugin4: "第三个插口",
  });

  @override
  void initState() {
    super.initState();
    _getCurrentStatus();
    print("init iot devie List");
  }

  @override
  Widget build(BuildContext context) {
    final List _result = [logLed,plugin7,wifiLed,plugin6,plugin5,plugin4];
    final tiles = _result.map(
          (pair) {
            switch (pair) {
              case logLed:
              case plugin7:
              case wifiLed:
              case plugin6:
              case plugin5:
              case plugin4:
                return ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(_realName[pair]),
                      Switch(
                        onChanged: (_){
                          _changeSwitchStatus(pair);
                        },
                        value: _status[pair],
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                      ),
                    ],
                  ),
                );
                break;
              default:
                return ListTile(
                  title: Text(
                    "不支持的项目:$pair",
                  ),
                );
                break;
            }
      },
    );
    final divided = ListTile.divideTiles(
      context: context,
      tiles: tiles,
    ).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text("开关控制"),
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.settings,
                color: Colors.white,
              ),
              onPressed: () {
                _setting();
              }),
          IconButton(
              icon: Icon(
                Icons.info,
                color: Colors.white,
              ),
              onPressed: () {
                _info();
              }),
        ],
      ),
      body: ListView(children: divided),
    );
  }

  _getCurrentStatus() async {
    String url = "${widget.device.baseUrl}/status";
    http.Response response;
    try {
      response = await http.get(url).timeout(const Duration(seconds: 2));
      print(response.body);
    } catch (e) {
      print(e.toString());
      return;
    }
//    同步状态到界面
    if (response.statusCode == 200) {
      setState(() {
//    log灯的状态
        _status[logLed] = jsonDecode(response.body)[logLed] == 1 ? true : false;
//    wifi灯的状态
        _status[wifiLed] =
            jsonDecode(response.body)[wifiLed] == 1 ? true : false;

        _status[plugin4] =
            jsonDecode(response.body)[plugin4] == 1 ? true : false;
        _status[plugin5] =
            jsonDecode(response.body)[plugin5] == 1 ? true : false;
        _status[plugin6] =
            jsonDecode(response.body)[plugin6] == 1 ? true : false;
//    总开关的状态
        _status[plugin7] =
            jsonDecode(response.body)[plugin7] == 1 ? true : false;
      });
    } else {
      print("获取状态失败！");
    }
  }

  _setting() async {
    // TODO 设备设置
    TextEditingController _name_controller = TextEditingController.fromValue(
        TextEditingValue(text: widget.device.info["name"]));
    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: Text("设置名称："),
                content: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _name_controller,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10.0),
                        labelText: '名称',
                      ),
                    )
                  ],
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text("取消"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text("修改"),
                    onPressed: () async {
                      try {
                        String url =
                            "${widget.device.baseUrl}/rename?name=${_name_controller.text}";
                        http.get(url).timeout(const Duration(seconds: 2));
                      } catch (e) {
                        print(e.toString());
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                  )
                ]));
  }

  _info() async {
    // TODO 设备信息
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return InfoPage(
            device: widget.device,
          );
        },
      ),
    );
  }

  _changeSwitchStatus(String name) async {
    String url;
    if (_status[name]) {
      url = "${widget.device.baseUrl}/switch?off=$name";
    } else {
      url = "${widget.device.baseUrl}/switch?on=$name";
    }
    http.Response response;
    try {
      response = await http.get(url).timeout(const Duration(seconds: 2));
      print(response.body);
    } catch (e) {
      print(e.toString());
      return;
    }
    _getCurrentStatus();
  }
}
