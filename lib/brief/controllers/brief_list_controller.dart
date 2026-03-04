// lib/brief/controllers/brief_list_controller.dart

import 'package:flutter/material.dart';
import '../models/brief_model.dart';
import '../services/brief_service.dart';

class BriefListController extends ChangeNotifier {
  final BriefService _briefService = BriefService();

  List<BriefModel> briefs = [];
  bool isLoading = true;

  Future<void> loadBriefs(String siteId) async {
    isLoading = true;
    notifyListeners();

    try {
      briefs = await _briefService.getBriefsBySite(siteId);
    } catch (e) {
      briefs = [];
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String siteId) async {
    await loadBriefs(siteId);
  }
}
