require('dotenv').config();

const express = require('express');
const { Client } = require('pg');

const app = express();

app.use(express.json());

const PORT = process.env.PORT || 3000;

// Conexión PostgreSQL
const db = new Client({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: 5432
});

// Verificar conexión
db.connect()
  .then(() => console.log('Conectado a PostgreSQL'))
  .catch(err => console.error('Error PostgreSQL:', err));

// Endpoint principal
app.get('/', (req, res) => {
  res.json({
    message: 'API funcionando correctamente'
  });
});

// Endpoint health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP'
  });
});

// Obtener usuarios
app.get('/users', async (req, res) => {

  try {

    const result = await db.query('SELECT * FROM users');

    res.json(result.rows);

  } catch (err) {

    res.status(500).json({
      error: err.message
    });

  }

});

// Crear usuario
app.post('/users', async (req, res) => {

  try {

    const { name, email } = req.body;

    const sql =
      'INSERT INTO users(name, email) VALUES($1, $2) RETURNING *';

    const result = await db.query(sql, [name, email]);

    res.json({
      message: 'Usuario creado',
      user: result.rows[0]
    });

  } catch (err) {

    res.status(500).json({
      error: err.message
    });

  }

});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});