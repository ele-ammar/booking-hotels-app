// lib/screens/user/search_results_screen.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';

import '../../controllers/PlaceController.dart';
import '../../controllers/hotel_card_controller.dart';
import '../../controllers/auth_controller.dart'; // 👈 ajouté
import '../../models/HotelCardData.dart';

class SearchResultsScreen extends StatefulWidget {
  final String? location;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guests;

  const SearchResultsScreen({
    super.key,
    this.location,
    this.checkIn,
    this.checkOut,
    this.guests,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;


  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      Provider.of<HotelCardController>(context, listen: false)
          .filterCards(_searchController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hotelController = Provider.of<HotelCardController>(context, listen: false);
      final placeController = Provider.of<PlaceController>(context, listen: false);

      // ✅ Charger les hôtels d'abord
      await hotelController.loadCards(location: widget.location);

      // ⏳ Attendre 200ms pour laisser le backend respirer
      await Future.delayed(Duration(milliseconds: 200));

      // ✅ Puis charger les places
      await placeController.loadPlaces(location: widget.location);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location', style: TextStyle(color: Colors.grey)),
                    Text(
                      widget.location ?? 'Tout',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.checkIn?.toString().split(' ')[0] ?? 'Check in'} - ${widget.checkOut?.toString().split(' ')[0] ?? 'Check out'}',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.guests ?? 1} guests',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search Hotel By Name',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.tune, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Recommended Hotels',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              // 🔁 Hauteur réduite à 200
              SizedBox(
                height: 200,
                child: Consumer<HotelCardController>(
                  builder: (context, cardController, _) {
                    if (cardController.isLoading) return const Center(child: CircularProgressIndicator());
                    if (cardController.error != null) {
                      return Center(child: Text(cardController.error!));
                    }
                    if (cardController.cards.isEmpty) {
                      return Center(child: Text('Aucun hôtel trouvé pour "${widget.location??"Tout"}"'));
                    }

                    // 🔑 Récupère l'userId une seule fois
                    final String? userId = Provider.of<AuthController>(context, listen: false).currentUser?.id;

                    return CarouselSlider.builder(
                      itemCount: cardController.cards.length,
                      options: CarouselOptions(
                        enlargeCenterPage: true,
                        viewportFraction: 0.85,
                        autoPlay: true,
                        autoPlayInterval: Duration(seconds: 4),
                      ),
                      itemBuilder: (context, index, realIndex) {
                        final card = cardController.cards[index];
                        if (userId != null) {
                          return _HotelCardExactMatch(
                            card: card,
                            userId: userId,
                          );
                        } else {
                          return _HotelCardExactMatchNonInteractive(card: card);
                        }
                      },
                    );
                  },
                ),
              ),

              // 🔹 SECTION "RECOMMENDED PLACES" — DYNAMIQUE ✅
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 24),
                child: Text(
                  'Recommended places',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              SizedBox(
                height: 250,
                child: Consumer<PlaceController>(
                  builder: (context, placeController, _) {


                    if (placeController.isLoading) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (placeController.error != null) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(height: 8),
                            Text(
                              '❌ ${placeController.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    if (placeController.places.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucune place à ${widget.location ?? "cette destination"}',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                      children: placeController.places.map((place) {
                        return _PlaceCard(
                          name: place.name,
                          imageUrl: place.imageUrl,
                          tag: place.tag,
                          badge: place.badge,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/wishlist');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// 🔹 Carte avec cœur INTERACTIF
class _HotelCardExactMatch extends StatelessWidget {
  final HotelCardData card;
  final String userId;

  const _HotelCardExactMatch({
    required this.card,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (card.hotelId?.isNotEmpty == true) {
          Navigator.pushNamed(context, '/hotel', arguments: card.hotelId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hôtel non disponible')),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 🖼️ Image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildImage(card.imageUrl),
              ),

              // ⭐ Étoiles
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.yellow[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 12),
                      const SizedBox(width: 1),
                      Text(
                        '${card.stars}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ❤️ Cœur INTERACTIF
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    Provider.of<HotelCardController>(context, listen: false)
                        .toggleFavorite(card.id, userId);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      card.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: card.isFavorite ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // 📄 Bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              card.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.location,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${card.pricePerMonth.toStringAsFixed(0)} TND',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00AEEF),
                            ),
                          ),
                          const Text(
                            'per month',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFF8F8F8),
        child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 30)),
      );
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
        progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stack) => Container(
          color: const Color(0xFFF8F8F8),
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          color: const Color(0xFFF8F8F8),
          child: const Center(child: Icon(Icons.image, color: Colors.grey)),
        ),
      );
    }
  }
}

// 🔹 Version non interactive (si non connecté)
class _HotelCardExactMatchNonInteractive extends StatelessWidget {
  final HotelCardData card;

  const _HotelCardExactMatchNonInteractive({required this.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (card.hotelId?.isNotEmpty == true) {
          Navigator.pushNamed(context, '/hotel', arguments: card.hotelId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hôtel non disponible')),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildImage(card.imageUrl),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.yellow[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 12),
                      const SizedBox(width: 1),
                      Text(
                        '${card.stars}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    card.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: card.isFavorite ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              card.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.location,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${card.pricePerMonth.toStringAsFixed(0)} TND',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00AEEF),
                            ),
                          ),
                          const Text(
                            'per month',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFF8F8F8),
        child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 30)),
      );
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
        progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stack) => Container(
          color: const Color(0xFFF8F8F8),
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          color: const Color(0xFFF8F8F8),
          child: const Center(child: Icon(Icons.image, color: Colors.grey)),
        ),
      );
    }
  }
}


// 🔹 ✅ PlaceCard
class _PlaceCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String tag;
  final String badge;

  const _PlaceCard({
    required this.name,
    required this.imageUrl,
    required this.tag,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildImage(imageUrl), // ✅ Utilise la même logique que les hôtels
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(tag, style: TextStyle(color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge, style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ COPIÉ depuis _HotelCardExactMatch — logique identique
  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFF8F8F8),
        child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 30)),
      );
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
        progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stack) => Container(
          color: const Color(0xFFF8F8F8),
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          color: const Color(0xFFF8F8F8),
          child: const Center(child: Icon(Icons.image, color: Colors.grey)),
        ),
      );
    }
  }
}