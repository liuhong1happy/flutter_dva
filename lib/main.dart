import 'package:flutter/material.dart';
import 'package:flutter_dva/app.dart';
import 'package:flutter_dva/dva.dart';
import 'package:flutter_dva/src/models/home.dart';
import 'package:flutter_dva/src/states/home.dart';

StoreOfState<CountStateTmpl> homeState = new StoreOfState<CountStateTmpl>(state: CountStateTmpl(0));

Dva dva = Dva(DvaOpts(
initialState: <String, StoreOfState<dynamic>>{
  'home': homeState
},
models: [
  new HomeModel()
]));

WidgetCreatorFunction app = dva.start(() => MyApp(), () {
  ReduxPersistor persistor = new ReduxPersistor(store: dva.store, heartBeat: 450);
  persistor.persist();
});

void main() {
  return runApp(app());
}