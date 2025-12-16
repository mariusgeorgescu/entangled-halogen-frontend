/**
 * Configuration for BFF services
 * Each service has its own target URL and Basic Auth credentials
 * Values are read from environment variables with fallback defaults
 */

export const services = {
  'delegation-service': {
    target: process.env.DELEGATION_SERVICE || 'https://dev-delegation-service.cardano.vip',
    username: process.env.BASIC_USER || 'charles',
    password: process.env.BASIC_PASS || 'hoskinson'
  }
  // Add more services here as needed:
  // 'another-service': {
  //   target: process.env.ANOTHER_SERVICE || 'https://api.example.com',
  //   username: process.env.ANOTHER_SERVICE_USER || 'user1',
  //   password: process.env.ANOTHER_SERVICE_PASS || 'pass1'
  // }
};

