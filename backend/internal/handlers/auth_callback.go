package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// AuthCallbackHandler serves an HTML page that reads the Supabase access_token
// from the URL fragment (#) and redirects the user to the EthioClass deep link
// as a query parameter (?access_token=...) so Android can pass it to the app.
//
// This is necessary because Android strips URL fragments from deep link intents,
// so the token must be converted to a query param via JavaScript in the browser.
//
// Flow:
//
//	Supabase recovery email
//	  → https://api.ethioclass.com/auth/callback#access_token=TOKEN
//	  → this HTML page reads #access_token from fragment via JS
//	  → redirects to ethioclass://reset-password?access_token=TOKEN
//	  → Flutter app receives it as a query param and opens UpdatePasswordScreen
func AuthCallbackHandler(c *gin.Context) {
	html := `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>EthioClass - Redirecting...</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: #F0F4F8;
      flex-direction: column;
      gap: 16px;
    }
    .logo { font-size: 24px; font-weight: 800; }
    .logo span { color: #FBB024; }
    p { color: #555; font-size: 15px; }
    .spinner {
      width: 40px; height: 40px;
      border: 4px solid #e0e0e0;
      border-top-color: #FBB024;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="logo">Ethio<span>Class</span></div>
  <div class="spinner"></div>
  <p>Opening EthioClass app...</p>
  <script>
    // Read the URL fragment which contains Supabase tokens
    // e.g. #access_token=TOKEN&token_type=bearer&type=recovery
    var fragment = window.location.hash.substring(1);
    var params = {};
    fragment.split('&').forEach(function(part) {
      var pair = part.split('=');
      if (pair.length === 2) {
        params[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1]);
      }
    });

    var accessToken = params['access_token'];
    var type = params['type'];

    if (accessToken && type === 'recovery') {
      // Redirect to EthioClass app via deep link with token as a query param
      // so Android does NOT strip it (fragments are stripped, query params are not)
      var deepLink = 'ethioclass://reset-password?access_token=' + encodeURIComponent(accessToken);
      window.location.href = deepLink;

      // Fallback: if app isn't installed or deep link fails after 3s, show message
      setTimeout(function() {
        document.querySelector('p').textContent = 'Could not open the EthioClass app. Please make sure EthioClass is installed on your device.';
        document.querySelector('.spinner').style.display = 'none';
      }, 3000);
    } else {
      document.querySelector('p').textContent = 'Invalid or expired reset link. Please request a new password reset in the EthioClass app.';
      document.querySelector('.spinner').style.display = 'none';
    }
  </script>
</body>
</html>`

	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(html))
}
