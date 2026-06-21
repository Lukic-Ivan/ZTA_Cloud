require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
const port = 4000;

app.use(express.json());
app.use(cors());

// Secret key se ucitava iz .env fajla
const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
    console.error("KRITIČNA GREŠKA: JWT_SECRET nije definisan u okruženju! Proveri .env fajl.");
    process.exit(1);
}

// Baza usera iako nije u potpunosti u skladu sa ZTA praksom (zbog lakse implementacije za demo)
const users = [
    { id: 1, username: 'admin', password: 'password123', role: 'admin' },
    { id: 2, username: 'user', password: 'password123', role: 'user' }
];

app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    const user = users.find(u => u.username === username && u.password === password);

    if (user) {

        const token = jwt.sign(
            { id: user.id, username: user.username, role: user.role },
            JWT_SECRET,
            { expiresIn: '1h' }
        );

        res.json({
            message: 'Uspesna autentifikacija',
            token: token
        });
    } else {
        res.status(401).json({ message: 'Neispravni kredencijali' });
    }
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Auth Service slusa na portu ${port}`);
});
