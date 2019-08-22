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