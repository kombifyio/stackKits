import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Home } from './pages/Home';
import { Overview } from './pages/Overview';
import { HowItWorks } from './pages/HowItWorks';
import { Requirements } from './pages/Requirements';
import { GetStarted } from './pages/GetStarted';
import { Architecture } from './pages/Architecture';
import { Special } from './pages/Special';

function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-white">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/overview" element={<Overview />} />
          <Route path="/how-it-works" element={<HowItWorks />} />
          <Route path="/requirements" element={<Requirements />} />
          <Route path="/get-started" element={<GetStarted />} />
          <Route path="/architecture" element={<Architecture />} />
          <Route path="/special" element={<Special />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}

export default App;
