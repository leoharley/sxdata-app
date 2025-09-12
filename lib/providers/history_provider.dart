import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class HistoryProvider with ChangeNotifier {
  List<ApplicationHistory> _applications = [];
  Map<String, int> _counters = {};
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'all';
  bool _hasMore = false;
  int _currentOffset = 0;
  final int _limit = 50;

  // Getters
  List<ApplicationHistory> get applications => _applications;
  Map<String, int> get counters => _counters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedFilter => _selectedFilter;
  bool get hasMore => _hasMore;

  /// Carregar histórico de aplicações
  Future<void> loadHistory({
    int? userId,
    String? period,
    String? syncStatus,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentOffset = 0;
      _applications.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getApplicationHistory(
        userId: userId,
        period: period ?? _selectedFilter,
        syncStatus: syncStatus,
        limit: _limit,
        offset: _currentOffset,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Atualizar contadores
        _counters = Map<String, int>.from(data['counters'] ?? {});
        
        // Processar aplicações
        final newApplications = (data['applications'] as List<dynamic>? ?? [])
            .map((app) => ApplicationHistory.fromJson(app))
            .toList();

        if (refresh) {
          _applications = newApplications;
        } else {
          _applications.addAll(newApplications);
        }

        // Verificar se há mais dados
        final pagination = data['pagination'] ?? {};
        _hasMore = pagination['has_more'] ?? false;
        _currentOffset += newApplications.length;

        _error = null;
        print('✅ Histórico carregado: ${newApplications.length} itens');
      } else {
        _error = response['message'] ?? 'Erro ao carregar histórico';
        print('❌ Erro na resposta: $_error');
      }
    } catch (e, stackTrace) {
      _error = 'Erro de conexão: $e';
      print('❌ Erro ao carregar histórico: $e');
      print('📋 Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alterar filtro e recarregar
  Future<void> setFilter(String filter, {int? userId}) async {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      await loadHistory(
        userId: userId,
        period: filter == 'all' ? null : filter,
        refresh: true,
      );
    }
  }

  /// Carregar mais itens (paginação)
  Future<void> loadMore({int? userId}) async {
    if (!_isLoading && _hasMore) {
      await loadHistory(
        userId: userId,
        period: _selectedFilter == 'all' ? null : _selectedFilter,
        refresh: false,
      );
    }
  }

  /// Limpar dados
  void clearHistory() {
    _applications.clear();
    _counters.clear();
    _error = null;
    _currentOffset = 0;
    _hasMore = false;
    notifyListeners();
  }

  /// Filtrar aplicações por status local (para filtros rápidos)
  List<ApplicationHistory> getFilteredApplications(String filter) {
    switch (filter) {
      case 'pending':
        return _applications.where((app) => app.sync.status == 'pending').toList();
      case 'synced':
        return _applications.where((app) => app.sync.status == 'synced').toList();
      case 'error':
        return _applications.where((app) => app.sync.status == 'error').toList();
      default:
        return _applications;
    }
  }
}

/// Modelo para histórico de aplicação
class ApplicationHistory {
  final int id;
  final Questionnaire questionnaire;
  final Respondent respondent;
  final Location location;
  final Timing timing;
  final SyncInfo sync;
  final AdditionalData additionalData;
  final String createdAt;

  ApplicationHistory({
    required this.id,
    required this.questionnaire,
    required this.respondent,
    required this.location,
    required this.timing,
    required this.sync,
    required this.additionalData,
    required this.createdAt,
  });

  factory ApplicationHistory.fromJson(Map<String, dynamic> json) {
    return ApplicationHistory(
      id: json['id'] ?? 0,
      questionnaire: Questionnaire.fromJson(json['questionnaire'] ?? {}),
      respondent: Respondent.fromJson(json['respondent'] ?? {}),
      location: Location.fromJson(json['location'] ?? {}),
      timing: Timing.fromJson(json['timing'] ?? {}),
      sync: SyncInfo.fromJson(json['sync'] ?? {}),
      additionalData: AdditionalData.fromJson(json['additional_data'] ?? {}),
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Questionnaire {
  final int id;
  final String title;
  final String code;

  Questionnaire({
    required this.id,
    required this.title,
    required this.code,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    return Questionnaire(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

class Respondent {
  final String? name;
  final String? email;

  Respondent({this.name, this.email});

  factory Respondent.fromJson(Map<String, dynamic> json) {
    return Respondent(
      name: json['name'],
      email: json['email'],
    );
  }
}

class Location {
  final String? name;
  final double? latitude;
  final double? longitude;
  final String fullAddress;

  Location({
    this.name,
    this.latitude,
    this.longitude,
    required this.fullAddress,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      fullAddress: json['full_address'] ?? 'Localização não informada',
    );
  }
}

class Timing {
  final String? startedAt;
  final String? completedAt;
  final int? durationMinutes;
  final String? completedAtFormatted;
  final String timeAgo;

  Timing({
    this.startedAt,
    this.completedAt,
    this.durationMinutes,
    this.completedAtFormatted,
    required this.timeAgo,
  });

  factory Timing.fromJson(Map<String, dynamic> json) {
    return Timing(
      startedAt: json['started_at'],
      completedAt: json['completed_at'],
      durationMinutes: json['duration_minutes'],
      completedAtFormatted: json['completed_at_formatted'],
      timeAgo: json['time_ago'] ?? '',
    );
  }
}

class SyncInfo {
  final String status;
  final String statusLabel;
  final String statusColor;
  final String icon;

  SyncInfo({
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
  });

  factory SyncInfo.fromJson(Map<String, dynamic> json) {
    return SyncInfo(
      status: json['status'] ?? 'pending',
      statusLabel: json['status_label'] ?? 'Pendente',
      statusColor: json['status_color'] ?? '#FF9800',
      icon: json['icon'] ?? 'sync',
    );
  }
}

class AdditionalData {
  final bool hasPhoto;
  final String? photoPath;
  final bool consentGiven;
  final bool hasLocation;

  AdditionalData({
    required this.hasPhoto,
    this.photoPath,
    required this.consentGiven,
    required this.hasLocation,
  });

  factory AdditionalData.fromJson(Map<String, dynamic> json) {
    return AdditionalData(
      hasPhoto: json['has_photo'] ?? false,
      photoPath: json['photo_path'],
      consentGiven: json['consent_given'] ?? false,
      hasLocation: json['has_location'] ?? false,
    );
  }
}