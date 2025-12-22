/**
 * Configuration for BFF services
 * Each service has its own target URL and Basic Auth credentials
 * All values must be provided via environment variables
 */

// Helper function to mask sensitive values for logging
function maskValue(value, showLength = true) {
  if (!value) return '(empty)';
  if (value.length <= 4) return '****';
  return showLength ? `${value.substring(0, 2)}${'*'.repeat(Math.min(value.length - 4, 20))}${value.substring(value.length - 2)} (length: ${value.length})` : '****';
}

// Helper function to validate required environment variables
function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    console.error(`ERROR: Required environment variable ${name} is not set`);
    process.exit(1);
  }
  return value;
}

// Load and validate all environment variables
const envVars = {
  DELEGATION_SERVICE: requireEnv('DELEGATION_SERVICE'),
  BASIC_USER: requireEnv('BASIC_USER'),
  BASIC_PASS: requireEnv('BASIC_PASS'),
  GOMAESTRO_ENV: requireEnv('GOMAESTRO_ENV'),
  GOMAESTRO_API_KEY: requireEnv('GOMAESTRO_API_KEY')
};

// Print environment variables for debugging (masking sensitive values)
console.log('\n=== Environment Variables (Debug) ===');
console.log(`DELEGATION_SERVICE: ${envVars.DELEGATION_SERVICE}`);
console.log(`BASIC_USER: ${envVars.BASIC_USER}`);
console.log(`BASIC_PASS: ${maskValue(envVars.BASIC_PASS)}`);
console.log(`GOMAESTRO_ENV: ${envVars.GOMAESTRO_ENV}`);
console.log(`GOMAESTRO_API_KEY: ${maskValue(envVars.GOMAESTRO_API_KEY)}`);
console.log('=====================================\n');

export const services = {
  'delegation-service': {
    target: envVars.DELEGATION_SERVICE,
    username: envVars.BASIC_USER,
    password: envVars.BASIC_PASS
  },
  'gomaestro-api': {
    gomaestroEnv: envVars.GOMAESTRO_ENV,
    target: `https://${envVars.GOMAESTRO_ENV}.gomaestro-api.org/v1`,
    apiKey: envVars.GOMAESTRO_API_KEY
  },
} 



 