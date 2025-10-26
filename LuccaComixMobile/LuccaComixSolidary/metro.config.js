const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Disabilita alcune funzionalità che causano blocchi
config.transformer.minifierConfig = {
  keep_classnames: true,
  keep_fnames: true,
};

module.exports = config;
