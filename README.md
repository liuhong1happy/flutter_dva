# flutter_dva

# Config
```yaml
/// pubspec.yaml

dependencies:
  flutter:
    sdk: flutter
  flutter_dva: 0.0.1
```

# Use

```dart
/// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dva/app.dart';
import 'package:flutter_dva/dva.dart';
import 'package:flutter_dva/src/models/home.dart';
import 'package:flutter_dva/src/states/home.dart';

class CountStateTmpl extends StateTmpl {
  num count;
  CountStateTmpl(this.count);

  void fromJson(Map json) {
    count = json['count'];
  }

  Map toJson() =>{
    'count': count,
  };
}

StoreOfState<CountStateTmpl> homeState = new StoreOfState<CountStateTmpl>(state: CountStateTmpl(0));

Dva dva = Dva(DvaOpts(
initialState: <String, StoreOfState<dynamic>>{
  'home': homeState
},
models: [
  new HomeModel()
]));

WidgetCreatorFunction app = dva.start(() => MyApp(), () {
  ReduxPersistor persistor = new ReduxPersistor(store: dva.store, heartBeat: 1500);
  persistor.persist();
});

void main() {
  return runApp(app());
}

/// src/models/home.dart
import 'package:flutter_dva/dva.dart';
import 'package:flutter_dva/src/states/home.dart';

class HomeModel implements Model<CountStateTmpl> {
  @override
  Map<String, EffectFunction> effects = <String, EffectFunction>{
    "incrementCounter":  (Action action, ModelEffects effects) async {
      StoreOfState<CountStateTmpl> state = effects.getState()["home"];
      CountStateTmpl tmpl = state?.getState();

      await Future.delayed(new Duration(microseconds: 450));
      tmpl.count += 1;
      effects.dispatch(Action("save", tmpl));
    }
  };

  @override
  String namespace = "home";

  @override
  Map<String, ReducerFuction> reducers = <String, ReducerFuction>{
    "save": (StoreOfState<dynamic> lastState, Action action) {
      lastState.setState(action.payload);
      return lastState;
    }
  };

  @override
  StoreOfState<CountStateTmpl> state = new StoreOfState<CountStateTmpl>(state: CountStateTmpl(1));
}


/// home-page.dart
import 'package:flutter/material.dart' hide Action;
import 'package:flutter_dva/dva.dart';
import 'package:flutter_dva/src/states/home.dart';

class MyHomePage extends Component {
  final String title;
  MyHomePage({this.title});
  @override
  State<StatefulWidget> createState() => MyHomePageState();
}
class MyHomePageState extends Connect<CountStateTmpl, MyHomePage> {
  MyHomePageState({Key key}) : 
    super((rootState)=> (rootState["home"] as StoreOfState<CountStateTmpl>)?.getState(), {
      "incrementCounter": (payload)=> new Action('home/incrementCounter', payload)
    });
  @override
  Widget build(BuildContext context) {
    // 引入数据
    num count = state?.count;
    // 引入方法
    void incrementCounter() {
      props["incrementCounter"]({});
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
```