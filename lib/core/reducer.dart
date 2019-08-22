class Action {
  String type;
  dynamic payload;
  Action(this.type, this.payload);
}

typedef _VoidCallback = void Function();

class Store {
  Map<String, StoreOfState> rootState;
  bool singleState = false;
  RootReducer rootReducer;
  List<_VoidCallback> listeners = [];

  Map<String, StoreOfState> getState() {
    return rootState;
  }

  void dispatch(Action action) {
    rootReducer?.doReducer(rootState, action);
  }

  subscribe(_VoidCallback f) {
    listeners.add(f);
  }

  remove(_VoidCallback f) {
    listeners.remove(f);
  }

  broadcast() {
    listeners.forEach((f) => f());
  }

  Store({ this.singleState = false, this.rootState, this.rootReducer });
}

class StoreOfState<T> {
  T state;
  DateTime updateAt;
  T getState() => state;
  setState(T newState) {
    state = newState;
    updateAt = DateTime.now();
  }
  StoreOfState({ this.state, this.updateAt }) {
    updateAt = this.updateAt != null ? this.updateAt : DateTime.now();
  }
  clone() {
    return new StoreOfState<T>(state: this.state, updateAt: this.updateAt);
  }
}

abstract class Reducer<T> {
  StoreOfState<T> initState;
  doReducer(StoreOfState<T> state, Action action) {
    return runReducer(state, action);
  }
  runReducer(StoreOfState<T> state, Action action) => state;
}

class RootReducer {
  Map<String, Reducer<dynamic>> reducers = new Map<String, Reducer<dynamic>>();
  bool singleReducer;
  Map<String, StoreOfState> initState = new Map<String, StoreOfState>();
  String singleReducerName = "rootReducer";
  RootReducer({Reducer reducer}) {
    if(reducer!=null) {
      reducers[singleReducerName] = reducer;
      singleReducer = true;
      initState[singleReducerName] =  reducer.initState;
    }
  }

  clone(RootReducer rootReducer) {
    combineReducers(rootReducer.reducers);
  }

  combineReducers(Map<String, Reducer<dynamic>> _reducers) {
    reducers.addAll(_reducers);
    singleReducer = false;
    reducers.forEach((key, value)=> initState[key] = value.initState);
  }

  doReducer(Map<String, StoreOfState> prevState, Action action) {
    return runReducer(prevState, action);
  }

  runReducer(Map<String, StoreOfState> prevState, Action action) {
    if(singleReducer) {
      reducers[singleReducerName]?.doReducer(prevState[singleReducerName], action);
    }

    var iterator = reducers.entries.iterator;

    do {
      if(iterator.current != null) {
        String key = iterator.current.key;
        StoreOfState reducerState = prevState[key];
        prevState[key] = iterator.current.value.doReducer(reducerState, action);
      }
    } while (iterator.moveNext());

    return prevState;
  }
}

createStore(RootReducer rootReducer) {
  return new Store(singleState: rootReducer.singleReducer, rootState: rootReducer.initState, rootReducer: rootReducer );
}
