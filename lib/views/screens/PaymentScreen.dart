// lib/views/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/hotel.dart';

class PaymentScreen extends StatefulWidget {
  final Hotel? hotel;
  final String? roomType;
  final double? total;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guests;

  const PaymentScreen({
    Key? key,
    this.hotel,
    this.roomType,
    this.total,
    this.checkIn,
    this.checkOut,
    this.guests,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderController = TextEditingController();

  // États
  String _selectedMethod = 'visa';
  bool _isLoading = false;

  // Focus nodes
  final _cardNumberFocus = FocusNode();
  final _expiryFocus = FocusNode();
  final _cvvFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // 🔹 Auto-format numéro de carte (espaces tous les 4 chiffres)
    _cardNumberController.addListener(() {
      final text = _cardNumberController.text;
      if (text.contains(RegExp(r'\s')) && text.endsWith(' ')) return;

      final newText = text.replaceAll(RegExp(r'\D'), '');
      final buffer = StringBuffer();
      for (int i = 0; i < newText.length; i += 4) {
        buffer.write(newText.substring(i, i + 4 > newText.length ? newText.length : i + 4));
        if (i + 4 < newText.length) buffer.write(' ');
      }
      if (_cardNumberController.text != buffer.toString()) {
        _cardNumberController.value = _cardNumberController.value.copyWith(
          text: buffer.toString(),
          selection: TextSelection.collapsed(offset: buffer.toString().length),
        );
      }
    });

    // 🔹 Auto-format CVV (3 chiffres max)
    _cvvController.addListener(() {
      final text = _cvvController.text.replaceAll(RegExp(r'\D'), '');
      if (text.length > 3) {
        _cvvController.text = text.substring(0, 3);
      }
    });

    // 🔹 Auto-format expiry (MM/YY)
    _expiryController.addListener(() {
      var text = _expiryController.text.replaceAll(RegExp(r'\D'), '');
      if (text.length > 4) text = text.substring(0, 4);
      if (text.length >= 2 && !_expiryController.text.contains('/')) {
        text = '${text.substring(0, 2)}/${text.substring(2)}';
      }
      if (_expiryController.text != text) {
        _expiryController.value = _expiryController.value.copyWith(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderController.dispose();
    _cardNumberFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  void _onPayPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // 🔹 Simuler un traitement de paiement (remplace par Stripe, PayPal, etc.)
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // ✅ Succès — navigue vers confirmation
      Navigator.pushReplacementNamed(context, '/confirmation', arguments: {
        'hotel': widget.hotel,
        'roomType': widget.roomType,
        'total': widget.total,
        'checkIn': widget.checkIn,
        'checkOut': widget.checkOut,
      });

      // ❌ En cas d’erreur :
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Paiement échoué. Veuillez réessayer.'), backgroundColor: Colors.red),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.total ?? 0.0;
    final nights = widget.checkIn != null && widget.checkOut != null
        ? widget.checkOut!.difference(widget.checkIn!).inDays
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Besoin d’aide ? Contactez-nous.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Résumé de la réservation
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.hotel != null)
                    Text(
                      widget.hotel!.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (widget.roomType != null)
                    Text('${widget.roomType} • ${widget.guests ?? 1} guest${(widget.guests ?? 1) > 1 ? 's' : ''}'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Check-in'),
                      Text('${widget.checkIn?.toLocal().day}/${widget.checkIn?.toLocal().month}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Check-out'),
                      Text('${widget.checkOut?.toLocal().day}/${widget.checkOut?.toLocal().month}'),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total (${nights} night${nights > 1 ? 's' : ''})', style: TextStyle(fontSize: 18)),
                      Text('${total.toStringAsFixed(0)} TND', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // 🔹 Méthode de paiement
            Text('Payment method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildPaymentOption('visa', 'assets/icons/visa.png'),
                _buildPaymentOption('mastercard', 'assets/icons/mastercard.png'),
                _buildPaymentOption('paypal', 'assets/icons/paypal.png'),
                _buildPaymentOption('payoneer', 'assets/icons/payoneer.png'),
              ],
            ),
            SizedBox(height: 24),

            // 🔹 Formulaire
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Nom du titulaire
                  TextFormField(
                    controller: _cardholderController,
                    decoration: InputDecoration(
                      labelText: 'Cardholder name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.person, color: Colors.grey),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Entrez le nom du titulaire';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Numéro de carte
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: InputDecoration(
                      labelText: 'Card number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.credit_card, color: Colors.grey),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      final clean = value?.replaceAll(' ', '') ?? '';
                      if (clean.length < 13 || clean.length > 19) {
                        return 'Numéro de carte invalide';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_expiryFocus),
                  ),
                  SizedBox(height: 16),

                  // Date d’expiration + CVV
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          focusNode: _expiryFocus,
                          decoration: InputDecoration(
                            labelText: 'Expiry (MM/YY)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: Icon(Icons.calendar_today, color: Colors.grey),
                          ),
                          keyboardType: TextInputType.datetime,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                              return 'Format: MM/YY';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_cvvFocus),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          focusNode: _cvvFocus,
                          decoration: InputDecoration(
                            labelText: 'CVV',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: Icon(Icons.lock, color: Colors.grey),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 3) {
                              return 'CVV requis (3 chiffres)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // 🔹 Bouton de paiement
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onPayPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'PAY NOW',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),

            SizedBox(height: 24),
            // 🔹 Sécurité
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Paiement sécurisé • Données cryptées',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String id, String asset) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue[50] : Colors.transparent,
        ),
        child: Image.asset(
          asset,
          width: 50,
          height: 30,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => Icon(Icons.credit_card, size: 30),
        ),
      ),
    );
  }
}