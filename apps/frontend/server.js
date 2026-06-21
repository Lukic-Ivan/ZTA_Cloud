const express = require('express');
const http = require('http');

const app = express();
const port = 8080;

app.get('/', (req, res) => {
    res.send('<h1>Zero Trust</h1><p>Frontend radi i vraca odgovor.</p>');
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Frontend slusa na portu ${port}`);
});