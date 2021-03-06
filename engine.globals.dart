import './widgets/engine.text.dart';
import 'dart:math';

// import './widgets/engine.text.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import './engine.app.localization.dart';
import './engine.error.helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///
/// `Engine` 에서 사용하는 글로벌 변수 몽므

import './engine.model.dart';

/// `Engine` `state model` 을 여기서 한번만 생성하여 글로벌 변수로 사용한다.
/// 글로벌 변수 명은 `ef` 이며, 이 값을 Provider 에 등록하면 되고, 필요하면 이 객체를 바로 사용하면 된다.
///
/// * 객체 생성은 main.dart 에서 하면 된다.
EngineModel _ef;

set ef(value) => _ef = value;
EngineModel get ef {
  assert(_ef != null, '===> Engine error! [ef] is not set.');
  assert(_ef.navigatorKey != null,
      '[GlobalKey<NavigatorState> navigatorKey] is not set. So, you cannot use context in Engine. Please set it on main.dart');
  return _ef;
}

const String hiveCacheBox = 'cache';

/// Returns translated string from the text code.
/// If [code] is [EngineError], then it takes [EngineError.code] as [code] and translate it.
String t(code, {info}) {
  // print(code);
  if (code is EngineError) {
    code = code.code;
    // if (info == null) info = code.message;
  }
  if (code is FlutterError) code = code.message;
  if (code is PlatformException) {
    // @fix type error
    // print('code: ');
    // print(code);
    String _code = '';
    _code += code?.code ?? '';
    _code += ' ' + code?.message ?? '';
    // print(_code);
    // if ( code?.details != null && code?.details[0] != null ) {
    //   _code += ' ' + code.details[0];
    // }
    code = _code;
    // code =  '${code.code} ${code.message} ${code.details['code']}';
  }

  return AppLocalizations.of(ef.context).t(code, info: info);
}

/// App language code
/// @return two letter string
///   'ko' - Korean
///   'en' - English
///   'zh' - Chinese
///   'ja' - Japanese.
String appLanguageCode() {
  return AppLocalizations.of(ef.context).locale.languageCode;
}

bottomSheet(List<Map<String, dynamic>> items) {
  showModalBottomSheet(
    context: ef.context,
    builder: (BuildContext bc) {
      return SafeArea(
        child: Container(
          child: new Wrap(
            children: <Widget>[
              for (var item in items)
                new ListTile(
                  leading: new Icon(item['icon']),
                  title: new Text(item['text']),
                  onTap: item['onTap'],
                  // new ListTile(
                  //   leading: new Icon(Icons.videocam),
                  //   title: new Text('Video'),
                  //   onTap: () => {},
                ),
            ],
          ),
        ),
      );
    },
  );
}

void _back({arguments}) {
  Navigator.pop(ef.context, arguments);
}

/// Show alert box
/// @example AppService.alert(null, e.message);
// engineAlert(String title, { String content}) {
//   if ( content == null ) {
//     content = title;
//     title = null;
//   }
//   showPlatformDialog(
//     context: ef.context,
//     builder: (_) => PlatformAlertDialog(
//       title: title != null ? Text(title) : null,
//       content: Text(content),
//       actions: <Widget>[
//         PlatformDialogAction(
//           child: PlatformText(t('Ok')),
//           onPressed: () => Navigator.pop(ef.context),
//         ),
//       ],
//     ),
//   );
// }

/// Show alert box
/// @example async( onError: alert );
/// @example alert(e) - where `e` can be an Error Object.
alert(dynamic title, {String content}) {
  /// 제목이 문자열이 아니면, t() 한다.
  if (title != null && !(title is String)) {
    title = t(title);
  }

  /// 내용이 문자열이 아니면, t() 한다.
  if (content != null && !(content is String)) {
    content = t(content);
  }
  if (content == null) {
    content = title;
    title = null;
  }
  showPlatformDialog(
    context: ef.context,
    builder: (_) => PlatformAlertDialog(
      title: title != null ? Text(title) : null,
      content: Text(content),
      actions: <Widget>[
        PlatformDialogAction(
          child: PlatformText(t('Ok')),
          onPressed: () => Navigator.pop(ef.context),
        ),
      ],
    ),
  );
}

openDialog(childWidget) {
  return showGeneralDialog(
    context: ef.context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(ef.context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext buildContext, Animation animation,
        Animation secondaryAnimation) {
      return childWidget;
    },
  );
}

/// Can it be synchronous by using async/await? So, it does not need to use callback functions.
confirm({String title, String content, Function onNo, Function onYes}) {
  return showPlatformDialog<void>(
    context: ef.context,
    builder: (context) {
      return AlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(content),
        actions: <Widget>[
          FlatButton(
            child: T('no'),
            onPressed: () {
              onNo();
              _back();
            },
          ),
          FlatButton(
            child: T('yes'),
            onPressed: () {
              onYes();
              _back();
            },
          )
        ],
      );
    },
  );
}

/// 랜덤 문자열을 리턴한다.
///
/// [length] 리턴 받을 랜덤 문자열의 길이를 정 할 수 있다.
String randomString({int length = 24}) {
  var rand = new Random();
  var codeUnits = new List.generate(length, (index) {
    return rand.nextInt(33) + 89;
  });

  return new String.fromCharCodes(codeUnits);
}

/// Enum 의 값을 바탕으로 enum 요소 참조
/// 예)
/// ``` dart
/// enum animals { cat, dog }
/// var re = enumValueFromString('dog', animals.value);
/// ```
/// 위와 같은 경우, re 는 `animals.dog` 값이 된다.
/// 일반적으로 `enum`의 경우, 값으로 해당 요소를 참조 할 수 없지만, 아래의 함수로 가능하다.
String enumValueToString(Object o) => o.toString().split('.').last;
T enumValueFromString<T>(String key, Iterable<T> values) => values.firstWhere(
      (v) => v != null && key == enumValueToString(v),
      orElse: () => null,
    );

/// 다른 라우트로 이동을 한다.
redirect(String route, {arguments}) {
  return Navigator.pushNamed(
    ef.context,
    route,
    arguments: arguments,
  );
}


/// Returns true if [obj] is one of null, false, empty string, or 0.
bool isEmpty(obj) {
  return obj == null || obj == '' || obj == false || obj == 0;
}


