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
    num count = state?.count;
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

