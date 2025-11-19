import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/hotel_card_controller.dart';
import '../../models/HotelCardData.dart';

class UserHomeScreen extends StatefulWidget {
  final AuthController authController;
  final HotelCardController hotelCardController;

  const UserHomeScreen({
    super.key,
    required this.authController,
    required this.hotelCardController,
  });

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late TextEditingController _locationController;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guests = 2;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();

    // 🔹 Listen to text changes → filter cards
    _locationController.addListener(_onLocationChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _onLocationChanged() {
    widget.hotelCardController.filterCards(_locationController.text);
  }

  void _initData() {
    final user = widget.authController.currentUser;
    if (user == null) {
      // Optional: handle guest mode or redirect
      debugPrint('⚠️ No user logged in');
      return;
    }

    // 🔁 Load cards → then init favorites
    widget.hotelCardController.loadCards().then((_) {
      if (!mounted) return;
      debugPrint('✅ Cards loaded: ${widget.hotelCardController.filteredCardsCount}');
      if (widget.hotelCardController.error != null) {
        _showError(widget.hotelCardController.error!);
        return;
      }

      widget.hotelCardController.initFavorites(user.id).then((_) {
        if (!mounted) return;
        debugPrint('✅ Favorites synced: ${widget.hotelCardController.favoriteIdsCount}');
        // UI auto-updates via addListener
      }).catchError((e) {
        debugPrint('❌ initFavorites error: $e');
        if (mounted) _showError('Erreur chargement favoris');
      });
    }).catchError((e) {
      debugPrint('❌ loadCards error: $e');
      if (mounted) _showError('Impossible de charger les hôtels');
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _locationController
      ..removeListener(_onLocationChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hello,', style: TextStyle(fontSize: 16, color: Color(0xFF7A7A7A))),
                      const SizedBox(height: 4),
                      Text(
                        widget.authController.currentUser?.username ?? 'Utilisateur',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_outlined, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 🔹 Search Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search location or hotel name...',
                        border: InputBorder.none,
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _checkInDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (date != null && mounted) {
                                setState(() {
                                  _checkInDate = date;
                                });
                              }
                            },
                            icon: Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF7A7A7A)),
                            label: Text(
                              _checkInDate?.toString().split(' ')[0] ?? 'Check in',
                              style: TextStyle(color: Colors.black),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              backgroundColor: const Color(0xFFF8F8F8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              if (_checkInDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Veuillez sélectionner une date d\'arrivée')),
                                );
                                return;
                              }
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _checkOutDate ?? _checkInDate!.add(const Duration(days: 1)),
                                firstDate: _checkInDate!,
                                lastDate: DateTime(2030),
                              );
                              if (date != null && mounted) {
                                setState(() {
                                  _checkOutDate = date;
                                });
                              }
                            },
                            icon: Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF7A7A7A)),
                            label: Text(
                              _checkOutDate?.toString().split(' ')[0] ?? 'Check out',
                              style: TextStyle(color: Colors.black),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              backgroundColor: const Color(0xFFF8F8F8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 20, color: Color(0xFF7A7A7A)),
                        const SizedBox(width: 8),
                        Text('Guests', style: TextStyle(color: Color(0xFF7A7A7A))),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, size: 20),
                              onPressed: () {
                                if (_guests > 1) {
                                  setState(() {
                                    _guests--;
                                  });
                                }
                              },
                            ),
                            Text('$_guests', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.add, size: 20),
                              onPressed: () {
                                setState(() {
                                  _guests++;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/search-results',
                            arguments: {
                              'location': _locationController.text,
                              'checkIn': _checkInDate,
                              'checkOut': _checkOutDate,
                              'guests': _guests,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4C9FC1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Explore Hotels',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyan),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/explore');
                    },
                    child: const Text('See more', style: TextStyle(color: Color(0xFF3A3A3A))),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // ✅ CAROUSEL — manually listening to changes
              _HotelCarouselSection(
                hotelCardController: widget.hotelCardController,
                authController: widget.authController,
                userId: widget.authController.currentUser?.id ?? '0',
                checkIn: _checkInDate,      // ←
                checkOut: _checkOutDate,    // ←
                guests: _guests,            // ←
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.pushNamed(context, '/wishlist');
              break;
            case 2:
              Navigator.pushNamed(context, '/profile');
              break;
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

// 🔹 Isolated widget that listens to HotelCardController changes
class _HotelCarouselSection extends StatefulWidget {
  final HotelCardController hotelCardController;
  final AuthController authController;
  final String userId;
  final DateTime? checkIn;      // ← ajout
  final DateTime? checkOut;     // ← ajout
  final int guests;             // ← ajout

  const _HotelCarouselSection({
    required this.hotelCardController,
    required this.authController,
    required this.userId,
    required this.checkIn,      // ←
    required this.checkOut,     // ←
    required this.guests,       // ←
  });

  @override
  State<_HotelCarouselSection> createState() => _HotelCarouselSectionState();
}

class _HotelCarouselSectionState extends State<_HotelCarouselSection> {
  @override
  void initState() {
    super.initState();
    widget.hotelCardController.addListener(_updateUI);
    widget.authController.addListener(_updateUI);
  }

  @override
  void dispose() {
    widget.hotelCardController.removeListener(_updateUI);
    widget.authController.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authController.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = widget.hotelCardController;

    if (controller.isLoading) {
      return SizedBox(
        height: 220,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.error != null) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              Text(controller.error!),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => controller.loadCards(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final cards = controller.cards;
    if (cards.isEmpty) {
      return SizedBox(
        height: 220,
        child: const Center(child: Text('Aucun hôtel disponible')),
      );
    }

    return CarouselSlider.builder(
      itemCount: cards.length,
      options: CarouselOptions(
        enlargeCenterPage: true,
        viewportFraction: 0.85,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        pauseAutoPlayOnTouch: true,
        height: 220,
      ),
      itemBuilder: (context, index, realIndex) {
        return _HotelCardExactMatch(
          card: cards[index],
          userId: widget.userId,
          hotelCardController: widget.hotelCardController,
          checkIn: widget.checkIn,      // ←
          checkOut: widget.checkOut,    // ←
          guests: widget.guests,        // ←
        );
      },
    );
  }
}

// 🔹 Card — accept controller to avoid context.read
class _HotelCardExactMatch extends StatelessWidget {
  final HotelCardData card;
  final String userId;
  final HotelCardController hotelCardController;
  final DateTime? checkIn;      // ←
  final DateTime? checkOut;     // ←
  final int guests;             // ←

  const _HotelCardExactMatch({
    required this.card,
    required this.userId,
    required this.hotelCardController,
    required this.checkIn,      // ←
    required this.checkOut,     // ←
    required this.guests,       // ←
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (card.hotelId?.isNotEmpty == true) {
          Navigator.pushNamed(
            context,
            '/hotel',
            arguments: {
              'hotelId': card.hotelId,
              'checkIn': checkIn,        // ✅ maintenant disponible
              'checkOut': checkOut,      // ✅
              'guests': guests,          // ✅
            },
          );
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
                      const Icon(Icons.star, color: Colors.white, size: 12),
                      const SizedBox(width: 1),
                      Text(
                        '${card.stars}',
                        style: const TextStyle(
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
                child: GestureDetector(
                  onTap: () {
                    hotelCardController.toggleFavorite(card.id, userId);
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
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.transparent, Colors.white],
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
    String url = imageUrl.isEmpty ? '' : imageUrl;
    if (!url.contains('.') && !url.startsWith('http')) {
      url = '$url.jpg';
    }

    if (url.isEmpty) return _imagePlaceholder();

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
        progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stack) => _imagePlaceholder(),
      );
    } else {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _imagePlaceholder(),
      );
    }
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel, size: 40, color: Colors.grey),
            SizedBox(height: 4),
            Text('Image', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}