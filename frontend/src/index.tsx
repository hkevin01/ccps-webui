// To fix TS7016, ensure @types/react-dom is installed:
// Run: npm install --save-dev @types/react-dom
import ReactDOM from 'react-dom/client';
import 'bootstrap/dist/css/bootstrap.min.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root') as HTMLElement);
root.render(<App />);
