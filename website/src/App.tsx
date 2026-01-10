import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Layout } from './components';
import { HomePage, OverviewPage, HowItWorksPage, RequirementsPage, GetStartedPage } from './pages';

function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/overview" element={<OverviewPage />} />
          <Route path="/how-it-works" element={<HowItWorksPage />} />
          <Route path="/requirements" element={<RequirementsPage />} />
          <Route path="/get-started" element={<GetStartedPage />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}

export default App;
