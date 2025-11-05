import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { pool } from './db.js'; // Connexion PostgreSQL
import bcrypt from 'bcrypt';
import 'dotenv/config';
import nodemailer from 'nodemailer';
const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

// ✅ Vérifier la connexion à PostgreSQL
pool.connect()
  .then(() => console.log('✅ Connecté à PostgreSQL (mode JSONB)'))
  .catch(err => console.error('❌ Erreur de connexion PostgreSQL:', err));

// --- USERS (signup avec validation email) ---

app.post('/api/signup', async (req, res) => {
  const { username, email, password } = req.body;

  // ✅ 1. Vérifier que tous les champs sont présents
  if (!username || !email || !password) {
    return res.status(400).json({ message: 'Tous les champs sont requis.' });
  }

  // ✅ 2. Valider le format de l'email (doit contenir @ et .)
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ message: 'Adresse email invalide.' });
  }

  try {
    // 🔍 3. Vérifier si l'email existe déjà
    const existing = await pool.query(
      'SELECT id FROM users WHERE data->>\'email\' = $1',
      [email]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({ message: 'Email déjà enregistré.' });
    }

    // ➕ 4. Créer l'utilisateur (rôle par défaut = 'user')
    const result = await pool.query(
      'INSERT INTO users (data) VALUES ($1) RETURNING id',
      [{
        username,
        email,
        password: await bcrypt.hash(password, 10),
        role: 'user'
      }]
    );

    res.status(201).json({
      message: 'Utilisateur enregistré avec succès !',
      id: result.rows[0].id
    });
  } catch (err) {
    console.error('Erreur inscription:', err);
    res.status(500).json({ message: 'Erreur serveur lors de l\'inscription.' });
  }
});



// 🔐 POST /api/login
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Username et mot de passe requis.' });
  }

  try {
    // 🔍 Rechercher un utilisateur avec ce username
    const result = await pool.query(
      'SELECT id, data FROM users WHERE data->>\'username\' = $1',
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Identifiants invalides.' });
    }

    const user = result.rows[0];
    const storedPassword = user.data.password;

    // ⚠️ TEMPORAIRE : comparaison en clair (à remplacer par bcrypt plus tard)
    if (!await bcrypt.compare(password, storedPassword)) {
      return res.status(401).json({ message: 'Identifiants invalides.' });
    }

    // ✅ Succès : retourner les infos utilisateur (sans le mot de passe)
    const { password: _, ...safeData } = user.data;
    res.json({
      id: user.id,
      ...safeData
    });
  } catch (err) {
    console.error('Erreur login:', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
});




// 📧 POST /api/forgot-password
app.post('/api/forgot-password', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'Email requis.' });
  }

  try {
    const result = await pool.query(
      'SELECT id FROM users WHERE data->>\'email\' = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(200).json({
        message: 'Si cet email est associé à un compte, un code vous a été envoyé.'
      });
    }

    // 🔢 Génère un code à 6 chiffres
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();

    // ⏳ Sauvegarde temporairement (en mémoire pour l'instant)
    // ⚠️ En production : stocke dans la base avec expiration
    if (!global.resetCodes) global.resetCodes = {};
    global.resetCodes[email] = { code: resetCode, userId: result.rows[0].id, expiresAt: Date.now() + 10 * 60 * 1000 }; // 10 min

    // 📧 Envoie le code par email
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS },
    });

    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Votre code de réinitialisation - Booking Hotel',
      text: `Votre code de réinitialisation est : ${resetCode}\nValable 10 minutes.`,
      html: `<h2>Votre code de réinitialisation</h2><p><strong>${resetCode}</strong></p><p>Valable 10 minutes.</p>`,
    });

    res.status(200).json({
      message: 'Si cet email est associé à un compte, un code vous a été envoyé.'
    });
  } catch (err) {
    console.error('Erreur forgot-password:', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
});





app.post('/api/reset-password', async (req, res) => {
  const { email, code, newPassword } = req.body;

  if (!email || !code || !newPassword) {
    return res.status(400).json({ message: 'Données manquantes.' });
  }

  try {
    // 🔍 Vérifie le code (simulé)
    if (!global.resetCodes || !global.resetCodes[email]) {
      return res.status(400).json({ message: 'Code invalide ou expiré.' });
    }

    const { code: storedCode, userId } = global.resetCodes[email];
    if (storedCode !== code) {
      return res.status(400).json({ message: 'Code incorrect.' });
    }

    // 🔒 Hache le nouveau mot de passe
    const newHashedPassword = await bcrypt.hash(newPassword, 10);

    // ✅ MET À JOUR SEULEMENT LE CHAMP "password" DANS LE JSONB
    const result = await pool.query(
      `UPDATE users
       SET data = jsonb_set(data, '{password}', $1, true)
       WHERE id = $2
       RETURNING id, data`,
      [JSON.stringify(newHashedPassword), userId] // 👈 Nouveau hash
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ message: 'Utilisateur non trouvé.' });
    }

    // 🧹 Nettoie le code temporaire
    delete global.resetCodes[email];

    res.json({ message: 'Mot de passe mis à jour avec succès.' });
  } catch (err) {
    console.error('Erreur reset-password:', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
});


// --- HOTELS ---

// 📋 GET /api/hotels
app.get('/api/hotels', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, data FROM hotels ORDER BY id DESC');
    const hotels = result.rows.map(row => ({ id: row.id, ...row.data }));
    res.json(hotels);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur chargement hôtels' });
  }
});

// 🔍 GET /api/hotels/:id
app.get('/api/hotels/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, data FROM hotels WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Hôtel non trouvé' });
    res.json({ id: result.rows[0].id, ...result.rows[0].data });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ➕ POST /api/hotels
app.post('/api/hotels', async (req, res) => {
  try {
    const result = await pool.query(
      'INSERT INTO hotels (data) VALUES ($1) RETURNING id',
      [req.body]
    );
    res.status(201).json({ id: result.rows[0].id, ...req.body });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ✏️ PUT /api/hotels/:id
app.put('/api/hotels/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'UPDATE hotels SET data = $1 WHERE id = $2 RETURNING id, data',
      [req.body, req.params.id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Hôtel non trouvé' });
    res.json({ id: result.rows[0].id, ...result.rows[0].data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 🗑️ DELETE /api/hotels/:id
app.delete('/api/hotels/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM hotels WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0)
      return res.status(404).json({ error: 'Hôtel non trouvé' });
    res.json({ success: true });
  } catch (err) {
    res.status(400).json({ error: 'Erreur suppression' });
  }
});

// ▶️ Lancer le serveur
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📱 From Android emulator: http://192.168.1.198:${PORT}`);
});
