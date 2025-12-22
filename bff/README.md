# BFF (Backend For Frontend)

Un server proxy simplu construit cu Fastify care funcționează ca intermediar între frontend-ul PureScript și mai multe backend-uri.

## Funcționalități

- Proxyează requesturile de la frontend către backend-uri
- Adaugă automat header-ul `Authorization: Basic` pentru serviciile cu Basic Auth
- Suportă API key authentication pentru servicii care necesită `api-key` header
- Suportă credențiale diferite pentru fiecare serviciu
- CORS configurat pentru a permite requesturi de la frontend
- Servește documente PDF din directorul `pdfs/`
- Validare obligatorie a variabilelor de mediu (fără valori default)
- Logging automat al variabilelor de mediu la pornire (valorile sensibile sunt mascate)

## Configurare

Serviciile sunt configurate în `bff/config.js` folosind variabile de mediu. **Toate variabilele de mediu sunt obligatorii** - nu există valori default. Dacă o variabilă lipsește, serverul va afișa o eroare și se va opri.

### Variabile de mediu obligatorii

- `DELEGATION_SERVICE` - URL-ul backend-ului delegation-service
- `BASIC_USER` - Username pentru Basic Auth
- `BASIC_PASS` - Password pentru Basic Auth
- `GOMAESTRO_ENV` - Environment-ul Gomaestro API (ex: preprod, preview, mainnet)
- `GOMAESTRO_API_KEY` - API key pentru Gomaestro API

### Exemplu de configurare

```bash
export DELEGATION_SERVICE=https://api.example.com
export BASIC_USER=myuser
export BASIC_PASS=mypassword
export GOMAESTRO_ENV=preprod
export GOMAESTRO_API_KEY=your-api-key-here
npm run bff
```

La pornire, serverul va afișa toate variabilele de mediu pentru debugging (valorile sensibile precum parolele și API keys sunt mascate):

```
=== Environment Variables (Debug) ===
DELEGATION_SERVICE: https://api.example.com
BASIC_USER: myuser
BASIC_PASS: my******************rd (length: 10)
GOMAESTRO_ENV: preprod
GOMAESTRO_API_KEY: yo******************ey (length: 40)
=====================================
```

### Adăugarea unui nou serviciu

Pentru a adăuga un nou serviciu, editează `bff/config.js`:

**Pentru servicii cu Basic Auth:**
```javascript
export const services = {
  'delegation-service': {
    target: envVars.DELEGATION_SERVICE,
    username: envVars.BASIC_USER,
    password: envVars.BASIC_PASS
  },
  'new-service': {
    target: requireEnv('NEW_SERVICE_URL'),
    username: requireEnv('NEW_SERVICE_USER'),
    password: requireEnv('NEW_SERVICE_PASS')
  }
};
```

**Pentru servicii cu API Key:**
```javascript
export const services = {
  'gomaestro-api': {
    gomaestroEnv: envVars.GOMAESTRO_ENV,
    target: `https://${envVars.GOMAESTRO_ENV}.gomaestro-api.org/v1`,
    apiKey: envVars.GOMAESTRO_API_KEY
  }
};
```

## Utilizare

### Pornirea serverului

```bash
npm run bff
```

Pentru development cu auto-reload:

```bash
npm run bff:dev
```

### Variabile de mediu opționale

- `PORT` sau `BFF_PORT` - Portul pe care rulează serverul (default: 80)
- `BFF_HOST` - Host-ul pe care rulează serverul (default: 0.0.0.0)
- `NODE_TLS_REJECT_UNAUTHORIZED` - Setează la `0` pentru a dezactiva validarea certificatelor SSL (doar pentru development/testing)

### Servicii disponibile

Serverul suportă următoarele servicii configurate automat prin proxy:

1. **delegation-service** - Proxyează către `DELEGATION_SERVICE` cu Basic Auth
   - Prefix: `/api/delegation-service`
   - Autentificare: Basic Auth (`Authorization: Basic ...`)

2. **gomaestro-api** - Proxyează către Gomaestro API cu API key
   - Prefix: `/api/gomaestro-api`
   - Autentificare: API Key (`api-key: ...`)
   - URL: `https://{GOMAESTRO_ENV}.gomaestro-api.org/v1`

### Endpoints

- `GET /health` - Health check endpoint care returnează statusul și lista serviciilor disponibile
- `GET /api/test` - Test endpoint pentru verificarea rutelor API
- `GET /test-connectivity` - Testează conectivitatea către backend-uri
- `GET /doc/{filename}` - Descarcă un document PDF specific din directorul `pdfs/`
- `/api/{service-name}/*` - Proxyează requesturile către serviciul specificat

### Exemple de utilizare

**Delegation Service (Basic Auth):**

Request de la frontend:
```
GET http://localhost/api/delegation-service/build-tx
```

Va fi proxiat către:
```
GET {DELEGATION_SERVICE}/build-tx
```

Cu header-ul:
```
Authorization: Basic {base64(username:password)}
```

**Gomaestro API (API Key):**

Request de la frontend:
```
GET http://localhost/api/gomaestro-api/pools/{poolId}/info
```

Va fi proxiat către:
```
GET https://{GOMAESTRO_ENV}.gomaestro-api.org/v1/pools/{poolId}/info
```

Cu header-ul:
```
api-key: {GOMAESTRO_API_KEY}
```

### Exemplu - Documente PDF

Serverul servește documente PDF din directorul `pdfs/` la prefixul `/doc/`.

Descărcarea unui document:
```
GET http://localhost/doc/hydra-pay-audit-report-signed.pdf
```

Documentele trebuie să fie plasate în directorul `pdfs/` din rădăcina proiectului.

## Instalare dependențe

```bash
npm install
```


