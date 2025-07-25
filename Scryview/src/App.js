import { useEffect, useMemo, useRef, useState } from 'react';
import { useSets, diamond } from './Api';
import { CardGallery } from './pages/CardGallery';
import { scrollToTop } from './Utility';
import { Home } from './pages/Home';
import './App.css';
import { DEBUG_CONFIG, DebugPanel } from './DebugPanel';

function App() {
  // All hooks must be called unconditionally at the top level
  const [selectedSet, setSelectedSet] = useState(null);
  const [selectedType, setSelectedType] = useState(null);
  const [selectedCardType, setSelectedCardType] = useState('');
  const [selectedColors, setSelectedColors] = useState([]);
  const [searchFields, setSearchFields] = useState({
    name: '',
    oracle: '',
    type: ''
  });
  const [showScrollTop, setShowScrollTop] = useState(false);
  // eslint-disable-next-line
  const [buttonWidth, setButtonWidth] = useState(0);

  const topRef = useRef(null);
  const buttonRef = useRef(null);

  // Scroll handler
  useEffect(() => {
    const handleScroll = () => {
      setShowScrollTop(window.scrollY > 200);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Button width effect
  useEffect(() => {
    if (buttonRef.current && showScrollTop) {
      setButtonWidth(buttonRef.current.offsetWidth);
    }
  }, [showScrollTop]);

  const { data: setsData, isLoading, error } = useSets();

  // Filter sets based on selected type
  const filteredSets = useMemo(() => {
    if (!setsData?.data) return [];
    return selectedType
      ? setsData.data.filter(set => set.set_type === selectedType)
      : setsData.data;
  }, [setsData, selectedType]);

  // Auto-select first set when filtered sets change
  useEffect(() => {
    if (filteredSets.length > 0 && !selectedSet) {
      const firstSet = filteredSets[0].code;
      setSelectedSet(firstSet);
      // Reset all filters when auto-selecting
      setSearchFields({ name: '', oracle: '', type: '' });
      setSelectedCardType('');
      setSelectedColors([]);
    }
  }, [filteredSets, selectedSet]);

  const handleSetSelect = (setCode) => {
    setSearchFields({ name: '', oracle: '', type: '' });
    setSelectedCardType('');
    setSelectedColors([]);
    setSelectedSet(setCode);
  };

  const handleTypeSelect = (type) => {
    setSearchFields({ name: '', oracle: '', type: '' });
    setSelectedCardType('');
    setSelectedColors([]);
    setSelectedType(type || null);
    setSelectedSet(null);
  };

  const handleCardTypeChange = (cardType) => {
    setSearchFields(prev => ({
      ...prev,
      type: cardType
    }));
    setSelectedColors([]);
    setSelectedCardType(cardType);
  };

  const handleSearchUpdate = (name, oracle) => {
    setSearchFields(prev => ({
      ...prev,
      name,
      oracle
    }));
  };

  const handleColorChange = (newColors) => {
    setSelectedColors(newColors);
  };

  return (
    <div className="page-wrapper">
      <div className="app-container">
        <header>
          <img src="/images/mtgshield.png" alt="MTG Shield" className="corner-image" />
          <img src="/images/mtgscryetitlesmall.png" alt="MTG Scrye Title" className="title-image" />
        </header>
        <main>
          <div className="controls">
            {isLoading ? (
              <div className="loading-section">
                <p>Loading Magic cache...</p>
                <div className="loading-spinner"></div>
              </div>
            ) : error ? (
              <div className="error-section">
                <p>Error loading sets: {error.message}</p>
                <button
                  onClick={() => window.location.reload()}
                  className="retry-button"
                >
                  Retry
                </button>
              </div>
            ) : (
              <Home
                sets={filteredSets}
                onSelect={handleSetSelect}
                selectedSet={selectedSet}
                selectedType={selectedType}
                onTypeChange={handleTypeSelect}
                selectedCardType={selectedCardType}
                onCardTypeChange={handleCardTypeChange}
                searchFields={searchFields}
                updateSearch={handleSearchUpdate}
                selectedColors={selectedColors}
                setSelectedColors={handleColorChange}
              />
            )}
          </div>

          <div ref={topRef} />

          <div className="gallery-container">
            <CardGallery
              setCode={selectedSet}
              searchFields={searchFields}
              onSelectSet={handleSetSelect}
              selectedCardType={selectedCardType}
              selectedColors={selectedColors}
            />
          </div>
        </main>
      </div>
      <footer>
        <div className="footer-content">
          <div className="footer-links">
            <a href='https://magic.wizards.com/en/rules' rel="noreferrer" target="_blank">Rules</a>{diamond}
            <a href='https://magic.wizards.com/en/formats' rel="noreferrer" target="_blank">Formats</a>
          </div>

          {showScrollTop && (
            <div className="scroll-top-wrapper">
              <button
                ref={buttonRef}
                className='span_button'
                onClick={() => scrollToTop(topRef)}
              >
                <span className="span_anchor">&#129153;Top</span>
              </button>
            </div>
          )}
        </div>
      </footer>

      {DEBUG_CONFIG.SHOW_DEBUG && (
        <DebugPanel
          title="App.js - Debug info"
          position="bottom-right"
          data={{
            'Selected Set': selectedSet || 'None',
            'Selected Type': selectedType || 'None',
            'Selected Card Type': selectedCardType || 'None',
            'Selected Colors': selectedColors.length > 0 ? selectedColors.join(', ') : 'None',
            'Search Fields': {
              'Name': searchFields.name || 'Empty',
              'Oracle': searchFields.oracle || 'Empty',
              'Type': searchFields.type || 'Empty'
            },
            'Filtered Sets': filteredSets.length,
            'Loading': isLoading ? 'Yes' : 'No',
            'Error': error ? error.message : 'None'
          }}
        />
      )}
    </div>
  );
}

export default App;