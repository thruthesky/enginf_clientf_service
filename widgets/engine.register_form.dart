import '../engine.defines.dart';
import '../widgets/engine.text.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import './engine.button.dart';

import '../engine.globals.dart';
import '../engine.user.helper.dart';
import './engine.register.user_photo.dart';
import './engine.space.dart';
import './engine.upload_icon.dart';
import './upload_progress_bar.dart';
import 'package:flutter/material.dart';

class EngineRegisterFrom extends StatefulWidget {
  EngineRegisterFrom({
    @required this.onError,
    @required this.onRegisterSuccess,
    @required this.onUpdateSuccess,
  });

  final Function onError;
  final Function onRegisterSuccess;
  final Function onUpdateSuccess;
  @override
  _EngineRegisterFromState createState() => _EngineRegisterFromState();
}

class _EngineRegisterFromState extends State<EngineRegisterFrom> {
  EngineUser user = EngineUser();
  int progress = 0;
  bool inSubmit = false;
  bool inLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  /// Gets user registration data from the form
  /// TODO - form validation
  getFormData() {
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String nickname = _nicknameController.text;
    final String phoneNumber = _phoneNumberController.text;
    final String birthday = _birthdayController.text;

    /// 여기서 부터. 회원 정보에서 displayName, phoneNumber, photoURL 이... Auth 에 저장되고, Firestore 에 저장되지 않는지 확인.
    /// 회원 정보 수정. Auth 에 있는 값과 Firestore 에 있는 값을 모두 잘 수정하는지 확인.
    ///
    final data = {
      'displayName': nickname,
      'phoneNumber': phoneNumber,
      'birthday': birthday,
    };

    /// 회원 가입
    if (ef.notLoggedIn) {
      /// 회원 가입시에만 이메일과 비빌번호를 지정
      data['email'] = email;
      data['password'] = password;

      /// 회원 가입을 할 때에는 사진이 `Anonymous` 로 업로드 되어져있는데,
      ///   - 그 사진의 URL 을 `Enginef`로 전달하고
      ///   - `Enginef`에서 해당 사용자의 `Firebase Auth` 에 기록을 한다.
      if (user.urls != null && user.urls.length > 0) {
        data['photoURL'] = user.urls[0];
      }
    }
    return data;
  }

  @override
  void initState() {
    if (ef.loggedIn) {
      loadProfile();
    }
    super.initState();
  }

  loadProfile() async {
    // print('loading profile');
    setState(() => inLoading = true);
    try {
      var _user = await ef.userProfile();
      if (mounted) {
        setState(() {
          user = _user;
          _nicknameController.text = user.displayName;
          _phoneNumberController.text = user.phoneNumber;
          _birthdayController.text = user.birthday;
        });
      }
    } catch (e) {
      widget.onError(e);
      // AppService.alert(null, t(e));
    }

    setState(() => inLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        EngineUploadIcon(
          user,
          onProgress: (p) {
            /// 업로드 Percentage 표시
            setState(() {
              progress = p;
            });
          },
          onUploadComplete: (String url) async {
            /// 사진 업로드
            try {
              /// 사진을 업로드하면, `Enginef` 에 바로 저장을 해 버린다. 즉, 전송 버튼을 누르지 않아도 이미 업데이트가 되어져 버린다.
              await ef.userUpdate({'photoURL': url});
              setState(() {});
            } catch (e) {
              widget.onError(e);
              // AppService.alert(null, t(e));
            }
          },
          onError: (e) => widget.onError(e),
          icon: EngineRegisterUserPhoto(
            user,
            onError: (e) => widget.onError(e),
          ),
        ),
        EngineProgressBar(progress),
        EnginePageSpace(),
        if (inLoading) PlatformCircularProgressIndicator(),
        ef.notLoggedIn
            ? TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (text) {},
                decoration: InputDecoration(
                  hintText: t('input email'),
                ),
              )
            : Text(user?.email ?? ''),
        EngineSpace(),
        if (ef.notLoggedIn)
          TextField(
            controller: _passwordController,
            onSubmitted: (text) {},
            decoration: InputDecoration(
              hintText: t('input password'),
            ),
          ),
        EngineSpace(),
        TextField(
          controller: _nicknameController,
          onSubmitted: (text) {},
          decoration: InputDecoration(
            hintText: t('input nickname'),
          ),
        ),
        EngineSpace(),
        TextField(
          controller: _phoneNumberController,
          onSubmitted: (text) {},
          decoration: InputDecoration(
            hintText: t('input phone number'),
          ),
        ),
        EngineSpace(),
        TextField(
          controller: _birthdayController,
          onSubmitted: (text) {},
          decoration: InputDecoration(
            hintText: t('input birthday'),
          ),
        ),
        FlatButton(
          onPressed: () {
            DatePicker.showDatePicker(
              context,
              showTitleActions: true,
              minTime: DateTime(1940, 1, 1),
              maxTime: DateTime(2020, 1, 1),
              onChanged: (date) {
                // print('change $date');
              },
              onConfirm: (date) {
                print('confirm $date');
                String ymd =
                    date.toString().split(' ').elementAt(0).split('-').join('');
                // print('ymd: $ymd');
                setState(() {
                  _birthdayController.text = ymd;
                });
              },
              currentTime: DateTime.parse(isEmpty(_birthdayController.text)
                  ? '20000101'
                  : _birthdayController.text),
              locale: enumValueFromString(appLanguageCode(), LocaleType.values),
            );
          },
          child: T(
            SHOW_DATE_PICKER,
            style: TextStyle(color: Colors.blue),
          ),
        ),
        EngineButton(
          loader: inSubmit,
          text: ef.notLoggedIn ? t('register submit') : t('update submit'),
          onPressed: () async {
            /// 전송 버튼
            if (inSubmit) return;
            if (_birthdayController.text.length != 8) {
              alert(t(BIRTHDAY_8_DIGITS));
              return;
            }
            setState(() => inSubmit = true);
            final data = getFormData();
            try {
              if (ef.notLoggedIn) {
                await ef.register(data);
                widget.onRegisterSuccess();
              } else {
                await ef.userUpdate(data);
                widget.onUpdateSuccess();
              }
            } catch (e) {
              widget.onError(e);
            }
            setState(() => inSubmit = false);
          },
          // child: ef.notLoggedIn ? T('register submit') : T('update submit'),
        ),
      ],
    );
  }
}
