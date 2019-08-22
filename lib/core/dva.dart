import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_dva/core/reducer.dart';

abstract class Component  extends StatefulWidget {
  const Component({
    Key key,
  }) : super(key: key);

  @protected
  State createState();
}

class Connect<T, W extends Component> extends State<W> {
  T state;
  final Map<String, Function> props = new Map<String, Function>();
  Store store;
  VoidCallback storeSubCallback;

  Connect(T f(Map<String, StoreOfState> rootState), Map<String, Function> propsMap) {
    store = Provider.getInstance().store;
    props["dispatch"] = store.dispatch;
    var iterator = propsMap.entries.iterator;
    do {
      if(iterator.current !=null) {
        String key = iterator.current.key;
        Function actionCreator = iterator.current.value;
        props[key] = (dynamic payload) {
          Action action = actionCreator(payload);
          store.dispatch(action);
        };
      }
    } while (iterator.moveNext());
    state = f(store.rootState);
    storeSubCallback = ()=> setState(()=>{});
    store.subscribe(storeSubCallback);
  }

  @override
  dispose() {
    super.dispose();
    store.remove(storeSubCallback);
  }

  @override
  Widget build(BuildContext context) {
    return null;
  }
}

class Provider {
    /// 单例对象
  static Provider _instance;

  Store store;

  /// 内部构造方法，可避免外部暴露构造函数，进行实例化
  Provider._internal();

  /// 工厂构造方法，这里使用命名构造函数方式进行声明
  factory Provider.getInstance() => _getInstance();

  /// 获取单例内部方法
  static _getInstance() {
    // 只能有一个实例
    if (_instance == null) {
      _instance = Provider._internal();
    }
    return _instance;
  }
}

class ModelEffects {
  dynamic dispatch(Action action) {
    if(action.type.contains("/")) {
      return this.dispatchOrigin(action);
    } else {
      return this.dispatchOrigin(new Action("$namespace/${action.type}", action.payload));
    }
  }
  StoreGetStateFunction getState;
  DispatchFunction dispatchOrigin;
  String namespace;
  ModelEffects(this.dispatchOrigin, this.getState, this.namespace);
}

typedef Future EffectFunction(Action action, ModelEffects effects);
typedef StoreOfState ReducerFuction(StoreOfState state, Action action);
typedef Map<String, StoreOfState> StoreGetStateFunction();
typedef dynamic DispatchFunction(Action action);

class Model<T> {
  String namespace;
  StoreOfState<T> state;
  Map<String, ReducerFuction> reducers;
  Map<String, EffectFunction> effects;
}

class DvaOpts {
  List<Model> models;
  Map<String, StoreOfState> initialState;
  DvaOpts({ this.models, this.initialState });
}

class DvaReducer<T> extends Reducer<T> {
  Model model;
  Store store;
  DvaReducer({ this.model, this.store }) {
    this.initState = this.model.state;
  }
  StoreOfState<T> lastState = new StoreOfState<T>();

  canUpdate(StoreOfState<T> lState, StoreOfState<T> nState) {
    // 比较两个State, 目前是以最后更改时间做判断
    return lState.updateAt != nState.updateAt;
  }

  broadcast() {
    Map<String, StoreOfState<dynamic>> nextStateMap = store.getState();
    StoreOfState<T> nextState = nextStateMap[model.namespace];
    if(canUpdate(lastState, nextState)) {
      store.broadcast();
      lastState = nextState.clone();
    }
  }
  
  @override
  runReducer(StoreOfState<T> state, Action action) {
    String type = action.type;
    if(type.contains("/") && type.split("/").first == model.namespace) {
      String key = type.split("/").last;
      if(model.reducers.containsKey(key)) {
        StoreOfState<T> newState = model.reducers[key](state, action);
        broadcast();
        return newState;
      }
      if(model.effects.containsKey(key)) {
        DispatchFunction dispatch = store.dispatch;
        StoreGetStateFunction getState = store.getState;
        Future future = model.effects[key](action, ModelEffects(dispatch, getState, model.namespace));
        future.then((res) => {}).catchError((error)=> {});
      }
    }
    return state;
  }
}

typedef Widget WidgetCreatorFunction();

class Dva {
  Map<String, Model> models = new Map<String, Model>();
  Store store;
  RootReducer rootReducer = RootReducer();
  Map<String, Reducer<dynamic>> reducers = new Map<String, Reducer<dynamic>>();

  Dva(DvaOpts opts) {
    opts.models.forEach((model) {
      // 如果DvaOpts中包含了initialState，且initialState中包含model.namespace一样的key，则会优先已opts.initialState[model.namespace] 取值给model的初始
      model.state = 
        opts.initialState != null && opts.initialState.containsKey(model.namespace) 
          ? opts.initialState[model.namespace] : model.state;
      models[model.namespace] = model;
    });
  }

  createRootReducer() {
    Iterator iterator = models.entries.iterator;
    do {
      if(iterator.current != null) {
        String key = iterator.current.key;
        Model model = iterator.current.value;
        reducers[key] =  DvaReducer(model: model, store: store);
      }
    } while (iterator.moveNext());
    rootReducer.combineReducers(reducers);
    return rootReducer;
  }

  dispatch(Action action) {
    store.rootState = rootReducer.doReducer(store.rootState, action);
  }

  WidgetCreatorFunction start(WidgetCreatorFunction widgetCreator) {
    store = createStore(createRootReducer());
    store.rootReducer.reducers.forEach((key, reducer)=> (reducer as DvaReducer).store = store);
    Provider provider = Provider.getInstance();
    provider.store = store;
    return () => widgetCreator();
  }
}
