/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: '#1a73e8',
        secondary: '#34a853',
        danger: '#d33b27',
        warning: '#fbbc04',
        info: '#4285f4',
      },
    },
  },
  plugins: [],
}
