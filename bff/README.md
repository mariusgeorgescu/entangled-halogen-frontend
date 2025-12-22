# BFF (Backend For Frontend)

Un server proxy simplu construit cu Fastify care funcționează ca intermediar între frontend-ul PureScript și mai multe backend-uri.

## Funcționalități

- Proxyează requesturile de la frontend către backend-uri
- Adaugă automat header-ul `Authorization: Basic` pentru fiecare serviciu
- Suportă credențiale diferite pentru fiecare serviciu
- CORS configurat pentru a permite requesturi de la frontend
- Servește documente PDF din directorul `pdfs/`

## Configurare

Serviciile sunt configurate în `bff/config.js` folosind variabile de mediu. Valorile pot fi setate prin environment variables sau vor folosi valorile default.

Pentru a configura serviciile, setează următoarele variabile de mediu:
- `DELEGATION_SERVICE` - URL-ul backend-ului (default: https://dev-delegation-service.cardano.vip)
- `BASIC_USER` - Username pentru Basic Auth (default: charles)
- `BASIC_PASS` - Password pentru Basic Auth (default: hoskinson)

Exemplu de configurare:
```bash
export DELEGATION_SERVICE=https://api.example.com
export BASIC_USER=myuser
export BASIC_PASS=mypassword
npm run bff
```

Pentru a adăuga un nou serviciu, editează `bff/config.js`:
```javascript
export const services = {
  'delegation-service': {
    target: process.env.DELEGATION_SERVICE || 'https://dev-delegation-service.cardano.vip',
    username: process.env.BASIC_USER || 'charles',
    password: process.env.BASIC_PASS || 'hoskinson'
  },
  'new-service': {
    target: process.env.NEW_SERVICE || 'https://api.example.com',
    username: process.env.NEW_SERVICE_USER || 'user',
    password: process.env.NEW_SERVICE_PASS || 'pass'
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

### Variabile de mediu

- `BFF_PORT` - Portul pe care rulează serverul (default: 3001)
- `BFF_HOST` - Host-ul pe care rulează serverul (default: 0.0.0.0)
- `DELEGATION_SERVICE` - URL-ul backend-ului delegation-service (default: https://dev-delegation-service.cardano.vip)
- `BASIC_USER` - Username pentru Basic Auth (default: charles)
- `BASIC_PASS` - Password pentru Basic Auth (default: hoskinson)

### Endpoints

- `GET /health` - Health check endpoint care returnează statusul și lista serviciilor disponibile
- `GET /doc` - Listăază toate documentele PDF disponibile
- `GET /doc/{filename}` - Descarcă un document PDF specific
- `/*/api/{service-name}/*` - Proxyează requesturile către serviciul specificat

### Exemplu

Un request de la frontend către:
```
GET http://localhost:3001/api/delegation-service/build-tx
```

Va fi proxiat către:
```
GET https://dev-delegation-service.cardano.vip/build-tx
```

Cu header-ul:
```
Authorization: Basic Y2hhcmxlczpob3NraW5zb24=
```

### Exemplu - Documente PDF

Listarea documentelor disponibile:
```
GET http://localhost:3001/doc
```

Răspuns:
```json
{
  "documents": [
    {
      "filename": "hydra-pay-audit-report-signed.pdf",
      "url": "/doc/hydra-pay-audit-report-signed.pdf"
    }
  ],
  "count": 1
}
```

Descărcarea unui document:
```
GET http://localhost:3001/doc/hydra-pay-audit-report-signed.pdf
```

## Instalare dependențe

```bash
npm install
```


