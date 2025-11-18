import express from 'express';
import cors from 'cors';
import { pool } from './db.js';
import bcrypt from 'bcrypt';
import 'dotenv/config';
import nodemailer from 'nodemailer';

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// ✅ Vérifier la connexion à PostgreSQL
// ✅ Tester la connexion à PostgreSQL (sans bloquer un client)
pool.query('SELECT NOW()')
  .then(() => console.log('✅ Connecté à PostgreSQL'))
  .catch(err => console.error('❌ Erreur de connexion PostgreSQL:', err));
// --- USERS ---

app.post('/api/signup', async (req, res) => {
  const { username, email, password } = req.body;

  if (!username?.trim() || !email?.trim() || !password) {
    return res.status(400).json({ message: 'Tous les champs sont requis.' });
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email.trim())) {
    return res.status(400).json({ message: 'Adresse email invalide.' });
  }

  try {
    const existing = await pool.query(
      "SELECT id FROM users WHERE data->>'email' = $1",
      [email.trim().toLowerCase()]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({ message: 'Email déjà enregistré.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const userData = {
      role: 'user',
      email: email.trim().toLowerCase(),
      username: username.trim(),
      password: passwordHash,
    };

    const result = await pool.query(
      "INSERT INTO users (data) VALUES ($1) RETURNING id, data",
      [userData]
    );

    const newUser = result.rows[0];

    res.status(201).json({
      success: true,
      message: 'Utilisateur enregistré avec succès !',
      user: {
        id: newUser.id.toString(),
        role: newUser.data.role,
        email: newUser.data.email,
        username: newUser.data.username,
      },
    });
  } catch (err) {
    console.error('❌ Erreur signup:', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
});

app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Identifiants requis.' });
  }

  try {
    const result = await pool.query(
      "SELECT id, data FROM users WHERE data->>'username' = $1",
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Identifiants invalides.' });
    }

    const user = result.rows[0];
    if (!await bcrypt.compare(password, user.data.password)) {
      return res.status(401).json({ message: 'Identifiants invalides.' });
    }

    const { password: _, ...safeData } = user.data;
    res.json({
      id: user.id.toString(),
      ...safeData
    });
  } catch (err) {
    console.error('❌ Erreur login:', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
});

app.post('/api/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: 'Email requis.' });

  try {
    const result = await pool.query(
      "SELECT id FROM users WHERE data->>'email' = $1",
      [email]
    );

    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    global.resetCodes = global.resetCodes || {};
    global.resetCodes[email] = {
      code: resetCode,
      userId: result.rows[0]?.id,
      expiresAt: Date.now() + 10 * 60 * 1000
    };

    if (process.env.NODE_ENV !== 'test') {
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS },
      });

      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: email,
        subject: 'Code de réinitialisation - Booking Hotel',
        text: `Code: ${resetCode} (valable 10 min)`,
        html: `<p>Votre code : <strong>${resetCode}</strong></p><p>Valable 10 minutes.</p>`,
      });
    }

    res.json({ message: 'Si cet email est valide, un code vous a été envoyé.' });
  } catch (err) {
    console.error('❌ Erreur forgot-password:', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
});

app.post('/api/reset-password', async (req, res) => {
  const { email, code, newPassword } = req.body;
  if (!email || !code || !newPassword) {
    return res.status(400).json({ message: 'Données manquantes.' });
  }

  try {
    const record = global.resetCodes?.[email];
    if (!record || record.code !== code || Date.now() > record.expiresAt) {
      return res.status(400).json({ message: 'Code invalide ou expiré.' });
    }

    const newHash = await bcrypt.hash(newPassword, 10);
    await pool.query(
      "UPDATE users SET data = jsonb_set(data, '{password}', $1, true) WHERE id = $2",
      [JSON.stringify(newHash), record.userId]
    );

    delete global.resetCodes[email];
    res.json({ message: 'Mot de passe mis à jour.' });
  } catch (err) {
    console.error('❌ Erreur reset-password:', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
});

// --- HOTELS ---

app.get('/api/hotels', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, data FROM hotels ORDER BY id DESC');
    res.json(result.rows.map(r => ({ id: r.id.toString(), ...r.data })));
  } catch (err) {
    console.error('❌ Erreur /api/hotels:', err);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

app.get('/api/hotels/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, data FROM hotels WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Hôtel non trouvé' });
    const row = result.rows[0];
    res.json({ id: row.id.toString(), ...row.data });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

app.post('/api/hotels', async (req, res) => {
  try {
    const result = await pool.query(
      'INSERT INTO hotels (data) VALUES ($1) RETURNING id',
      [req.body]
    );
    res.status(201).json({ id: result.rows[0].id.toString(), ...req.body });
  } catch (err) {
    res.status(400).json({ error: 'Impossible de créer l\'hôtel.' });
  }
});

app.put('/api/hotels/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'UPDATE hotels SET data = $1 WHERE id = $2 RETURNING id, data',
      [req.body, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Hôtel non trouvé' });
    const row = result.rows[0];
    res.json({ id: row.id.toString(), ...row.data });
  } catch (err) {
    res.status(400).json({ error: 'Erreur mise à jour.' });
  }
});

app.delete('/api/hotels/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM hotels WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'Hôtel non trouvé' });
    res.json({ success: true });
  } catch (err) {
    res.status(400).json({ error: 'Erreur suppression.' });
  }
});

// --- HOTEL CARDS ---

app.get('/api/hotel-cards', async (req, res) => {
  try {
    let query = `
      SELECT id, name, location, price_per_month, stars,
             image_url, facilities_preview, hotel_id
      FROM hotel_cards
    `;
    const values = [];
    if (req.query.location) {
      query += ` WHERE LOWER(location) LIKE LOWER($1)`;
      values.push(`%${req.query.location}%`);
    }
    query += ` ORDER BY id DESC`;

    const result = await pool.query(query, values);
    const cards = result.rows.map(row => ({
      id: row.id.toString(),
      name: row.name,
      location: row.location,
      price_per_month: parseFloat(row.price_per_month) || 0,
      stars: parseInt(row.stars) || 5,
      image_url: row.image_url || '',
      facilities_preview: Array.isArray(row.facilities_preview)
        ? row.facilities_preview.map(f => f?.toString() || '')
        : ['WiFi', 'Parking'],
      hotel_id: row.hotel_id ? row.hotel_id.toString() : null,
    }));
    res.json(cards);
  } catch (err) {
    console.error('❌ Erreur /api/hotel-cards:', err);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

app.get('/api/hotel-cards/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, location, price_per_month, stars,
              image_url, facilities_preview, hotel_id
       FROM hotel_cards WHERE id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Carte non trouvée' });
    const row = result.rows[0];
    res.json({
      id: row.id.toString(),
      name: row.name,
      location: row.location,
      price_per_month: parseFloat(row.price_per_month) || 0,
      stars: parseInt(row.stars) || 5,
      image_url: row.image_url || '',
      facilities_preview: Array.isArray(row.facilities_preview)
        ? row.facilities_preview.map(f => f.toString())
        : ['WiFi', 'Parking'],
      hotel_id: row.hotel_id ? row.hotel_id.toString() : null,
    });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

app.post('/api/hotel-cards', async (req, res) => {
  const { name, location, price_per_month, stars = 5, image_url = '', facilities_preview = ['WiFi', 'Parking'], hotel_id } = req.body;
  if (!name || !location || !hotel_id) {
    return res.status(400).json({ error: 'name, location, hotel_id requis' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO hotel_cards
        (name, location, price_per_month, stars, image_url, facilities_preview, hotel_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, name, location, price_per_month, stars, image_url, facilities_preview, hotel_id`,
      [
        name,
        location,
        parseFloat(price_per_month) || 0,
        parseInt(stars) || 5,
        image_url,
        facilities_preview,
        parseInt(hotel_id)
      ]
    );

    const row = result.rows[0];
    res.status(201).json({
      id: row.id.toString(),
      name: row.name,
      location: row.location,
      price_per_month: row.price_per_month,
      stars: row.stars,
      image_url: row.image_url,
      facilities_preview: row.facilities_preview,
      hotel_id: row.hotel_id ? row.hotel_id.toString() : null,
    });
  } catch (err) {
    console.error('❌ Erreur POST /api/hotel-cards:', err);
    res.status(400).json({ error: 'Création impossible.' });
  }
});

app.put('/api/hotel-cards/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, location, price_per_month, stars, image_url, facilities_preview, hotel_id } = req.body;
    const fields = [], values = [id];
    let i = 2;

    if (name !== undefined) fields.push(`name = $${i++}`), values.push(name);
    if (location !== undefined) fields.push(`location = $${i++}`), values.push(location);
    if (price_per_month !== undefined) fields.push(`price_per_month = $${i++}`), values.push(parseFloat(price_per_month));
    if (stars !== undefined) fields.push(`stars = $${i++}`), values.push(parseInt(stars));
    if (image_url !== undefined) fields.push(`image_url = $${i++}`), values.push(image_url);
    if (facilities_preview !== undefined) fields.push(`facilities_preview = $${i++}`), values.push(facilities_preview);
    if (hotel_id !== undefined) fields.push(`hotel_id = $${i++}`), values.push(parseInt(hotel_id));

    if (fields.length === 0) return res.status(400).json({ error: 'Aucune donnée à mettre à jour' });

    const query = `
      UPDATE hotel_cards
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $1
      RETURNING id, name, location, price_per_month, stars, image_url, facilities_preview, hotel_id
    `;

    const result = await pool.query(query, values);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Carte non trouvée' });

    const row = result.rows[0];
    res.json({
      id: row.id.toString(),
      name: row.name,
      location: row.location,
      price_per_month: row.price_per_month,
      stars: row.stars,
      image_url: row.image_url,
      facilities_preview: row.facilities_preview,
      hotel_id: row.hotel_id ? row.hotel_id.toString() : null,
    });
  } catch (err) {
    console.error('❌ Erreur PUT /api/hotel-cards/:id:', err);
    res.status(400).json({ error: 'Mise à jour impossible.' });
  }
});

app.delete('/api/hotel-cards/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM hotel_cards WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'Carte non trouvée' });
    res.json({ success: true, id: req.params.id });
  } catch (err) {
    res.status(400).json({ error: 'Suppression impossible.' });
  }
});

// --- WISHLIST ENDPOINTS (FIXED) ---

// ✅ GET: Returns ["1", "2", "3"] — compatible with Flutter
app.get('/api/wishlist/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const result = await pool.query(`
      SELECT hc.id
      FROM wishlist w
      JOIN hotel_cards hc ON w.hotel_card_id = hc.id
      WHERE w.user_id = $1
    `, [userId]);

    const ids = result.rows.map(row => row.id.toString());
    res.json(ids);
  } catch (err) {
    console.error('❌ Erreur GET /api/wishlist/:userId:', err);
    res.status(500).json({ error: 'Erreur chargement wishlist.' });
  }
});

// ✅ POST: Add to wishlist (idempotent)
app.post('/api/wishlist', async (req, res) => {
  const { userId, hotelCardId } = req.body;
  if (!userId || !hotelCardId) {
    return res.status(400).json({ error: 'userId et hotelCardId requis' });
  }

  try {
    const cardCheck = await pool.query('SELECT id FROM hotel_cards WHERE id = $1', [hotelCardId]);
    if (cardCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Carte introuvable' });
    }

    await pool.query(`
      INSERT INTO wishlist (user_id, hotel_card_id)
      VALUES ($1, $2)
      ON CONFLICT (user_id, hotel_card_id) DO NOTHING
    `, [userId, hotelCardId]);

    console.log(`✅ Ajouté à wishlist: user=${userId}, card=${hotelCardId}`);
    res.status(201).json({ success: true });
  } catch (err) {
    console.error('❌ Erreur POST /api/wishlist:', err);
    res.status(500).json({ error: 'Erreur ajout wishlist.' });
  }
});

// ✅ DELETE: Remove from wishlist — supports BODY and QUERY
app.delete('/api/wishlist', async (req, res) => {
  // 🔹 Accept from body (Flutter POSTMAN) OR query (Flutter mobile)
  const userId = req.body?.userId || req.query?.userId;
  const hotelCardId = req.body?.hotelCardId || req.query?.hotelCardId;

  console.log(`➡️ DELETE wishlist attempt: userId=${userId}, hotelCardId=${hotelCardId}`);

  if (!userId || !hotelCardId) {
    console.warn('⚠️ DELETE /api/wishlist: userId/hotelCardId manquants');
    return res.status(400).json({
      error: 'userId et hotelCardId requis (dans body ou query)'
    });
  }

  try {
    const result = await pool.query(
      'DELETE FROM wishlist WHERE user_id = $1 AND hotel_card_id = $2',
      [userId, hotelCardId]
    );

    console.log(`🗑️ Supprimé: ${result.rowCount} ligne(s)`);

    if (result.rowCount === 0) {
      return res.status(404).json({
        error: 'Élément non trouvé dans la wishlist'
      });
    }

    res.json({ success: true });
  } catch (err) {
    console.error('❌ Erreur DELETE /api/wishlist:', err);
    res.status(500).json({ error: 'Erreur suppression wishlist.' });
  }
});

// ✅ Clear wishlist (secure)
app.delete('/api/wishlist/clear', async (req, res) => {
  const userId = req.query.userId || req.body?.userId;
  if (!userId) return res.status(400).json({ error: 'userId requis' });

  try {
    const result = await pool.query('DELETE FROM wishlist WHERE user_id = $1', [userId]);
    console.log(`🧹 Wishlist vidée pour user=${userId} (${result.rowCount} éléments)`);
    res.json({ success: true, count: result.rowCount });
  } catch (err) {
    console.error('❌ Erreur /api/wishlist/clear:', err);
    res.status(500).json({ error: 'Erreur vidage wishlist.' });
  }
});
// --- ADMIN: USER MANAGEMENT ---

const requireAdmin = (req, res, next) => {
  // 🔐 À remplacer par auth JWT en production
  next();
};

app.get('/api/users', requireAdmin, async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, data->>'username' AS username, data->>'email' AS email, data->>'role' AS role FROM users"
    );
    res.json(result.rows.map(r => ({
      id: r.id.toString(),
      username: r.username || '',
      email: r.email || '',
      role: (r.role || 'user').toLowerCase(),
    })));
  } catch (err) {
    console.error('❌ Erreur /api/users:', err);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

app.put('/api/users/:id/role', requireAdmin, async (req, res) => {
  const { role } = req.body;
  if (!['user', 'admin'].includes(role)) {
    return res.status(400).json({ error: 'Rôle invalide' });
  }

  try {
    const result = await pool.query(
      "UPDATE users SET data = jsonb_set(data, '{role}', $1, true) WHERE id = $2 RETURNING id, data",
      [JSON.stringify(role), req.params.id]
    );

    if (result.rows.length === 0) return res.status(404).json({ error: 'Utilisateur non trouvé' });

    const user = result.rows[0];
    const safeData = { ...user.data };
    delete safeData.password;
    res.json({ id: user.id.toString(), ...safeData });
  } catch (err) {
    console.error('❌ Erreur update rôle:', err);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

app.delete('/api/users/:id', requireAdmin, async (req, res) => {
  if (req.params.id === '1') {
    return res.status(403).json({ error: 'Super-admin protégé' });
  }

  try {
    await pool.query('DELETE FROM wishlist WHERE user_id = $1', [req.params.id]);
    const result = await pool.query('DELETE FROM users WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'Utilisateur non trouvé' });
    res.json({ success: true });
  } catch (err) {
    console.error('❌ Erreur suppression utilisateur:', err);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});


// --- PLACES ---

// 🔹 GET /api/places?location=Hammamet
app.get('/api/places', async (req, res) => {
  try {
    let query = `
      SELECT id, name, location, image_url, tag, badge, description
      FROM places
    `;
    const values = [];
    if (req.query.location) {
      // ✅ Filtrage case-insensitive, avec LIKE pour flexibilité
      query += ` WHERE LOWER(location) = LOWER($1)`;
      values.push(req.query.location);
    }
    query += ` ORDER BY created_at DESC`;

    const result = await pool.query(query, values);
    const places = result.rows.map(row => ({
      id: row.id.toString(),
      name: row.name,
      location: row.location,
      image_url: row.image_url || '',
      tag: row.tag || 'Hot Deal',
      badge: row.badge || '2N/3D',
      description: row.description || '',
    }));
    res.json(places);
  } catch (err) {
    console.error('❌ Erreur /api/places:', err);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

// 🔹 GET /api/places/:id
app.get('/api/places/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, location, image_url, tag, badge, description
       FROM places WHERE id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Place non trouvée' });
    }
    const row = result.rows[0];
    res.json({
      id: row.id.toString(),
      name: row.name,
      location: row.location,
      image_url: row.image_url || '',
      tag: row.tag || 'Hot Deal',
      badge: row.badge || '2N/3D',
      description: row.description || '',
    });
  } catch (err) {
    console.error('❌ Erreur GET /api/places/:id:', err);
    res.status(500).json({ error: 'Erreur serveur.' });
  }
});

// 🔹 POST /api/places
app.post('/api/places', async (req, res) => {
  const { name, location, image_url = '', tag = 'Hot Deal', badge = '2N/3D', description = '' } = req.body;

  if (!name || !location) {
    return res.status(400).json({ error: 'name et location requis' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO places (name, location, image_url, tag, badge, description)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, name, location, image_url, tag, badge, description`,
      [
        name.trim(),
        location.trim(), // ✅ cohérence avec votre frontend
        image_url,
        tag,
        badge,
        description
      ]
    );

    const row = result.rows[0];
    res.status(201).json({
      id: row.id.toString(),
      name: row.name,
      location: row.location,
      image_url: row.image_url,
      tag: row.tag,
      badge: row.badge,
      description: row.description,
    });
  } catch (err) {
    console.error('❌ Erreur POST /api/places:', err);
    res.status(400).json({ error: 'Création impossible.' });
  }
});

// 🔹 PUT /api/places/:id
app.put('/api/places/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, location, image_url, tag, badge, description } = req.body;
    const fields = [];
    const values = [id]; // $1 = id
    let i = 2; // next placeholder index

    if (name !== undefined) {
      fields.push(`name = $${i}`);
      values.push(name.trim());
      i++;
    }
    if (location !== undefined) {
      fields.push(`location = $${i}`);
      values.push(location.trim());
      i++;
    }
    if (image_url !== undefined) {
      fields.push(`image_url = $${i}`);
      values.push(image_url); // ✅ push value!
      i++;
    }
    if (tag !== undefined) {
      fields.push(`tag = $${i}`);
      values.push(tag); // ✅
      i++;
    }
    if (badge !== undefined) {
      fields.push(`badge = $${i}`);
      values.push(badge); // ✅
      i++;
    }
    if (description !== undefined) {
      fields.push(`description = $${i}`);
      values.push(description); // ✅
      i++;
    }

    if (fields.length === 0) {
      return res.status(400).json({ error: 'Aucune donnée à mettre à jour' });
    }

    const query = `
      UPDATE places
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $1
      RETURNING id, name, location, image_url, tag, badge, description
    `;

    const result = await pool.query(query, values);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Place non trouvée' });
    }

    const row = result.rows[0];
    res.json({
      id: row.id.toString(),
      name: row.name,
      location: row.location,
      image_url: row.image_url,
      tag: row.tag,
      badge: row.badge,
      description: row.description,
    });
  } catch (err) {
    console.error('❌ Erreur PUT /api/places/:id:', err);
    res.status(400).json({ error: 'Mise à jour impossible.' });
  }
});

// 🔹 DELETE /api/places/:id
app.delete('/api/places/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM places WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'Place non trouvée' });
    res.json({ success: true, id: req.params.id });
  } catch (err) {
    console.error('❌ Erreur DELETE /api/places/:id:', err);
    res.status(400).json({ error: 'Suppression impossible.' });
  }
});



























// ▶️ Lancer le serveur
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Backend démarré sur http://localhost:${PORT}`);

  console.log(`🏠 Depuis LAN (ex: Flutter) : http://192.168.1.198:${PORT}`);
});