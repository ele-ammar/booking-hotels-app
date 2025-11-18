import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/HotelCardData.dart';

class HotelCardController with ChangeNotifier {
  final String _baseUrl = 'http://192.168.1.198:3000/api/hotel-cards';
  final String _wishlistUrl = 'http://192.168.1.198:3000/api/wishlist';

  List<HotelCardData> _allCards = [];
  List<HotelCardData> _filteredCards = [];
  bool _isLoading = false;
  String? _error;

  Set<String> _favoriteIds = {};

  // 🔹 Public getters — safe for UI
  List<HotelCardData> get cards {
    return _filteredCards.map((card) {
      return card.copyWith(isFavorite: _favoriteIds.contains(card.id));
    }).toList();
  }

  List<HotelCardData> get favoriteCards => _allCards
      .where((card) => _favoriteIds.contains(card.id))
      .map((card) => card.copyWith(isFavorite: true))
      .toList();

  int get allCardsCount => _allCards.length;
  int get filteredCardsCount => _filteredCards.length;
  int get favoriteIdsCount => _favoriteIds.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 🔁 Refresh UI (e.g., after favorites sync)
  void refreshCards() {
    notifyListeners();
  }

  // 🔽 Local favorites
  Future<void> _loadLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? saved = prefs.getStringList('favorites');
      _favoriteIds = saved != null ? Set<String>.from(saved) : {};
      debugPrint('📥 Local favorites loaded: $_favoriteIds');
    } catch (e) {
      debugPrint('⚠️ Erreur chargement local: $e');
    }
  }

  // ☁️ Server wishlist — SERVEUR = source de vérité
  Future<void> _loadServerWishlist(String userId) async {
    if (userId == '0') return;

    try {
      final response = await http.get(Uri.parse('$_wishlistUrl/$userId')).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        Set<String> serverIds = {};

        if (data is List) {
          for (var item in data) {
            if (item is String) {
              serverIds.add(item.trim());
            } else if (item is Map<String, dynamic>) {
              final id = (item['id'] as String?)?.trim();
              if (id != null && id.isNotEmpty) serverIds.add(id);
            }
          }
        }

        // ✅ CORRIGÉ : Remplace au lieu de fusionner
        _favoriteIds = serverIds;
        await _saveFavorites();
        debugPrint('☁️ Server favorites synced (source de vérité): $_favoriteIds');
      } else {
        debugPrint('⚠️ Serveur wishlist: ${response.statusCode}');
        _favoriteIds.clear();
        await _saveFavorites();
      }
    } catch (e) {
      debugPrint('⚠️ Erreur sync serveur: $e');
      _favoriteIds.clear();
      await _saveFavorites();
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', _favoriteIds.toList());
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde: $e');
    }
  }

  Future<void> initFavorites(String userId) async {
    await _loadLocalFavorites();
    notifyListeners();
    await _loadServerWishlist(userId);
  }

  bool isFavorite(String cardId) => _favoriteIds.contains(cardId);

  // 🔁 Load all cards
  Future<void> loadCards({String? location}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = _baseUrl;
      if (location != null && location.isNotEmpty) {
        url += '?location=${Uri.encodeComponent(location)}';
      }

      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        _allCards = jsonList
            .map((json) => HotelCardData.fromJson(json as Map<String, dynamic>))
            .toList();
        _filteredCards = List.from(_allCards);
      } else {
        _error = 'Erreur API: ${response.statusCode}';
        debugPrint('❌ loadCards: $response.statusCode → ${response.body}');
      }
    } catch (e) {
      _error = 'Impossible de charger les cartes';
      debugPrint('❌ Exception loadCards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterCards(String query) {
    if (query.isEmpty) {
      _filteredCards = List.from(_allCards);
    } else {
      final lowerQuery = query.toLowerCase().trim();
      _filteredCards = _allCards.where((card) {
        final nameMatch = card.name.toLowerCase().contains(lowerQuery);
        final locationMatch = card.location.toLowerCase().contains(lowerQuery);
        return nameMatch || locationMatch;
      }).toList();
    }
    notifyListeners();
  }

  // ✅ toggleFavorite — CORRIGÉ pour DELETE (sans erreur queryParameters)
  Future<void> toggleFavorite(String cardId, String userId) async {
    if (cardId.isEmpty || userId.isEmpty || userId == '0') {
      debugPrint('❌ toggleFavorite: cardId="$cardId", userId="$userId" — annulé');
      return;
    }

    final wasFavorite = _favoriteIds.contains(cardId);
    final willBeFavorite = !wasFavorite;

    if (willBeFavorite) {
      _favoriteIds.add(cardId);
    } else {
      _favoriteIds.remove(cardId);
    }
    notifyListeners();
    debugPrint('🎨 UI mis à jour: $cardId → ${willBeFavorite ? '❤️' : '🤍'}');

    final body = jsonEncode({
      'userId': userId,
      'hotelCardId': cardId,
    });

    bool success = false;

    try {
      http.Response response;
      if (willBeFavorite) {
        response = await http.post(
          Uri.parse('$_wishlistUrl'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
        debugPrint('📤 POST wishlist: status=${response.statusCode}');
      } else {
        // ✅ CORRIGÉ : construction manuelle de l'URI avec query params
        final uri = Uri.parse('$_wishlistUrl').replace(
          queryParameters: {
            'userId': userId,
            'hotelCardId': cardId,
          },
        );
        response = await http.delete(uri, headers: {
          'Content-Type': 'application/json',
        });
        debugPrint('🗑️ DELETE wishlist: status=${response.statusCode}, uri=$uri');
      }

      success = response.statusCode == 200 || response.statusCode == 201;
      if (!success) {
        debugPrint('❌ Réponse serveur: ${response.statusCode} → ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur réseau toggleFavorite: $e');
    }

    if (!success) {
      if (willBeFavorite) {
        _favoriteIds.remove(cardId);
      } else {
        _favoriteIds.add(cardId);
      }
      notifyListeners();
      debugPrint('🔄 Rollback: $cardId → ${willBeFavorite ? '🤍' : '❤️'}');
    } else {
      await _saveFavorites();
      debugPrint('✅ Serveur confirmé: $cardId → ${willBeFavorite ? '❤️' : '🤍'}');
    }
  }

  Future<bool> deleteCard(String cardId) async {
    if (_favoriteIds.contains(cardId)) {
      _favoriteIds.remove(cardId);
      await _saveFavorites();
    }

    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$cardId'));
      if (response.statusCode == 200) {
        await loadCards();
        return true;
      }
      _error = 'Erreur suppression: ${response.statusCode}';
    } catch (e) {
      _error = 'Erreur réseau';
    }
    notifyListeners();
    return false;
  }

  // ✅ clearWishlist — CORRIGÉ (sans queryParameters nommé)
  Future<void> clearWishlist(String? userId) async {
    if (userId == null || userId == '0') return;

    try {
      // ✅ Construction correcte de l'URI
      final uri = Uri.parse('$_wishlistUrl/clear')
          .replace(queryParameters: {'userId': userId});

      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        _favoriteIds.clear();
        await _saveFavorites();
        notifyListeners();
        debugPrint('🧹 Wishlist vidée (serveur + local)');
      } else {
        debugPrint('❌ clearWishlist serveur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ clearWishlist erreur: $e');
    }
  }

  // 🧹 Nettoyage d'urgence (à utiliser une fois si besoin)
  Future<void> clearAllLocalFavoritesNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorites');
    _favoriteIds.clear();
    debugPrint('🚨 Clef "favorites" supprimée localement');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}