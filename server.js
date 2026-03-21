const express = require('express');
const path = require('path');
const app = express();

const port = process.env.PORT || 8080;

// Serve the static files from the Flutter build directory
app.use(express.static(path.join(__dirname, 'build/web')));

// Any other request will be redirected to index.html
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build/web', 'index.html'));
});

app.listen(port, () => {
  console.log(`Server started on port ${port}`);
});
