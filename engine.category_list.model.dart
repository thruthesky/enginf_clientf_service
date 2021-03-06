
import './engine.category_list.helper.dart';
import './engine.globals.dart';
import 'package:flutter/material.dart';

class EngineCategoryListModel extends ChangeNotifier {
  bool inLoading = false;
  EngineCategoryListModel() {
    loadCategories();
  }
  EngineCategoryList list;
  loadCategories() async {
    inLoading = true;
    notifyListeners();
    try {
      list = await ef.categoryList();
    } catch (e) {
      alert(t(e));
    }
    inLoading = false;
    notifyListeners();
  }
}
