import { Navbar, Hero, Overview, HowItWorks, Requirements, GetStarted, Footer } from './components';

function App() {
  return (
    <div className="min-h-screen bg-dark">
      <Navbar />
      <main>
        <Hero />
        <Overview />
        <HowItWorks />
        <Requirements />
        <GetStarted />
      </main>
      <Footer />
    </div>
  );
}

export default App;
