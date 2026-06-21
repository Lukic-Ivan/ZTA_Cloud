require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const app = express();
const port = 3000;

app.use(cors());
const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
    console.error("KRITIČNA GREŠKA: JWT_SECRET nije definisan u okruženju! Proveri .env fajl.");
    process.exit(1);
}
const verifyTokenAndRole = (requiredRole) => {
    return (req, res, next) => {
        const authHeader = req.headers['authorization'];
        if (!authHeader) return res.status(403).json({ message: 'Nema tokena. Pristup odbijen.' });
        const token = authHeader.split(' ')[1];
        jwt.verify(token, JWT_SECRET, (err, decoded) => {
            if (err) return res.status(401).json({ message: 'Nevalidan token. Pristup odbijen.' });
            if (requiredRole && decoded.role !== requiredRole) {
                return res.status(403).json({ message: `Samo ${requiredRole} ima pristup. Vaša uloga: ${decoded.role}` });
            }
            req.user = decoded;
            next();
        });
    };
};
app.get('/api/data', verifyTokenAndRole(), async (req, res) => {
    res.json({
        message: 'Pozdrav! API prolaz radi i ti si autentifikovan.',
        user: req.user,
        visits: 1
    });
});
app.get('/api/admin-data', verifyTokenAndRole('admin'), async (req, res) => {
    res.json({
        message: 'Ovo je tajni podatak, vidljiv samo adminima',
        user: req.user
    });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Backend slusa na portu ${port}`);
});
