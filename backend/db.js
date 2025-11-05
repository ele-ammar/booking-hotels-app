// db.js
import pkg from 'pg';
const { Pool } = pkg;

export const pool = new Pool({
  user: 'postgres',           // ton nom d'utilisateur PostgreSQL
  host: 'localhost',          // ton serveur local
  database: 'hotel_db',       // la base que tu as créée
  password: '123', // ton mot de passe PostgreSQL
  port: 5432,                 // port par défaut
});
