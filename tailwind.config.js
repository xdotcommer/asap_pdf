module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
  ],
  theme: {
    extend: {
      colors: {
        'off-white': '#fcfcfc',
        'attendee': '#6A6A74',
        'recent': '#FFFEEE'
      }
    },
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: [
      {
        noir: {
          primary: '#1A2333',
          'primary-focus': '#2A374D',
          'primary-content': '#ffffff',
          secondary: '#2C2C34',
          'secondary-focus': '#3A3A44',
          'secondary-content': '#ffffff',
          accent: '#35fcff',
          'accent-focus': '#00CED1',
          'accent-content': '#1A2333',
          neutral: '#2c2c2c',
          'neutral-focus': '#3a3a3a',
          'neutral-content': '#eaeaea',
          'base-100': '#f8f8f8',
          'base-200': '#e8e8e8',
          'base-300': '#d8d8d8',
          'base-content': '#1a1a1a',
          info: '#F0F7FA',
          'info-content': '#00A5A8',
          success: '#F0FDF4',
          'success-content': '#16A34A',
          error: '#FEF2F2',
          'error-content': '#EF4444',
          warning: '#E1A533',
          '--rounded-box': '.75rem',
          '--rounded-btn': '.25rem',
          '--rounded-badge': '.25rem',
          '--animation-btn': '.2s',
          '--animation-input': '.15s',
          '--btn-text-case': 'capitalize',
          '--navbar-padding': '0.75rem',
          '--border-btn': '1px',
        },
      },
    ],
  },
};
