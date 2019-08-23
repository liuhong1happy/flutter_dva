import 'dart:async';
import 'dart:convert';
import 'package:flutter_dva/core/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _VoidCallback = void Function();

const PERSIST_REDUCER = "_persist";
const PERSIST_ACTION = "_persist";
const SAVE_ACTION = "_save";
const PERSISTED_ACTION = "_persisted";
const SAVED_ACTION = "_saved";
const PREFIX = "perist:";

class PersistTmpl extends StateTmpl {
  int version = -1;
  bool persist = false;
  DateTime updateAt = DateTime.now();
  PersistTmpl();

  void fromJson(Map json) {
    version = json['version'];
    persist = json['persist'];
    updateAt = DateTime.fromMillisecondsSinceEpoch(json['updateAt']);
  } 

  Map toJson() =>{
    'version': version,
    'persist' :persist,
    'updateAt': updateAt.millisecondsSinceEpoch,
  };
}

class ReduxPersistor {
  Store store;
  Timer timer;
  // 心跳时长 默认1500毫秒
  int heartBeat = 1500;

  _VoidCallback storeSubCallback;

  ReduxPersistor({ this.store, this.heartBeat }){
    storeSubCallback = (){
      startPersist();
    };
    this.store.subscribe(startPersist);
    this.store.rootReducer.reducers[PERSIST_REDUCER] = PersistReducer(persist: this, store: store);
    this.store.rootState[PERSIST_REDUCER] = StoreOfState<PersistTmpl>(state: new PersistTmpl(), updateAt: DateTime.now());
  }

  void startPersist() {
      // 如果还有处于激活中的定时器，则直接取消掉，进入下一个心跳
      if(timer != null && timer.isActive) timer.cancel();
      timer = new Timer(new Duration(milliseconds: heartBeat), ()=> save());
  }

  Future persist() async {
    Map<String, StoreOfState<dynamic>> state = store.getState();
    await Future.wait(state.entries.map((item) async {
      String persistJSON = await getJSON(item.key);
      Map<String, dynamic>  persistItem = persistJSON != null ? JsonDecoder().convert(persistJSON) : null;
      if(persistItem != null) {
       StoreOfState storeOfState = store.rootState[item.key];
       StateTmpl stateTmpl = (storeOfState.getState() as StateTmpl);
       stateTmpl.fromJson(persistItem);
       storeOfState.setState(stateTmpl);
      }
      return await Future.delayed(new Duration(milliseconds: 1));
    }));
    store.dispatch(Action(PERSISTED_ACTION, {}));
  }

  Future save() async {
    Map<String, StoreOfState<dynamic>> state = store.getState();
    await Future.wait(state.entries.map((item) async {
      String persistJSON = JsonEncoder().convert(item.value.getState());
      return await saveJSON(item.key, persistJSON);
    }));
    store.dispatch(Action(SAVED_ACTION, {}));
  }

  Future saveJSON(String key, String persistJSON) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(PREFIX+key, persistJSON);
  }

  Future<String> getJSON(String key) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String persistJSON = sharedPreferences.getString(PREFIX+key);
    return persistJSON;
  }
}

class PersistReducer extends Reducer<PersistTmpl> {
  ReduxPersistor persist;
  PersistReducer({ this.persist, Store store }): super(store: store);
  @override
  runReducer(StoreOfState<PersistTmpl> state, Action action) {
    PersistTmpl lState = state.getState();
    switch (action.type) {
      case PERSIST_ACTION:
        persist.persist();
        break;
      case SAVE_ACTION:
        persist.save();
        break;
      case PERSISTED_ACTION:
        lState.version += 1;
        lState.persist = true;
        state.setState(lState);
        break;
      case SAVED_ACTION:
        lState.updateAt = DateTime.now();
        state.setState(lState);
        break;
      default: break;
    }
    return state;
  }
}

