import 'package:flutter_dva/core/redux.dart';

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